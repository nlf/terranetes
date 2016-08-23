variable "packet_project_id" {}
variable "packet_token" {}
variable "domain" {}

variable "master_name" {
  default = "master"
}

variable "node_count" {
  default = "3"
}

variable "node_plan" {
  default = "baremetal_0"
}

variable "node_facility" {
  default = "ewr1"
}

provider "packet" {
  auth_token = "${var.packet_token}"
}

variable "private_key_path" {}
