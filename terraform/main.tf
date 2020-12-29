provider "yandex" {
  version                  = "~> 0.35.0"
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# resource "yandex_compute_instance" "app" {
#   count = var.instance_count
#   name = "reddit-app-${count.index}"
#   resources {
#     core_fraction = 5
#     cores         = 2
#     memory        = 2
#   }
#   boot_disk {
#     initialize_params {
#       # Указать id образа созданного в предыдущем домашнем задании
#       image_id = var.image_id
#     }
#   }
#   network_interface {
#     # Указан id подсети default-ru-central1-a
#     # subnet_id = var.subnet_id
#     subnet_id = yandex_vpc_subnet.app-subnet.id
#     nat       = true
#   }
#   metadata = {
#     ssh-keys = "ubuntu:${file(var.public_key_path)}"
#   }
#   connection {
#     type  = "ssh"
#     host  = self.network_interface.0.nat_ip_address
#     user  = "ubuntu"
#     agent = false
#     # путь до приватного ключа
#     private_key = file(var.private_key_path)
#   }
#   provisioner "file" {
#     source      = "files/puma.service"
#     destination = "/tmp/puma.service"
#   }
#   provisioner "remote-exec" {
#     script = "files/deploy.sh"
#   }
# }
