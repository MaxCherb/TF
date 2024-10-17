resource "yandex_kubernetes_cluster" "clust" {
  name        = "name"
  description = "description"
  depends_on  = [
    yandex_resourcemanager_folder_iam_member.admin-account-iam,
    ]
  network_id = yandex_vpc_network.this.id

  master {
    # version = "1.17"
    zonal {
      zone      = yandex_vpc_subnet.private.zone
      subnet_id = yandex_vpc_subnet.private.id
    }

    public_ip = true

    # security_group_ids = ["${yandex_vpc_security_group.security_group_name.id}"]

    maintenance_policy {
      auto_upgrade = true

    #   maintenance_window {
    #     start_time = "15:00"
    #     duration   = "3h"
    #   }
    }

    # master_logging {
    #   enabled                    = true
    #   log_group_id               = yandex_logging_group.group1.id
    #   kube_apiserver_enabled     = true
    #   cluster_autoscaler_enabled = true
    #   events_enabled             = true
    #   audit_enabled              = true
    # }
  }

  service_account_id      = yandex_iam_service_account.sa.id
  node_service_account_id = yandex_iam_service_account.sb.id

#   labels = {
#     my_key       = "my_value"
#     my_other_key = "my_other_value"
#   }

  release_channel         = "RAPID"
#   network_policy_provider = "CALICO"

#   kms_provider {
#     key_id = yandex_kms_symmetric_key.key-a.id
#   }
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

resource "yandex_logging_group" "group1" {
  name      = "test-logging-group"
  folder_id = var.folder_id
}

#создание сервисного аккаунта
resource "yandex_iam_service_account" "sa" {
  name        = "tester"
  description = "Service account to be used for provisioning Compute Cloud and VPC resources for Kubernetes cluster. Selected service account should have edit role"
}


resource "yandex_iam_service_account" "sb" {
  name        = "node-tester"
  description = "Service account to be used by the worker nodes of the Kubernetes cluster to access Container Registry or to push node logs and metrics."
}


resource "yandex_resourcemanager_folder_iam_member" "admin-account-iam" {
  folder_id   = var.folder_id
  role        = "editor"
  member      = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}

# resource "yandex_resourcemanager_folder" "folder1" {
#   cloud_id = var.cloud_id
# }



resource "yandex_kubernetes_node_group" "group" {
  cluster_id  = yandex_kubernetes_cluster.clust.id
  name        = "working-pool-${count.index}"
  description = "test working pool k8s"
  version     = "1.27"
  count = 2


  labels = {
    "stage" = "test"
    "level" = "scaling"
  }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = ["${yandex_vpc_subnet.private.id}"]
    }

    resources {
      memory = 2
      cores  = 2
    }
    labels = {
      "stage" = "test"
      "level" = "scaling"
    }
    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = false
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    fixed_scale {
      size = 1
    }
  }

#   allocation_policy {
#     location {
#       zone = "ru-central1-a"
#     }
#   }

#   maintenance_policy {
#     auto_upgrade = true
#     auto_repair  = true

#     maintenance_window {
#       day        = "monday"
#       start_time = "15:00"
#       duration   = "3h"
#     }

#     maintenance_window {
#       day        = "friday"
#       start_time = "10:00"
#       duration   = "4h30m"
#     }
#   }
}
