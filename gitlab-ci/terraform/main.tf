provider "yandex" {
  version                  = "~> 0.35.0"
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_compute_instance" "gitlab" {
  name = "gitlab-ci-vm"

  labels = {
    tags = "gitlab-ci"
  }
  resources {
    core_fraction = 100
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = 50
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = yandex_compute_instance.gitlab.network_interface[0].nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname gitlab-ci-vm"]
  }

  provisioner "local-exec" {
    command = "ansible-playbook playbooks/prepare_gitlab.yml"
    working_dir = "../ansible"
  }

}
