# NGWAF Edge deployment
As much fun as clicking and typing are, how about we give our weary hands a break and let Terraform do the work?

This terraform implementation will allow you to quickly spin up a VCL service with an NGWAF edge deployment using dynamic snippets. Additional request headers are added to enrich the data that is sent to the Next-Gen WAF based on the blog [Stronger security with a unified CDN and WAF](https://www.fastly.com/blog/stronger-security-with-a-unified-cdn-and-waf).

# Pre-requisites
* [Clone this repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
* [Install terraform](https://developer.hashicorp.com/terraform/downloads)
* [Create an NGWAF API Key](https://docs.fastly.com/signalsciences/developer/using-our-api/#about-api-access-tokens)
* [Create an Fastly API Key](https://docs.fastly.com/en/guides/using-api-tokens)

# New to Terraform?
Check out [Terraform for beginners](https://geekflare.com/terraform-for-beginners/)

# Quick start steps
* Update `VCL_SERVICE_DOMAIN_NAME` in variables.tf with your own custom domain name.
* run `terraform apply` or `terraform apply -auto-approve`
* Enjoy!
* run `terraform destroy` or `terraform destroy -auto-approve` to start fresh

# Noteworthy configurations

The dynamic snippets are set with `managed = false` so that the initial implementation creates a placeholder for these snippets. Fastly is then updating the snippets when a revised integration is created or the `sigsci_edge_deployment_service` resource is applied.

# Want some new functionality or have questions?
Reach out the contributors of this repository.

