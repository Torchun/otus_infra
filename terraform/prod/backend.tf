terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-2"
    region     = "ru-central1-a"
    key        = "terraform.tfstate"
    access_key = "IsIs0huRkJ35PGIfxGUc"
    secret_key = "CGh9qIjFdPNU6Ko7GYo3d1IwLALpOYazCj0MXgQ3"

    skip_region_validation      = true
    skip_credentials_validation = true
   }
}
