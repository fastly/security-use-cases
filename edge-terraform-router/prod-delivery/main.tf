module "service_vcl" {
    source                           = "../modules/service-vcl"
    fastly_routes                    = var.fastly_routes

    providers = {
        fastly = fastly
    }
}
