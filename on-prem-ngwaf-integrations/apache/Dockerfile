# https://docs.fastly.com/en/ngwaf/installing-the-apache-module
FROM ubuntu:24.04
RUN apt update 
RUN apt install -y apache2 
RUN apt install -y apache2-utils 


# Add the version of the Ubuntu package repository that you want to use.
RUN apt-get update
RUN apt-get install -y apt-transport-https wget gnupg
RUN wget -qO - https://apt.signalsciences.net/release/gpgkey | gpg --dearmor -o /usr/share/keyrings/sigsci.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/sigsci.gpg] https://apt.signalsciences.net/release/ubuntu/ noble main" | tee /etc/apt/sources.list.d/sigsci-release.list
RUN apt-get update

# Install the Apache NGWAF module. https://docs.fastly.com/en/ngwaf/installing-the-apache-module
RUN apt-get install sigsci-module-apache

# Enable the NGWAF module.
RUN a2enmod signalsciences

# Install the agent. https://docs.fastly.com/en/ngwaf/installing-the-agent#ubuntu
RUN apt-get install sigsci-agent

# Clean apt to make the container use less storage.
RUN apt clean 

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Entrypoint will run the NGWAF agent and start Apache
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# ENTRYPOINT "/bin/bash"

# steps for demo when entrypoint is "/bin/bash"
# 1. start NGWAF Agent. `sigsci-agent &`
# 2. start Apache with module enabled. `apache2ctl -D FOREGROUND &`
# 3. tail the error and apache logs. `tail /var/log/apache2/error.log -f` and `tail /var/log/apache2/access.log -f`
