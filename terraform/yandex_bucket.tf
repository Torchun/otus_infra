provider "yandex" {
  version                  = "~> 0.35.0"
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_storage_bucket" "tfstate" {
  bucket        = var.bucket_name
  access_key    = var.yabucket_key_id
  secret_key    = var.yabucket_secret
  force_destroy = "true"
}
