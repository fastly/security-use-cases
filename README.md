[![Build ngwaf-compute-integration](https://github.com/fastly/security-use-cases/actions/workflows/build-ngwaf-compute-integration.yaml/badge.svg)](https://github.com/fastly/security-use-cases/actions/workflows/build-ngwaf-compute-integration.yaml)
[![Envoy NGWAF Deployment Test](https://github.com/fastly/security-use-cases/actions/workflows/ngwaf-envoy.yaml/badge.svg)](https://github.com/fastly/security-use-cases/actions/workflows/ngwaf-envoy.yaml)
[![k8s module-agent NGWAF Deployment](https://github.com/fastly/security-use-cases/actions/workflows/ngwaf-k8s-module-agent.yaml/badge.svg)](https://github.com/fastly/security-use-cases/actions/workflows/ngwaf-k8s-module-agent.yaml)

# Fastly Next-Gen WAF (NGWAF) Security Use Cases

This repository provides comprehensive examples, integrations, and deployment patterns for Fastly's Next-Gen Web Application Firewall (NGWAF). It includes Terraform configurations, container deployments, Kubernetes integrations, and advanced security implementations to help you quickly deploy and configure NGWAF across various environments.

## Repository Structure

This repository is organized into several key areas, each addressing different deployment scenarios and use cases:

### 🚀 Quick Start Implementations

#### [`gold-standard-starter/`](./gold-standard-starter/)
**Terraform-based comprehensive NGWAF setup with security best practices**
- Pre-configured corp and site rules based on [Stronger security with a unified CDN and WAF](https://www.fastly.com/blog/stronger-security-with-a-unified-cdn-and-waf)
- JA3 signatures and ASN-based detection
- System attack consolidation and anomaly signal tagging  
- Rate limiting for enumeration attack detection
- Geo-blocking policies and malicious attacker identification
- **Quick start**: `terraform init && terraform apply -parallelism=1`

#### [`ngwaf-terraform-edge-deploy/`](./ngwaf-terraform-edge-deploy/)
**Simple Terraform VCL service deployment with NGWAF edge integration**
- VCL service with dynamic snippets for NGWAF integration
- Enriched request headers for enhanced WAF data
- **Quick start**: Update `VCL_SERVICE_DOMAIN_NAME` in variables.tf, then `terraform apply`

### 🖥️ Compute Integration

#### [`ngwaf-compute-integration/`](./ngwaf-compute-integration/)  
**Fastly Compute integration with NGWAF decision engine**
- Pass requests to NGWAF from Compute code
- Make decisions based on WAF analysis response
- Requires linking NGWAF edge deployment to Compute service
- Based on [Next-Gen WAF in Compute tutorial](https://www.fastly.com/documentation/solutions/tutorials/next-gen-waf-compute/)

### 🏢 Enterprise & Advanced Deployments

#### [`ngwaf-terraform-edge-deployment-unified-ui/`](./ngwaf-terraform-edge-deployment-unified-ui/)
**Advanced Terraform configuration with unified UI management**
- NGWAF workspace management
- Centralized configuration for multiple deployments

#### [`protect-cached-content/`](./protect-cached-content/)
**Advanced VCL implementation for inspecting cached content**  
- Allows NGWAF to inspect and act on cached content
- Handles cache HIT scenarios with WAF inspection
- Includes NOOP origin service setup
- Supports blocking/challenging cached content
- **Architecture**: VCL pass → NGWAF inspection → cache delivery or block

### 🐳 Container & Kubernetes Integrations

#### [`on-prem-ngwaf-integrations/`](./on-prem-ngwaf-integrations/)
**Complete suite of containerized and Kubernetes NGWAF deployments**

##### Simple Container Deployment
- **[`simple-container-only/`](./on-prem-ngwaf-integrations/simple-container-only/)**: Basic Docker container NGWAF reverse proxy
  - Single command deployment: `docker run` with NGWAF agent
  - Supports multiple upstream applications
  - API specification integration support

##### Kubernetes Integrations  
- **[`k8s-module-agent/`](./on-prem-ngwaf-integrations/k8s-module-agent/)**: Basic Kubernetes pod with NGWAF agent module
- **[`k8s-nginx-module-agent/`](./on-prem-ngwaf-integrations/k8s-nginx-module-agent/)**: NGINX-based Kubernetes deployment with NGWAF module
- **[`k8s-apache_apisix-rev-proxy/`](./on-prem-ngwaf-integrations/k8s-apache_apisix-rev-proxy/)**: Apache APISIX reverse proxy with NGWAF integration

##### Web Server Integrations
- **[`apache/`](./on-prem-ngwaf-integrations/apache/)**: Apache web server with NGWAF module integration

### 📊 Documentation & Architecture

#### [`diagrams/`](./diagrams/)
**System architecture diagrams and flow documentation**
- Mermaid diagrams showing request flow through NGWAF integrations
- Kubernetes pod architecture illustrations  
- Visual representations of different deployment patterns

## Integration Types Supported

| Integration Type | Use Case | Complexity | Best For |
|------------------|----------|------------|----------|
| **Edge Deployment** | CDN + WAF unified | Low | Most common web applications |
| **Compute Integration** | Custom logic + WAF | Medium | Applications needing custom decision logic |
| **Container/K8s Module** | On-premises/hybrid | Medium | Microservices, on-prem deployments |
| **Reverse Proxy** | Legacy integration | Low | Existing infrastructure integration |
| **Cached Content Protection** | Advanced caching + security | High | High-performance cached applications |

## Quick Start Guide

### For New Users (Recommended)
1. Start with [`gold-standard-starter/`](./gold-standard-starter/) for a comprehensive setup
2. Follow the step-by-step guide in that directory's README

### For Simple Edge Deployment  
1. Use [`ngwaf-terraform-edge-deploy/`](./ngwaf-terraform-edge-deploy/)
2. Update domain name and run `terraform apply`

### For Container/Kubernetes Deployment
1. Choose appropriate integration from [`on-prem-ngwaf-integrations/`](./on-prem-ngwaf-integrations/)
2. Set environment variables `$NGWAFACCESSKEYID` and `$NGWAFACCESSKEYSECRET`
3. Run `make build` or follow specific README instructions

## Prerequisites

Before using any of these implementations, ensure you have:

* [Clone this repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
* [Install Terraform](https://developer.hashicorp.com/terraform/downloads) (for Terraform-based deployments)
* [Create a NextGen WAF API Key](https://docs.fastly.com/signalsciences/developer/using-our-api/#about-api-access-tokens)
* [Create a Fastly Delivery API Key](https://docs.fastly.com/en/guides/using-api-tokens) (for edge deployments)
* Create a NextGen WAF Corp and Site (see individual component documentation)

### Additional Prerequisites by Integration Type

**For Kubernetes deployments:**
- kubectl configured with access to your cluster
- Docker (for building custom images)
- kind or similar for local testing

**For Container deployments:**  
- Docker installed and running
- Access to pull `signalsciences/sigsci-agent` image

**For Compute integration:**
- Fastly CLI tools
- Rust toolchain (for Compute development)

## Architecture Overview

```mermaid
flowchart TB
    Client[HTTP Client]
    
    subgraph "Fastly Edge"
        CDN[Fastly CDN]
        NGWAF_Edge[NGWAF Edge]
        Compute[Fastly Compute]
    end
    
    subgraph "On-Premises/K8s"
        K8s[Kubernetes Pods]
        Container[Docker Containers]
        Apache[Apache Server]
        NGWAF_Agent[NGWAF Agent]
    end
    
    subgraph "Origin"
        Origin[Your Application]
    end
    
    Client --> CDN
    CDN --> NGWAF_Edge
    NGWAF_Edge --> CDN
    CDN --> Compute
    Compute --> Origin
    
    Client --> K8s
    K8s --> NGWAF_Agent
    NGWAF_Agent --> Origin
    
    Client --> Container
    Container --> NGWAF_Agent
    
    Client --> Apache
    Apache --> NGWAF_Agent
    
    classDef fastlyClass fill:#f96
    class CDN,NGWAF_Edge,Compute fastlyClass
```

## Support & Contribution

### New to Terraform?
Check out [Terraform for beginners](https://geekflare.com/terraform-for-beginners/)

### Want some new functionality or have questions?
Reach out to the contributors of this repo by opening an issue or pull request.

### Security
For security-related issues, please see [SECURITY.md](./SECURITY.md)

## License
See [LICENSE](./LICENSE) for details.