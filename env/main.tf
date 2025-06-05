module "dev" {
    source  = "../module"

    environment     = {
        name            = "qa"
        network_prefix  = "10.1"
    }
}
