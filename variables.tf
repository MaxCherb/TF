variable "cloud_id" {
  description = "cloud_id"
  type        = string
  sensitive   = true

}

variable "folder_id" {
  description = "folder_id"
  type        = string
  sensitive   = true
  # default = var.TF_VAR_YC_FOLDER_ID
}

variable "yc_iam_token" {
  description = "Yandex Cloud authorization token. Use 'yc iam create-token' to receive"
  type        = string
  sensitive   = true
  # default = var.TF_VAR_YC_TOKEN
}