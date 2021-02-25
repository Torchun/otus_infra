output "external_ip_address_gitlab" {
  value = yandex_compute_instance.gitlab.network_interface.0.nat_ip_address
}

# generate inventory file for Ansible: won't work because dynamic inventory needed - that file will be created AFTER whole terraform work completed, including provisioners.
#resource "local_file" "inventory_generator" {
#  content = templatefile("./generated_inventory.tpl",
#    {
#      gitlab_names = yandex_compute_instance.gitlab[*].name,
#      gitlab_addrs = yandex_compute_instance.gitlab[*].network_interface.0.nat_ip_address
#
#    }
#  )
#  filename = "../ansible/generated_inventory"
#}
