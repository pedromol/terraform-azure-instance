variable "client_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "client_certificate_path" {
  type = string
}

variable "cloudflare_api_token" {
  description = "The Cloudflare API token."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "The DNS zone to use."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Public key signature of the ssh key pair"
  type        = string
}

variable "region" {
  type    = string
  default = "brazilsouth"
}

variable "prefix_display_name" {
  description = "Prefix for resources display names"
  default     = ""
  type        = string
}

variable "ingress_allowed_tcp" {
  description = "List of allowed TCP ingress ports"
  type        = list(number)
  default     = [22, 443, 80, 300, 3000]
}

variable "ingress_allowed_udp" {
  description = "List of allowed UDP ingress ports"
  type        = list(number)
  default     = [51820, 20560, 27015, 7777, 8080, 9876, 9877, 27015, 27016]
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  type    = string
  default = "10.0.1.0/24"
}

variable "storage_size_in_gbs" {
  description = "Size in GBs to attach to first instance"
  type        = number
  default     = 64
}

variable "instance_size" {
  type    = string
  default = "Standard_B1s"
}

variable "cloudflare_instance_name" {
  type    = string
  default = "vm0"
}
