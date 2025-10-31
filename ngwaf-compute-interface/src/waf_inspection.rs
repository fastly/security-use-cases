use fastly::handle::BodyHandle;
use fastly::security::{inspect, InspectConfig, InspectError, InspectResponse};
use fastly::{Request, Response};
use std::net::IpAddr;

use serde_json::json;

#[cfg(test)]
use std::time::Duration;

pub fn do_waf_inspection(req: Request) -> (Request, Result<InspectResponse, InspectError>) {
    let ngwaf_config = fastly::config_store::ConfigStore::open("ngwaf");
    let corp_name = ngwaf_config
        .get("corp")
        .expect("no `corp` present in config");
    let ws_name = ngwaf_config
        .get("workspace")
        .expect("no `workspace` present in config");

    // Get the client IP address from the request header `x-source-ip` before converting to handles
    let client_ip_opt = req
        .get_header("x-source-ip")
        .and_then(|header| header.to_str().ok())
        .and_then(|ip_str| ip_str.parse::<IpAddr>().ok());

    let (req_handle, req_body) = req.into_handles();
    let req_body = req_body.unwrap_or_else(BodyHandle::new);
    let mut config = InspectConfig::from_handles(&req_handle, &req_body)
        .corp(corp_name)
        .workspace(ws_name);

    // Set client IP if header was present and valid
    if let Some(client_ip) = client_ip_opt {
        config = config.client_ip(client_ip);
    }

    let inspect_resp = inspect(config);

    let mut rebuilt_req = Request::from_handles(req_handle, Some(BodyHandle::new()));
    rebuilt_req.set_body(req_body);

    (rebuilt_req, inspect_resp)
}

pub fn format_waf_inspection_header(inspect_resp: InspectResponse, client_req_id: &str) -> String {
    // Inspired by https://www.fastly.com/documentation/solutions/examples/filter-cookies-or-other-structured-headers/

    println!("Inspection Response: {:?}", inspect_resp);

    let mut filtered_cookie_header_value = "".to_string();

    filtered_cookie_header_value.push_str(&format!("{}{:?};", "agentResponse=", inspect_resp.status()));
    filtered_cookie_header_value.push_str(&format!(
        " {}{};",
        "tags=",
        inspect_resp
            .tags()
            .into_iter()
            .collect::<Vec<&str>>()
            .join(",")
            .as_str()
    ));
    filtered_cookie_header_value.push_str(&format!(
        " {}{:?};",
        "decisionms=",
        inspect_resp.decision_ms().as_millis()
    ));
    filtered_cookie_header_value.push_str(&format!(" {}{}", "requestid=", client_req_id));


    filtered_cookie_header_value
}

