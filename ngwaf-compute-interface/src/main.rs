// Interface for Fastly Compute@Edge with NGWAF

use fastly::{Error, Request, Response};

mod waf_inspection;

#[fastly::main]
fn main(req: Request) -> Result<Response, Error> {
    // Reject request if the request header cdn-secret is not present or not equal to "foo"
    match req.get_header("cdn-secret") {
        Some(value) if value.to_str().unwrap_or("") == "foo" => {},
        _ => {
            return Ok(Response::from_status(403)
                .with_body_text_plain("Forbidden"));
        }
    }

    // Start - NGWAF
    let resp = match waf_inspection::waf_inspect_and_respond(req) {
        Ok(response) => response,
        Err(e) => panic!("WAF inspection error: {e:?}"),
    };
    // End - NGWAF

    Ok(resp)
}

/*
curl -i "https://YOUR_DOMAIN/anything/asdfasdfasf" -H cdn-secret:foo
curl -i https://YOUR_DOMAIN/test?brooks=../../../../etc/passwd -H cdn-secret:foo
*/

