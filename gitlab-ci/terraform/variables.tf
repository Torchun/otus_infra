variable public_key_path {
  # Описание переменной
  description = "Path to the public key used for ssh access"
}
variable private_key_path {
  # Описание переменной
  description = "Path to the private key used for ssh access"
}
variable subnet_id {
  description = "Subnet"
}
variable service_account_key_file {
  description = "service_account_key_file"
}
variable cloud_id {
  description = "cloud_id"
}
variable folder_id {
  description = "folder_id"
}
variable zone {
  description = "YC zone"
  default     = "ru-central1-a"
}
variable image_id {
  description = "image_id, default for Ubuntu 18.04 LTS"
  default     = "fd8nu2c8tvflvpei3tlj"
}
