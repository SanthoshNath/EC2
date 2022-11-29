variable "name_prefix" {
  description = "Prefix to name resources and tags"
  type        = string
  nullable    = false
}

variable "ingress_cidr_blocks" {
  description = "Ingress CIDRs for EC2"
  default     = ["0.0.0.0/0"]
  type        = list(string)
  nullable    = false
}

# VPC
variable "vpc_id" {
  description = "VPC ID"
  type        = string
  nullable    = false
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  nullable    = false
}

variable "nat_gateway_enabled" {
  description = "Switch to enable or disable NAT gateway"
  default     = true
  type        = bool
  nullable    = false
}

# Instance
variable "instance_ami" {
  description = "AMI of the instance"
  type        = string
  nullable    = false
}

variable "instance_type" {
  description = "Type of the instance"
  type        = string
  nullable    = false
}

variable "subnet_id" {
  description = "Subnet where instance to be created"
  type        = string
  nullable    = false
}

variable "user_data_path" {
  description = "Path to the user data file"
  default     = null
  type        = string
}

variable "user_data_arguments" {
  description = "User data arguments. Required only if user_data_path is defined"
  default     = {}
  type        = map(any)
  nullable    = false
}

variable "port" {
  description = "Port in which application is running"
  type        = number
  nullable    = false

  validation {
    condition     = var.port % 1 == 0
    error_message = "Port number should be a whole number"
  }
}

# Load balancer
variable "enable_load_balancer" {
  description = "Switch to enable or disable load balancer"
  default     = false
  type        = bool
  nullable    = false
}
