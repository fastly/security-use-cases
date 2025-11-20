# Kubernetes Gateway API: sigsci-agent Reverse Proxy to NGINX

This deployment demonstrates how to use the Kubernetes Gateway API with the Fastly Next-Gen WAF (sigsci-agent) in reverse proxy mode to protect a minimal NGINX backend server running in a separate pod.

## Architecture

This deployment leverages the Kubernetes Gateway API to route traffic through the sigsci-agent for inspection before reaching the backend NGINX service.

The deployment creates:

1. **NGINX Backend Pod**: A minimal NGINX server using the `nginx:alpine` image
2. **sigsci-agent Reverse Proxy Pod**: The Fastly NGWAF agent configured in reverse proxy mode
3. **Gateway**: A Kubernetes Gateway API Gateway resource that defines the ingress point
4. **HTTPRoute**: A Kubernetes Gateway API HTTPRoute resource that defines routing rules

Traffic flows through the Gateway API components to the sigsci-agent, which inspects and protects requests before forwarding them to the NGINX backend service.

```
Client → Gateway (port 8000) → HTTPRoute → sigsci-revproxy-service → sigsci-agent pod → nginx-backend-service → nginx pod
```

## Prerequisites

- A Kubernetes cluster (local or cloud-based)
- `kubectl` configured to access your cluster
- **Gateway API CRDs installed** (see [Installation](#gateway-api-installation))
- **Gateway API controller** (e.g., Envoy Gateway, Istio, or other Gateway API implementation)
- Fastly NGWAF access key ID and secret access key
- Set environment variables:
  ```bash
  export NGWAFACCESSKEYID="your-access-key-id"
  export NGWAFACCESSKEYSECRET="your-secret-access-key"
  ```

### Gateway API Installation

The Kubernetes Gateway API requires CRDs to be installed in your cluster. Choose one of the following methods:

#### Option 1: Install Gateway API CRDs Only

If you have an existing Gateway controller:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml
```

#### Option 2: Install Envoy Gateway (includes CRDs)

For a complete Gateway API implementation:

```bash
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.0.0 -n envoy-gateway-system --create-namespace
```

Or using kubectl:

```bash
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.0.0/install.yaml
```

For more details, see:
- [Gateway API Installation Guide](https://gateway-api.sigs.k8s.io/guides/)
- [Envoy Gateway Documentation](https://gateway.envoyproxy.io/latest/user/quickstart/)

## Deployment

### Build and Deploy

```bash
make build
```

This will:
1. Create a Kubernetes secret with your NGWAF credentials
2. Deploy the NGINX backend pod and service
3. Deploy the sigsci-agent reverse proxy pod and service
4. Create the Gateway and HTTPRoute resources

### Test the Deployment

Forward the Gateway port to your local machine:

```bash
make demo
```

Then in another terminal, test the deployment:

```bash
curl http://127.0.0.1:8000
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

View all pods, services, gateways and httproutes:
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
  - Service: `sigsci-revproxy-service` (ClusterIP)
  - Upstream: `http://nginx-backend-service.default.svc.cluster.local:80/`

- **Gateway API Resources**:
  - Gateway: `sigsci-gateway` (listens on port 8000)
  - Gateway Class: `envoy-gateway` (change based on your Gateway controller)
  - HTTPRoute: `nginx-route` (routes all paths to sigsci-revproxy-service)

### Customizing the Deployment

To modify the configuration:

1. Edit `deployment.yaml` to change pod specifications or Gateway resources
2. Update the `gatewayClassName` in the Gateway resource to match your Gateway controller
3. Modify the HTTPRoute rules to customize routing behavior
4. Update the `SIGSCI_REVPROXY_LISTENER` environment variable to change upstream or listener settings
5. Modify the Makefile to add custom commands or change default behavior

## About Kubernetes Gateway API

The Kubernetes Gateway API is the next-generation API for routing and load balancing in Kubernetes. It provides:

- **Role-oriented design**: Separation of concerns between infrastructure providers and application developers
- **Expressive and extensible**: More powerful routing capabilities than Ingress
- **Portable**: Consistent API across different implementations
- **Type-safe**: Strongly typed API with proper validation

Key resources:
- **Gateway**: Defines how traffic enters the cluster (like an Ingress with more capabilities)
- **HTTPRoute**: Defines HTTP routing rules (more expressive than Ingress rules)
- **GatewayClass**: Defines the controller that will manage Gateways

For more information, see the [Gateway API documentation](https://gateway-api.sigs.k8s.io/).

## Notes

- The NGINX backend uses the minimal `nginx:alpine` image with default configuration
- The sigsci-agent is configured with debug logging enabled for troubleshooting
- Both pods run in the `default` namespace
- The Gateway listens on port 8000 for HTTP traffic
- The default `gatewayClassName` is set to `envoy-gateway`, which works with Envoy Gateway controller
- If using a different Gateway controller (e.g., Istio, Kong), update the `gatewayClassName` accordingly
