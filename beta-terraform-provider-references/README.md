# Beta Fastly Terraform provider reference

A reference implementation for the beta Fastly Terraform provider
([`fastly/fastly-beta`](https://registry.terraform.io/providers/fastly/fastly-beta/latest/docs)),
following the same per-environment, per-concern layout as
[`edge-terraform-starter`](../edge-terraform-starter).

Read these first:

- [Beta Testing Guide](https://registry.terraform.io/providers/fastly/fastly-beta/latest/docs/guides/beta_testing) -
  how to use the beta provider, and how it reports feedback.
- [HCL Syntax Changes](https://registry.terraform.io/providers/fastly/fastly-beta/latest/docs/guides/hcl_syntax_changes) -
  what changed from the legacy `fastly/fastly` provider.

## What's in this repo?

* Per environment directory for Next-Gen WAF security settings
  (`dev-security`, `prod-security`), each owning a `fastly_ngwaf_workspace`.
* Per environment directory for Delivery settings (`dev-delivery`,
  `prod-delivery`), each owning one `fastly_service_cdn_auto` service and any
  number of domains attached to it.
* Reusable `modules/edge-security` and `modules/service-cdn`.

Security and delivery are deliberately kept in separate Terraform state, the
same decoupled-environments pattern `edge-terraform-starter` uses (see
Fastly's
[multiple environments](https://www.fastly.com/documentation/guides/integrations/orchestration/terraform/#multiple-environments)
guidance). Apply order: `*-security` first, then copy its
`ngwaf_workspace_id` output into the matching `*-delivery/inputs.auto.tfvars`,
then apply `*-delivery`.

## Why this differs from `edge-terraform-starter`

This provider is a ground-up rewrite on HashiCorp's Plugin Framework, and is
not a drop-in replacement for `fastly/fastly`. A few differences shape this
reference:

- **Only the Automatic (`_auto`) resource family is usable today.** The
  provider also ships an Explicit family (`fastly_service_backend`,
  `fastly_service_domain`, etc.) for manual version lifecycle management, but
  per the provider's own Beta Testing Guide those resources "aren't usable
  yet." This reference uses `fastly_service_cdn_auto` plus the versionless
  `fastly_domain` and NGWAF resources, which aren't service-version-scoped at
  all.
- **Next-Gen WAF is no longer a separate `sigsci` provider.** It's
  `fastly_ngwaf_workspace` + `fastly_service_product_ngwaf` under the same
  `fastly` provider - no second provider to configure, and no hand-rolled
  dynamic VCL snippets to wire NGWAF into a service.
- **Provider authentication changed**: `api_token` /
  `FASTLY_API_TOKEN`, replacing `api_key` / `FASTLY_API_KEY`. `base_url`,
  `no_auth`, and `force_http2` no longer exist.
- **Product enablement is one resource per product**
  (`fastly_service_product_<name>`), not a nested `product_enablement` block.

## Adding a domain

Each delivery environment reads its domains from `domains.json`, which is
actually decoded with `jsondecode()` and fed through a `for_each` - edit the
file to add or remove a `fastly_domain` attached to that environment's
service:

```json
{
  "domains": [
    { "fqdn": "dev-tf-demo.freetls.fastly.net", "comment": "primary" },
    { "fqdn": "dev-tf-demo-2.freetls.fastly.net", "comment": "secondary" }
  ]
}
```

~> **Important:** `fastly_domain` validates `fqdn` against the live Fastly API
and rejects Fastly's own auto-assigned, per-service shared domain suffixes -
`global.ssl.fastly.net`, `edgecompute.app`, and `us.preview.fastly-edge.com`
all fail with `400 - Bad Request: Invalid value for fqdn`, since those
hostnames are platform-managed and can't be independently claimed as an owned
domain. `freetls.fastly.net` is different: it's a zone customers are meant to
pick their own subdomain under (per [Fastly's routing
docs](https://www.fastly.com/documentation/guides/concepts/routing-traffic-to-fastly/#cdn-services)),
getting a working hostname with a Fastly-provided shared TLS certificate and
no owned domain or custom cert required - which is why the placeholders here
use it. A real owned domain works too; just point its DNS at the service once
`fastly_domain` creates it.

## Pre-requisites

* [Clone this repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
* [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
* A [Fastly API token](https://docs.fastly.com/en/guides/using-api-tokens), exported as `FASTLY_API_TOKEN`

## What's out of scope here

Compute services are not included in this reference - `fastly_service_cdn_auto`
plus Next-Gen WAF is the one fully-working, testable path with the beta
provider today. See the provider's own
[`compute-auto-resource-link`](https://github.com/fastly/terraform-provider-fastly-beta/tree/main/examples/compute-auto-resource-link)
example if you want to explore the Compute pattern (`fastly_service_compute_auto`
with a `package` block).
