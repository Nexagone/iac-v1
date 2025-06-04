variable "region" {
  type        = string
  default     = "GRA7"
  description = "OVH region"
}

variable "instance_flavor" {
  type        = string
  default     = "d2-2"
  description = "Instance type"
}

variable "ubuntu_image" {
  type        = string
  default     = "Ubuntu 22.04"
  description = "Ubuntu image name"
}

variable "existing_server_ip" {
  type        = string
  description = "IP address of your existing OVH server"
}

variable "ssh_user" {
  type        = string
  description = "SSH user for the existing server"
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to the SSH private key file"
  default     = "~/.ssh/id_rsa"
}

variable "force_update" {
  description = "Force la mise à jour du serveur et de K3s"
  type        = bool
  default     = false
}

variable "update_k3s" {
  description = "Active la mise à jour de K3s lors de la mise à jour du serveur"
  type        = bool
  default     = false
} 