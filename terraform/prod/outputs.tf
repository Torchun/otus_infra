# output "external_ip_address_app" {
#   value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
# }
# output "loadbalancer_ip_address" {
#   value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
# }

output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
