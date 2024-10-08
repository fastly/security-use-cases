use fastly::experimental::{inspect, InspectConfig, InspectError, InspectResponse};
use fastly::handle::BodyHandle;
use fastly::http::{HeaderValue, StatusCode};
use fastly::{Request, Response};
use std::collections::HashMap;

const HTTPME_BACKEND: &str = "HTTPME";

#[fastly::main]
fn main(mut req: Request) -> Result<Response, fastly::Error> {
    // Log service version
    println!(
        "FASTLY_SERVICE_VERSION: {}",
        std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new())
    );

    // Do not cache requests
    req.set_pass(true);

    // Returns req to allow for setting request headers based on the WAF inspection.
    let (mut req, waf_inspection_result) = do_waf_inspect(req);

    // if the waf inspection has an error, then return the error.
    if waf_inspection_result.get_status() != 200 {
        return Ok(waf_inspection_result);
    }

    req.set_header("host", "http.edgecompute.app");

    // Send request to the backend
    let resp: Response = req.send(HTTPME_BACKEND)?;

    // Return the response back to the client
    return Ok(resp);
}

fn do_waf_inspect(mut req: Request) -> (Request, Response) {
    // if bypass-waf is present, then do not send the request to the WAF for processing
    match req.get_header_str("bypass-waf") {
        Some(_) => {
            println!("bypassing waf");
            return (
                req,
                Response::from_status(StatusCode::OK).with_set_header(
                    "x-version",
                    std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new()),
                ),
            );
        }
        _ => {
            let ngwaf_config = fastly::config_store::ConfigStore::open("ngwaf");
            let corp_name = ngwaf_config
                .get("corp")
                .expect("no `corp` present in config");
            let site_name = ngwaf_config
                .get("site")
                .expect("no `site` present in config");

            // clone the request and send the cloned request to the waf inspection.
            let inspection_req = req.clone_with_body();
            let (reqhandle, bodyhandle) = inspection_req.into_handles();
            let bodyhandle = bodyhandle.unwrap_or_else(|| BodyHandle::new());

            let inspectconf: InspectConfig<'_> = InspectConfig::new(&reqhandle, &bodyhandle)
                .corp(&corp_name)
                .workspace(&site_name);
            let waf_result: Result<InspectResponse, InspectError> = inspect(inspectconf);

            match waf_result {
                Ok(inspect_resp) => {
                    // Handling WAF result
                    println!(
                    "waf_status_code: {}\nwaf_tags: {:?}\nwaf_decision_ms: {:?}\nwaf_verdict: {:?}",
                    inspect_resp.status(),
                    inspect_resp.tags(),
                    inspect_resp.decision_ms(),
                    inspect_resp.verdict(),
                    );
                    let waf_inspection_header_val = format_waf_inspection_header(inspect_resp);
                    
                    req.set_header("waf-inspect-data", waf_inspection_header_val);
                }
                Err(y) => match y {
                    InspectError::InvalidConfig => {
                        println!("NGWAF failed because of invalid configuration");
                        return (
                            req,
                            Response::from_status(StatusCode::SERVICE_UNAVAILABLE).with_set_header(
                                "x-version",
                                std::env::var("FASTLY_SERVICE_VERSION")
                                    .unwrap_or_else(|_| String::new()),
                            ),
                        );
                    }
                    InspectError::RequestError(f) => {
                        println!(
                    "Failed to send an inspection request to the NGWAF FastlyStatusCode: {}",
                    f.code
                );
                        return (
                            req,
                            Response::from_status(StatusCode::SERVICE_UNAVAILABLE).with_set_header(
                                "x-version",
                                std::env::var("FASTLY_SERVICE_VERSION")
                                    .unwrap_or_else(|_| String::new()),
                            ),
                        );
                    }
                    _ => println!("Catch-all waf_result"),
                },
            };

            return (
                req,
                Response::from_status(StatusCode::OK).with_set_header(
                    "x-version",
                    std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new()),
                ),
            );
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
