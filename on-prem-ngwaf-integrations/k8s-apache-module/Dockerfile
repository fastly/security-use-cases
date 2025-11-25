# https://www.fastly.com/documentation/guides/next-gen-waf/setup-and-configuration/module-agent-deployment/apache-module/installing-the-apache-module/
FROM ubuntu:24.04

# Install Apache and utilities
RUN apt-get update && \
    apt-get install -y apache2 apache2-utils apt-transport-https wget gnupg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add the Fastly NGWAF package repository
RUN wget -qO - https://apt.signalsciences.net/release/gpgkey | gpg --dearmor -o /usr/share/keyrings/sigsci.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/sigsci.gpg] https://apt.signalsciences.net/release/ubuntu/ noble main" | tee /etc/apt/sources.list.d/sigsci-release.list && \
    apt-get update

# Install the Apache NGWAF module
RUN apt-get install -y sigsci-module-apache && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Enable the NGWAF module
RUN a2enmod signalsciences

# Set environment variables for Apache
ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_PID_FILE=/var/run/apache2/apache2.pid
ENV APACHE_RUN_DIR=/var/run/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2

# Create necessary directories
RUN mkdir -p /var/run/apache2 /var/lock/apache2

# Expose port 80
EXPOSE 80

# Start Apache in foreground mode
CMD ["apache2ctl", "-D", "FOREGROUND"]
