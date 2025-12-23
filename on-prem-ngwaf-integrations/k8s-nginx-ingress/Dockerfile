# Dockerfile for NGINX Ingress Controller with Fastly NGWAF Module
# Based on the official NGINX Ingress Controller image

FROM registry.k8s.io/ingress-nginx/controller:v1.11.2

USER root

# Install required dependencies for Alpine Linux
RUN apk update && \
    apk add --no-cache wget

# Add Signal Sciences (Fastly) APK repository key
RUN wget -q https://apk.signalsciences.net/sigsci_apk.pub && \
    mv sigsci_apk.pub /etc/apk/keys/

# Add Signal Sciences repository based on Alpine version
RUN echo https://apk.signalsciences.net/$(grep -oE '[0-9]+\.[0-9]{2}' /etc/alpine-release)/main | tee -a /etc/apk/repositories && \
    apk update

# Install the Fastly NGWAF module for NGINX
# This dynamically detects the NGINX version and installs the compatible module
RUN nginx_version=$(nginx -v 2>&1 | sed 's/.*nginx\///' | cut -d ' ' -f1) && \
    echo "--- Detected NGINX version: ${nginx_version}. Installing matching Fastly module. ---" && \
    apk add --no-cache nginx-module-fastly-nxs~${nginx_version} && \
    unset nginx_version

# Verify the module is installed
RUN ls -la /etc/nginx/modules/ && \
    ls -la /etc/nginx/modules/ngx_http_fastly_module.so || \
    (echo "ERROR: NGWAF module not found!" && exit 1)

# Switch back to the default user for security
USER www-data

# Note: The NGINX Ingress Controller will automatically load modules
# through its configuration management system