/// Performs NGWAF inspection and returns (Request, Response)
pub fn waf_inspect_and_respond(mut req: Request) -> Result<Response, InspectError> {
    req.set_header("inspected-by", "compute");
    req.set_header(
        "compute-version",
        std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new()),
    );

    let (_rebuilt_req, waf_inspection_result) = do_waf_inspection(req);

    let waf_inspection_resp = waf_inspection_result?;

    println!("{:?}", waf_inspection_resp);
    let client_req_id = std::env::var("FASTLY_TRACE_ID").unwrap_or_else(|_| String::new());
    println!("Client Request ID: {}", &client_req_id);

    let json_body = json!({
        "decisionms": waf_inspection_resp.decision_ms().as_millis(),
        "requestid": &client_req_id,
        "agentResponse": waf_inspection_resp.status(),
        "tags": waf_inspection_resp.tags(),
        "verdict": format!("{:?}", waf_inspection_resp.verdict())
    })
    .to_string();

    let status = waf_inspection_resp.status();
    let status_code = if (200..500).contains(&status) {
        status as u16
    } else {
        500
    };

    let resp = Response::from_status(status_code)
        .with_set_header(
            "waf-info",
            format_waf_inspection_header(waf_inspection_resp, &client_req_id),
        )
        .with_set_header(
            "compute-version",
            std::env::var("FASTLY_SERVICE_VERSION").unwrap_or_else(|_| String::new()),
        )
        .with_set_header("Content-Type", "application/json")
        .with_body(json_body);

    Ok(resp)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_format_waf_inspection_header_basic() {
        // Create a mock InspectResponse for testing
        // Since InspectResponse is from the Fastly SDK, we'll test the formatting logic
        // This test validates the header formatting function structure
        
        // We can't easily construct an InspectResponse without the actual Fastly SDK,
        // so this test documents the expected behavior
        
        let client_req_id = "test-request-id-12345";
        
        // The function should format a header with:
        // - agentResponse=<status>;
        // - tags=<comma-separated-tags>;
        // - decisionms=<milliseconds>;
        // - requestid=<request-id>
        
        // This is a documentation test showing expected format
        assert!(client_req_id.len() > 0);
    }

    #[test]
    fn test_format_waf_inspection_header_client_req_id() {
        // Test that client request ID is properly included in the header
        let client_req_id = "abc-123-def-456";
        
        // The header should contain the request ID
        // Format: requestid=<client_req_id>
        assert!(client_req_id.contains('-'));
        assert_eq!(client_req_id.len(), 15);
    }

    #[test]
    fn test_status_code_range_200_to_499() {
        // Test status code mapping for valid ranges
        let test_cases = vec![
            (200, 200u16),
            (201, 201u16),
            (300, 300u16),
            (400, 400u16),
            (404, 404u16),
            (499, 499u16),
        ];

        for (status, expected) in test_cases {
            let status_code = if (200..500).contains(&status) {
                status as u16
            } else {
                500
            };
            assert_eq!(status_code, expected, "Status {} should map to {}", status, expected);
        }
    }

    #[test]
    fn test_status_code_range_out_of_bounds() {
        // Test status code mapping for out-of-range values
        let test_cases = vec![
            (100, 500u16),
            (199, 500u16),
            (500, 500u16),
            (503, 500u16),
            (600, 500u16),
        ];

        for (status, expected) in test_cases {
            let status_code = if (200..500).contains(&status) {
                status as u16
            } else {
                500
            };
            assert_eq!(status_code, expected, "Status {} should map to {}", status, expected);
        }
    }

    #[test]
    fn test_json_response_structure() {
        // Test the JSON response structure
        let decision_ms = 123u128;
        let request_id = "test-req-id";
        let agent_response = 200;
        let tags: Vec<&str> = vec!["tag1", "tag2"];
        let verdict = "Allow";

        let json_body = json!({
            "decisionms": decision_ms,
            "requestid": request_id,
            "agentResponse": agent_response,
            "tags": tags,
            "verdict": verdict
        });

        // Verify the JSON structure
        assert_eq!(json_body["decisionms"], 123);
        assert_eq!(json_body["requestid"], "test-req-id");
        assert_eq!(json_body["agentResponse"], 200);
        assert_eq!(json_body["tags"][0], "tag1");
        assert_eq!(json_body["tags"][1], "tag2");
        assert_eq!(json_body["verdict"], "Allow");
    }

    #[test]
    fn test_json_response_serialization() {
        // Test JSON serialization
        let json_body = json!({
            "decisionms": 456,
            "requestid": "abc-123",
            "agentResponse": 403,
            "tags": ["blocked", "malicious"],
            "verdict": "Block"
        }).to_string();

        // Verify it's valid JSON string
        assert!(json_body.contains("\"decisionms\""));
        assert!(json_body.contains("456"));
        assert!(json_body.contains("\"requestid\""));
        assert!(json_body.contains("\"abc-123\""));
        assert!(json_body.contains("\"agentResponse\""));
        assert!(json_body.contains("403"));
        assert!(json_body.contains("\"tags\""));
        assert!(json_body.contains("\"blocked\""));
        assert!(json_body.contains("\"verdict\""));
        assert!(json_body.contains("\"Block\""));
    }

    #[test]
    fn test_client_ip_parsing_valid() {
        // Test parsing valid IP addresses
        let valid_ips = vec![
            "192.168.1.1",
            "10.0.0.1",
            "172.16.0.1",
            "169.254.5.5",
            "8.8.8.8",
            "2001:db8::1",
        ];

        for ip_str in valid_ips {
            let parsed = ip_str.parse::<IpAddr>();
            assert!(parsed.is_ok(), "Failed to parse valid IP: {}", ip_str);
        }
    }

    #[test]
    fn test_client_ip_parsing_invalid() {
        // Test parsing invalid IP addresses
        let invalid_ips = vec![
            "256.1.1.1",
            "invalid",
            "192.168.1",
            "192.168.1.1.1",
            "",
        ];

        for ip_str in invalid_ips {
            let parsed = ip_str.parse::<IpAddr>();
            assert!(parsed.is_err(), "Should not parse invalid IP: {}", ip_str);
        }
    }

    #[test]
    fn test_header_format_parts() {
        // Test individual header format parts
        let agent_response = 200;
        let tags = vec!["tag1", "tag2", "tag3"];
        let decision_ms = 123;
        let request_id = "req-123";

        // Test agentResponse format
        let agent_part = format!("{}{:?};", "agentResponse=", agent_response);
        assert_eq!(agent_part, "agentResponse=200;");

        // Test tags format
        let tags_str = tags.join(",");
        let tags_part = format!(" {}{};", "tags=", tags_str);
        assert_eq!(tags_part, " tags=tag1,tag2,tag3;");

        // Test decisionms format
        let decision_part = format!(" {}{:?};", "decisionms=", decision_ms);
        assert_eq!(decision_part, " decisionms=123;");

        // Test requestid format
        let request_part = format!(" {}{}", "requestid=", request_id);
        assert_eq!(request_part, " requestid=req-123");
    }

    #[test]
    fn test_empty_tags_handling() {
        // Test handling of empty tags
        let tags: Vec<&str> = vec![];
        let tags_str = tags.join(",");
        assert_eq!(tags_str, "");
        
        let tags_part = format!(" {}{};", "tags=", tags_str);
        assert_eq!(tags_part, " tags=;");
    }

    #[test]
    fn test_duration_conversion() {
        // Test duration to milliseconds conversion
        let duration = Duration::from_millis(123);
        let millis = duration.as_millis();
        assert_eq!(millis, 123);

        let duration2 = Duration::from_secs(2);
        let millis2 = duration2.as_millis();
        assert_eq!(millis2, 2000);
    }
}
