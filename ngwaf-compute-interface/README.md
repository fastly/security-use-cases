# Fastly Compute@Edge NGWAF Interface

This service performs WAF inspection on incoming requests and returns inspection results without forwarding to an origin backend.

## Features

- **Authentication**: Validates requests using a `cdn-secret` header
- **WAF Inspection**: Performs NGWAF inspection using Fastly's security inspection API
- **Custom Client IP**: Supports custom client IP via `x-source-ip` header
- **Detailed Response**: Returns JSON with inspection results including:
  - Decision time in milliseconds
  - Request ID (Fastly trace ID)
  - WAF agent response status
  - Security tags applied by NGWAF
  - Inspection verdict
- **Response Headers**: Includes `waf-info` header with formatted inspection details

## Configuration

The service requires a Fastly Config Store named `ngwaf` with the following keys:
- `corp`: Your NGWAF corporation name
- `workspace`: Your NGWAF workspace name

## Request Headers

### Required
- `cdn-secret`: Must be set to `foo` (authentication header)

### Optional
- `x-source-ip`: Custom client IP address for WAF inspection (e.g., `169.254.5.5`)

## Response Format

### Success Response
```json
{
  "decisionms": 123,
  "requestid": "abc123...",
  "agentResponse": 200,
  "tags": ["tag1", "tag2"],
  "verdict": "Allow"
}
```

### Response Headers
- `waf-info`: Formatted string with inspection details
- `compute-version`: Fastly service version
- `Content-Type`: application/json

### Status Codes
- `200-499`: Returns the status code from NGWAF inspection
- `500`: Returned if NGWAF status is outside 200-499 range
- `403`: Returned if `cdn-secret` header is missing or incorrect

## Setup

### 1. Link Service to NGWAF

Follow the [Fastly NGWAF documentation](https://www.fastly.com/documentation/guides/next-gen-waf/setup-and-configuration/edge-deployment/ngwaf-control-panel/setting-up-edge-waf-deployments-using-the-next-gen-waf-control-panel/#creating-the-edge-security-service) to create an edge security service.

```bash
curl -X PUT "https://dashboard.signalsciences.net/api/v0/corps/${corpName}/sites/${siteName}/edgeDeployment" \
  -H "x-api-user:${SIGSCI_EMAIL}" \
  -H "x-api-token:${SIGSCI_TOKEN}" \
  -H "Fastly-Key: ${FASTLY_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"authorizedServices": [ "${fastlySID}" ] }'
```

### 2. Verify Edge Deployment Configuration

```bash
curl -H "x-api-user:${SIGSCI_EMAIL}" -H "x-api-token:${SIGSCI_TOKEN}" \
  -H "Content-Type: application/json" \
  "https://dashboard.signalsciences.net/api/v0/corps/${corpName}/sites/${siteName}/edgeDeployment"
```

### 3. Configure Config Store

Create a config store named `ngwaf` with your corporation and workspace values:
```bash
fastly config-store create --name=ngwaf
fastly config-store-entry create --store-id=<store-id> --key=corp --value=<your-corp-name>
fastly config-store-entry create --store-id=<store-id> --key=workspace --value=<your-workspace-name>
```

## Test Requests

### Basic Request
```bash
curl -i "https://YOURDOMAIN/test" \
  -H "cdn-secret: foo"
```

### With Custom Client IP
```bash
curl -i "https://YOURDOMAIN/test" \
  -H "cdn-secret: foo" \
  -H "x-source-ip: 169.254.5.5"
```

### Test with Suspicious User-Agent (should trigger NGWAF tags)
```bash
curl -i "https://YOURDOMAIN/anything/test" \
  -H "cdn-secret: foo"
```

### Test with Path Traversal (should trigger NGWAF detection)
```bash
curl -i "https://YOURDOMAIN/test?path=../../../../etc/passwd" \
  -H "cdn-secret: foo"
```

### Test Authentication Failure
```bash
curl -i "https://YOURDOMAIN/test"
# Should return 403 Forbidden
```

## Development

### Build
```bash
cargo build
```

### Deploy
```bash
fastly compute publish
```

## Implementation Details

### Modules

#### `main.rs`
- Entry point for the Compute@Edge service
- Validates `cdn-secret` header
- Delegates WAF inspection to `waf_inspection` module
- Returns 403 if authentication fails

#### `waf_inspection.rs`
Contains three main functions:

1. **`do_waf_inspection(req: Request)`**
   - Reads NGWAF config from config store
   - Extracts client IP from `x-source-ip` header if present
   - Configures and executes NGWAF inspection
   - Returns rebuilt request and inspection response

2. **`format_waf_inspection_header(inspect_resp: InspectResponse, client_req_id: &str)`**
   - Formats inspection results into a header-friendly string
   - Includes agent response, tags, decision time, and request ID

3. **`waf_inspect_and_respond(req: Request)`**
   - Main orchestration function
   - Adds metadata headers (`inspected-by`, `compute-version`)
   - Performs WAF inspection
   - Builds JSON response with inspection results
   - Returns appropriate HTTP status code

