# Kubernetes Deployment: NGINX Ingress Controller with Fastly NGWAF Module

This deployment demonstrates how to integrate the Fastly Next-Gen WAF (NGWAF) with the NGINX Ingress Controller using the NGWAF module and agent sidecar pattern.

## Architecture

This deployment creates a Kubernetes cluster with NGINX Ingress Controller enhanced with Fastly NGWAF protection:

1. **NGINX Ingress Controller Pod**: NGINX Ingress Controller with the Fastly NGWAF module loaded
2. **sigsci-agent Sidecar**: The Fastly NGWAF agent running as a sidecar container alongside the ingress controller
3. **Backend Application Pod**: A simple demo application to demonstrate ingress routing

Traffic flows through the NGINX Ingress Controller, which uses the NGWAF module to communicate with the agent sidecar for request inspection before routing to backend services.

```
Client → Ingress Service → NGINX Ingress Controller (with NGWAF module) ↔ sigsci-agent sidecar → Backend Service → Backend Pod
```

## Prerequisites

### Required Tools
- **colima**: Container runtime for macOS/Linux
- **kind**: Kubernetes IN Docker - for running local Kubernetes clusters
- **kubectl**: Kubernetes command-line tool
- **docker**: Docker CLI (used by kind and colima)
- **make**: Build automation tool

### Fastly NGWAF Credentials
- Fastly NGWAF access key ID
- Fastly NGWAF secret access key

### Environment Setup

1. **Install colima** (if not already installed):
   ```bash
   # macOS
   brew install colima
   
   # Linux
   # Follow instructions at: https://github.com/abiosoft/colima
   ```

2. **Install kind** (if not already installed):
   ```bash
   # macOS
   brew install kind
   
   # Linux
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   ```

3. **Install kubectl** (if not already installed):
   ```bash
   # macOS
   brew install kubectl
   
   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   ```

4. **Start colima**:
   ```bash
   colima start --cpu 4 --memory 8 --disk 50
   ```

5. **Create a kind cluster**:
   ```bash
   kind create cluster --name ngwaf-demo
   ```

6. **Verify cluster is running**:
   ```bash
   kubectl cluster-info --context kind-ngwaf-demo
   kubectl get nodes
   ```

7. **Set environment variables**:
   ```bash
   export NGWAFACCESSKEYID="your-access-key-id"
   export NGWAFACCESSKEYSECRET="your-secret-access-key"
   ```

## Deployment

### Build and Deploy

The Makefile automates the entire deployment process:

```bash
make build
```

This will:
1. Build a custom NGINX Ingress Controller Docker image with the Fastly NGWAF module
2. Load the image into the kind cluster
3. Create a Kubernetes secret with your NGWAF credentials
4. Deploy the NGINX Ingress Controller with sigsci-agent sidecar
5. Deploy a demo backend application
6. Create ingress resources to route traffic

### Test the Deployment

Forward the ingress controller service port to your local machine:

```bash
make demo
```

Then in another terminal, test the deployment:

```bash
# Test the demo application through the ingress
curl http://127.0.0.1:8080 -H "Host: demo.example.com"

# Test with a potentially malicious request (should be blocked/logged)
curl "http://127.0.0.1:8080?id=1%20OR%201=1" -H "Host: demo.example.com"
```

You should see responses from the backend application, and all requests will be logged in your Fastly NGWAF dashboard with full inspection details.

## Useful Commands

### View Logs

View NGINX Ingress Controller logs:
```bash
make logs
```

View sigsci-agent sidecar logs:
```bash
make logs-agent
```

View backend application logs:
```bash
make logs-backend
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

To also delete the kind cluster and stop colima:
```bash
make clean-all
```

## Configuration

The deployment uses the following default configuration:

- **NGINX Ingress Controller**:
  - Custom image with Fastly NGWAF module pre-installed
  - Communicates with sigsci-agent via Unix domain socket
  - Listens on port 80
  - Service: `ingress-nginx-controller` (NodePort)

- **sigsci-agent Sidecar**:
  - Image: `signalsciences/sigsci-agent:latest`
  - Runs alongside NGINX Ingress Controller
  - Shared volume for Unix socket communication
  - Debug logging enabled for troubleshooting

- **Backend Application**:
  - Simple HTTP server for demonstration
  - Service: `demo-backend-service` (ClusterIP)
  - Ingress: Routes traffic from `demo.example.com` to backend

### Customizing the Deployment

To modify the configuration:

1. **Edit `Dockerfile`** to customize the NGINX Ingress Controller base image or module installation
2. **Edit `deployment.yaml`** to:
   - Change namespace (currently `default`)
   - Adjust resource limits/requests
   - Modify ingress rules and hostnames
   - Change agent configuration via environment variables
3. **Edit `Makefile`** to add custom commands or change default behavior

## Architecture Details

### NGINX Ingress Controller with NGWAF Module

The NGINX Ingress Controller is built with the Fastly NGWAF module (`ngx_http_fastly_module.so`) which enables:
- Real-time request inspection
- Communication with the sigsci-agent via Unix domain socket
- Minimal performance overhead
- Full visibility into all ingress traffic

### Sidecar Pattern

The sigsci-agent runs as a sidecar container in the same pod as the NGINX Ingress Controller:
- Shares a volume for Unix socket communication
- Processes inspection requests from the NGWAF module
- Sends telemetry and alerts to Fastly NGWAF cloud
- Receives updated rules and configurations

### Volume Sharing

An `emptyDir` volume named `sigsci-tmp` is mounted at `/sigsci/tmp` in both containers:
- NGINX writes requests to `unix:/sigsci/tmp/sigsci.sock`
- sigsci-agent listens on the same socket
- Ensures fast, in-memory communication

## Troubleshooting

### Check if containers are running:
```bash
kubectl get pods -n default
```

### Verify the NGWAF module is loaded:
```bash
kubectl exec -it deployment/nginx-ingress-controller -c nginx-ingress-controller -- nginx -V 2>&1 | grep fastly
```

### Check agent connectivity:
```bash
make logs-agent | grep -i "connected"
```

### View all events:
```bash
kubectl get events --sort-by='.lastTimestamp'
```

### Common Issues

1. **Image pull errors**: Ensure the custom image is built and loaded into kind
2. **Secret not found**: Verify environment variables are set before running `make build`
3. **Socket permission errors**: Check that both containers have proper volume mounts
4. **Connection refused**: Ensure colima is running and kind cluster is created

## Using with colima and kind

This deployment is specifically designed for local development using colima and kind:

- **colima** provides the container runtime
- **kind** creates a Kubernetes cluster in Docker containers
- Images are loaded directly into kind using `kind load docker-image`
- No external registry required

To switch between clusters:
```bash
kubectl config get-contexts
kubectl config use-context kind-ngwaf-demo
```

## Additional Resources

- [Fastly NGWAF Documentation](https://docs.fastly.com/signalsciences/)
- [NGINX Ingress Controller Documentation](https://kubernetes.github.io/ingress-nginx/)
- [kind Documentation](https://kind.sigs.k8s.io/)
- [colima Documentation](https://github.com/abiosoft/colima)

## Notes

- The deployment uses debug logging for all NGWAF components to aid in troubleshooting
- Both pods run in the `default` namespace
- The ingress service uses `NodePort` type for easy local access
- For production deployments, consider using specific agent versions instead of `latest`
- Resource limits should be adjusted based on your traffic patterns
