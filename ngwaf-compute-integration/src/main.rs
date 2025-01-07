use fastly::security::{inspect, InspectConfig, InspectError, InspectResponse, InspectVerdict};
use fastly::handle::BodyHandle;
use fastly::http::{HeaderName, HeaderValue, StatusCode};
use fastly::{Request, Response};

const HTTPME_BACKEND: &str = "HTTPME";

#[fastly::main]
fn main(req: Request) -> Result<Response, fastly::Error> {
    let ngwaf_config = fastly::config_store::ConfigStore::open("ngwaf");
    let corp_name = ngwaf_config
        .get("corp")
        .expect("no `corp` present in config");
    let ws_name = ngwaf_config
        .get("workspace")
        .expect("no `workspace` present in config");

    let (mut req_handle, req_body) = req.into_handles();
    let req_body = req_body.unwrap_or_else(|| BodyHandle::new());
    let config = InspectConfig::new(&req_handle, &req_body)
        .corp(corp_name)
        .workspace(ws_name);

    match inspect(config) {
        Ok(resp) => match resp.verdict() {
            InspectVerdict::Block => Ok(Response::from_status(StatusCode::NOT_ACCEPTABLE)),
            InspectVerdict::Allow => {

                let waf_inspection_header_val = format_waf_inspection_header(resp);    
                req_handle.insert_header(&HeaderName::from_static("waf-inspect-data"), &HeaderValue::from_str(&waf_inspection_header_val)?);
                req_handle.insert_header(&HeaderName::from_static("host"), &HeaderValue::from_static("http.edgecompute.app"));


                // Send request to the backend
                let resp = Request::from_handles(req_handle, Some(req_body)).send(HTTPME_BACKEND)?;
            
                // Return the response back to the client
                return Ok(resp);
            },
            InspectVerdict::Unauthorized => {
                panic!("The service is not authorized to inspect the request")
            },
            _ => Ok(Response::from_status(StatusCode::INTERNAL_SERVER_ERROR)
                .with_body("Unable to inspect request")),
        },
        Err(err) => {
            let msg = format!("Invalid request: {err:?}");
            Ok(Response::from_status(StatusCode::BAD_REQUEST).with_body(msg))
        }
    }
}

fn format_waf_inspection_header(inspect_resp: InspectResponse) -> String {
    // Inspired by https://www.fastly.com/documentation/solutions/examples/filter-cookies-or-other-structured-headers/

    println!("Inspection Response: {:?}", inspect_resp);

    let mut filtered_cookie_header_value = "".to_string();

    filtered_cookie_header_value.push_str(&format!("{}{:?};", "status=", inspect_resp.status()));
    filtered_cookie_header_value.push_str(&format!(
        "{}{};",
        "tags=",
        inspect_resp
            .tags()
            .into_iter()
            .collect::<Vec<&str>>()
            .join(",")
            .as_str()
    ));
    filtered_cookie_header_value.push_str(&format!(
        "{}{:?};",
        "decision_ms=",
        inspect_resp.decision_ms()
    ));
    filtered_cookie_header_value.push_str(&format!("{}{:?}", "verdict=", inspect_resp.verdict()));

    return filtered_cookie_header_value;
}
