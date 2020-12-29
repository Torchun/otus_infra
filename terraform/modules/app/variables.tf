variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable subnet_id {
  description = "Subnet"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "fd8olmief7lme71b4ud5"
}
