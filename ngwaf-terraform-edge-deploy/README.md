# security-use-cases
As much fun as clicking and typing are, how about we give our weary hands a break and let Terraform do the work?

# What's been implemented so far?
## Gold Standard Starter
[Quick start your Fastly NextGen WAF implementations](https://github.com/fastly/security-use-cases/tree/main/gold-standard-starter)

# Pre-requisites
* [Clone this repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
* [Install terraform](https://developer.hashicorp.com/terraform/downloads)
* [Create an NGWAF API Key](https://docs.fastly.com/signalsciences/developer/using-our-api/#about-api-access-tokens)
* [Create an Fastly API Key](https://docs.fastly.com/en/guides/using-api-tokens)

# New to Terraform?
Check out [Terraform for beginners](https://geekflare.com/terraform-for-beginners/)

Steps
* Update `VCL_SERVICE_DOMAIN_NAME` in variables.tf with your own custom domain name.
* run `terraform apply`
* Enjoy!
* run `terraform destroy` to start fresh

# Noteworthy configurations
The following is set in the lifecycle for the VCL service resource.

```
  lifecycle {
    ignore_changes = [
      dynamicsnippet,
      product_enablement,
    ]
  }
```
# Want some new functionality or have questions?
Reach out Max Anderson, Guy Brown, or Brooks Cunningham on the TSG team.

