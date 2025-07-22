FROM nginx:1.28.0-alpine
# Base image for the build
# https://hub.docker.com/_/nginx

# This single RUN instruction performs all necessary steps
RUN apk update && apk add wget
RUN wget -q https://apk.signalsciences.net/sigsci_apk.pub ; mv sigsci_apk.pub /etc/apk/keys
RUN echo https://apk.signalsciences.net/$(grep -oE '[0-9]+\.[0-9]{2}' /etc/alpine-release)/main | tee -a /etc/apk/repositories && apk update
RUN \
    # --- Your Logic Starts Here ---
    #
    # 1. Dynamically get the NGINX version from the base image
    nginx_version=$(nginx -v 2>&1 | sed 's/.*nginx\///' | cut -d ' ' -f1) && \
    \
    # (Optional but good practice) Echo the detected version to the build logs
    echo "--- Detected NGINX version: ${nginx_version}. Installing matching Fastly module. ---" && \
    \
    # 2. Install the Fastly module using apk's tilde (~) for compatible version matching
    apk add --no-cache nginx-module-fastly-nxs~${nginx_version} && \
    \
    # 3. Unset the shell variable to clean up the environment
    # Note: Your original command had 'unset module_version', which is likely a typo.
    # It should be 'unset nginx_version' to match the variable that was set.
    unset nginx_version
    
# ENTRYPOINT ["/docker-entrypoint.sh"]