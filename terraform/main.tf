provider "yandex" {
  version   = "~> 0.35.0"
  service_account_key_file = "/home/pbedyaev/secrets/yc/terraform_key.json"
  cloud_id  = "b1g7kiamf1mjb42t1lpa"
  folder_id = "b1gke8b3gh5mjbpt1qsr"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  resources {
    core_fraction = 5
    cores = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашнем задании
      image_id = "fd86gh35ock232282slf"
    }
  }
  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = "e9b1s7ga4doqd1feqrba"
    nat = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/ubuntu.pub")}"
  }
  connection {
    type = "ssh"
    host = yandex_compute_instance.app.network_interface.0.nat_ip_address
    user = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file("~/.ssh/yc")
  }
  provisioner "file" {
    source = "files/puma.service"
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "files/deploy.sh"
  }
}
