terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone      = "ru-central1-a"
  token     = var.yc_iam_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

# Создание VPC и подсети
resource "yandex_vpc_network" "this" {
  name = "private"
}

resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.this.id
}

# Создание диска и виртуальной машины
resource "yandex_compute_disk" "boot_disk" {
  count = 2  
  name = "d-${count.index}"
  zone     = "ru-central1-a"
  image_id = "fd85u0rct32prepgjlv0" # Ubuntu 22.04 LTS
  size     = 15
}


resource "yandex_compute_instance" "this" {

  count = 2  
  name = "server-${count.index}"
  allow_stopping_for_update = true
  platform_id               = "standard-v3"
  zone                      = "ru-central1-a"

  resources {
    cores  = "2"
    memory = "4"
  }


  metadata = {
    # foo      = "bar"
    # ssh-keys = "ubuntu:${file("/Users/mchernikov/.ssh/id_ed25519.pub")}"
    user-data = "${file("/Users/mchernikov/my-cloud-training-terraform-project/cloud-init")}"
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot_disk[count.index].id
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.private.id
    nat            = true
    nat_ip_address = yandex_vpc_address.addr[count.index].external_ipv4_address[0].address
  }
}


resource "yandex_vpc_address" "addr" {
  count = 2 
  name = "vm-adress-${count.index}"
  external_ipv4_address {
    zone_id = "ru-central1-a"
  }
}

// Создание сервисного аккаунта
resource "yandex_iam_service_account" "sa" {
  name = "storage-user"
}

// Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "sa-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

// Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

// Создание бакета с использованием ключа
resource "yandex_storage_bucket" "spaaaaace" {
  access_key            = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key            = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket                = "bucket-in-my-space"
  acl                   = "private"
  max_size              = 1024
  default_storage_class = "COLD"
  anonymous_access_flags {
    read        = true
    list        = false
    config_read = false
  }
  # tags = {
  #   <ключ_1> = "<значение_1>"
  #   <ключ_2> = "<значение_2>"
  #   ...
  #   <ключ_n> = "<значение_n>"
  # }
}