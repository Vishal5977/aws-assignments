variable "project_name" {
  description = "Prefix for all resource names"
  type        = string
  default     = "xyz-corp-web"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH — restrict to your IP in production"
  type        = string
  default     = "0.0.0.0/0"
}
