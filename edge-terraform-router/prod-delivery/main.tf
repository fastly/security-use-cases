module "service_vcl" {
    source                           = "../modules/service-vcl"
    fastly_routes                    = var.fastly_routes
    add_header_based_on_path         = var.add_header_based_on_path

    providers = {
        fastly = fastly
    }
}
