variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable subnet_id {
  description = "Subnet"
}
variable db_disk_image {
  description = "Disk image for reddit db"
  default = "fd8gulo0dtv9uu8oqhoi"
}
