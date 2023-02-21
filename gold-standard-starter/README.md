# What's in the Gold Standard Starter?

## Corp configurations
* Request Rule that adds a Signal for requests that matches on System Attacks AND frequent attack sources
* Request Rule for a default geo-blocking policy
* Request Rule that consolidates System Attacks under one Signal
* Request Rule to tag a base set of Anomaly Signals

## Site configurations
* Site Alert that lowers thresholds for Any System Attack Signal
* Rate Limiting rule to detect enumeration attacks


# Step 0 - Pre-requisites
[Install terraform](https://developer.hashicorp.com/terraform/downloads)

# Step 1
Run `terraform init` within the gold-standard-starter directory

# Step 2
Run `terraform apply` within the gold-standard-starter directory
    - You will be prompted to enter details. Enter the appropriate information.
    - You must respond with "yes" for the terraform configuration to actually apply
Alternatively, you may run `terraform apply -parallelism=1 -var="NGWAF_CORP=YOUR_NGWAF_CORP_NAME" -var="NGWAF_SITE=YOUR_NGWAF_SITE_NAME" -var="NGWAF_EMAIL=YOUR_NGWAF_ACCOUNT_EMAIL" ` and then enter your API key when prompted.

# Need to restart?
Just run `terraform destroy` to delete any resources created by terraform after running `terraform apply`. You may supply variables with the `terraform destroy` command in the same fashion as in Step 2
