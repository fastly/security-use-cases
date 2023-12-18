# What's in the Gold Standard Starter?

## [Stronger security with a unified CDN and WAF](https://www.fastly.com/blog/stronger-security-with-a-unified-cdn-and-waf)
* Using JA3 signatures and ASNs
* Utilizing the ASN header
* Taking Advantage of the Proxy Headers
* Optimize NGWAF enforcement with the Edge Cloud Network
* The edge specific integration configurations are in [./gold-standard-starter/rules_with_edge_deployment.tf](./gold-standard-starter/rules_with_edge_deployment.tf)


## Corp configurations
* Request Rule that adds a Signal for requests that matches on System Attacks AND frequent attack sources
* Request Rule for a default geo-blocking policy
* Request Rule that consolidates System Attacks under one Signal
* Request Rule to tag a base set of Anomaly Signals

## Site configurations
* Site Alert that lowers thresholds for Any System Attack Signal
* Rate Limiting rule to detect enumeration attacks


# Step 0 - Pre-requisites
* [Clone this repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
* [Install terraform](https://developer.hashicorp.com/terraform/downloads)
* [Create an NGWAF API Key](https://docs.fastly.com/signalsciences/developer/using-our-api/#about-api-access-tokens)

# Step 1
Run `terraform init` within the gold-standard-starter directory

# Step 2
Run `terraform apply -parallelism=1` within the gold-standard-starter directory
    - You will be prompted to enter details. Enter the appropriate information.
    - You must respond with "yes" for the terraform configuration to actually apply
Alternatively, you may run `terraform apply -parallelism=1 -var="NGWAF_CORP=YOUR_NGWAF_CORP_NAME" -var="NGWAF_SITE=YOUR_NGWAF_SITE_NAME" -var="NGWAF_EMAIL=YOUR_NGWAF_ACCOUNT_EMAIL"` and then enter your API key when prompted. Make sure to include `-parallelism=1` to avoid issues when applying many changes at the same time.

# Need to restart?
Just run `terraform destroy -parallelism=1` to delete any resources created by terraform after running `terraform apply -parallelism=1`. You may supply variables with the `terraform destroy -parallelism=1` command in the same fashion as in Step 2
