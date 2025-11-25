# k8s-apache-module

Kubernetes deployment of Apache with Fastly Next-Gen WAF (NGWAF) module on Ubuntu.

This deployment runs the Apache web server with the Fastly NGWAF module alongside the NGWAF agent as a sidecar container in the same pod.

## Architecture

- **Apache Container**: Ubuntu-based Apache with the Fastly NGWAF module installed
- **NGWAF Agent Sidecar**: The sigsci-agent container that communicates with the Fastly cloud
- **Shared Volume**: Unix socket communication between Apache module and agent via `/sigsci/tmp/sigsci.sock`

## Prerequisites

- Kubernetes cluster (kind, minikube, or other)
- kubectl configured to access your cluster
- Docker installed locally
- Fastly NGWAF credentials ([Accessing agent keys](https://www.fastly.com/documentation/guides/next-gen-waf/setup-and-configuration/accessing-agent-keys/))

## Quickstart

1. Set your NGWAF credentials as environment variables:
```bash
export NGWAFACCESSKEYID="your-access-key-id"
export NGWAFACCESSKEYSECRET="your-secret-access-key"
```

2. Build the Docker image and deploy:
```bash
make docker
make rebuild
```

3. Forward the service port and send test requests:
```bash
make demo
# In another terminal:
curl 127.0.0.1:8080
```

## Reference

- [Installing the Apache Module](https://www.fastly.com/documentation/guides/next-gen-waf/setup-and-configuration/module-agent-deployment/apache-module/installing-the-apache-module/)
- [Kubernetes Agent Module Deployment](https://www.fastly.com/documentation/guides/next-gen-waf/setup-and-configuration/kubernetes/kubernetes-agent-module/)
