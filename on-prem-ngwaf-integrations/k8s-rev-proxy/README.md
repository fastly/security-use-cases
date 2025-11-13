# Kubernetes Deployment: sigsci-agent Reverse Proxy to NGINX

This deployment demonstrates how to use the Fastly Next-Gen WAF (sigsci-agent) in reverse proxy mode to protect a minimal NGINX backend server running in a separate pod.

## Architecture

This deployment creates two separate pods:

1. **NGINX Backend Pod**: A minimal NGINX server using the `nginx:alpine` image
2. **sigsci-agent Reverse Proxy Pod**: The Fastly NGWAF agent configured in reverse proxy mode

Traffic flows through the sigsci-agent, which inspects and protects requests before forwarding them to the NGINX backend service.

```
Client → sigsci-revproxy-service (NodePort) → sigsci-agent pod → nginx-backend-service → nginx pod
```

## Prerequisites

- A Kubernetes cluster (local or cloud-based)
- `kubectl` configured to access your cluster
- Fastly NGWAF access key ID and secret access key
- Set environment variables:
  ```bash
  export NGWAFACCESSKEYID="your-access-key-id"
  export NGWAFACCESSKEYSECRET="your-secret-access-key"
  ```

## Deployment

### Build and Deploy

```bash
make build
```

This will:
1. Create a Kubernetes secret with your NGWAF credentials
2. Deploy the NGINX backend pod and service
3. Deploy the sigsci-agent reverse proxy pod and service

### Test the Deployment

Forward the sigsci-agent service port to your local machine:

```bash
make demo
```

Then in another terminal, test the deployment:

```bash
curl http://127.0.0.1:8080
```

You should see the default NGINX welcome page, and the request will be logged in your Fastly NGWAF dashboard.

## Useful Commands

### View Logs

View sigsci-agent logs:
```bash
make logs
```

View NGINX backend logs:
```bash
make logs-nginx
```

### Get Status

View all pods and services:
```bash
make get
```

View detailed pod information:
```bash
make describe
```

### Clean Up

Remove all deployed resources:
```bash
make clean
```

## Configuration

The deployment uses the following default configuration:

- **NGINX Backend**: 
  - Image: `nginx:alpine`
  - Internal port: 80
  - Service: `nginx-backend-service` (ClusterIP)

- **sigsci-agent Reverse Proxy**:
  - Image: `signalsciences/sigsci-agent:latest`
  - Listen port: 8080
  - Service: `sigsci-revproxy-service` (NodePort)
  - Upstream: `http://nginx-backend-service.default.svc.cluster.local:80/`

### Customizing the Deployment

To modify the configuration:

1. Edit `deployment.yaml` to change pod specifications
2. Update the `SIGSCI_REVPROXY_LISTENER` environment variable to change upstream or listener settings
3. Modify the Makefile to add custom commands or change default behavior

## Notes

- The NGINX backend uses the minimal `nginx:alpine` image with default configuration
- The sigsci-agent is configured with debug logging enabled for troubleshooting
- Both pods run in the `default` namespace
- The sigsci-revproxy-service uses `NodePort` type for easy external access
- All APISIX dependencies have been removed from this deployment
