variable "resource_group_name" {
  default = "azurelab"
}

variable "location" {
  default = "ukwest"
}

variable "vnet_cidr_range" {
  default = ["10.1.10.0/24"]
}

variable "subnet_prefixes" {
  default = ["10.1.10.0/24"]
}

variable "subnet_names" {
  default = ["azurelab"]
}

variable "avset_name" {
  default = "azurelab"
}

variable "nsg_name" {
  default = "azurelab"
}

variable "num_control" {
  description = "Control nodes count"
  default     = 1
}

variable "num_worker" {
  description = "Worker nodes count"
  default     = 1
}

variable "num_all" {
  description = "All-in-one nodes count"
  default     = 0
}

variable "prefix" {
  description = "Prefix added to names of all resources"
  default     = "rke"
}

variable "engineer" {
  description = "Responsible engineer's name"
  default     = "cowmeleon"
}

variable "kubernetes_version" {
  default = "v1.19.2-rancher1-1"
}

variable "cluster_name" {
  default = "azurenetes"
}

