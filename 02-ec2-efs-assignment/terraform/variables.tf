variable "aws_region"      { default = "us-east-1" }
variable "project_name"    { default = "ec2-efs-assignment" }
variable "instance_type"   { default = "t2.micro" }
variable "key_pair_name"   { type = string }
variable "allowed_ssh_cidr" { default = "0.0.0.0/0" }
