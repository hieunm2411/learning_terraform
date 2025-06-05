output "alb-dns" {
    description = "The DNS name of the load balancer"
    value      = module.blog_alb.dns_name
}
