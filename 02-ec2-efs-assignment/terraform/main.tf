terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ══════════════════════════════════════════════════════════════════════════════
# NETWORKING
# ══════════════════════════════════════════════════════════════════════════════

data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Group — EC2 instances ────────────────────────────────────────────
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow SSH inbound and all outbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22; to_port = 22; protocol = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0; to_port = 0; protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ec2-sg" }
}

# ── Security Group — EFS mount target ─────────────────────────────────────────
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  description = "Allow NFS traffic from EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "NFS from EC2 instances"
    from_port       = 2049; to_port = 2049; protocol = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0; to_port = 0; protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-efs-sg" }
}

# ══════════════════════════════════════════════════════════════════════════════
# EFS — Elastic File System (shared across all 3 instances)
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_efs_file_system" "shared_fs" {
  creation_token   = "${var.project_name}-shared-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true

  tags = { Name = "${var.project_name}-shared-efs" }
}

resource "aws_efs_mount_target" "efs_mount" {
  file_system_id  = aws_efs_file_system.shared_fs.id
  subnet_id       = tolist(data.aws_subnets.default.ids)[0]
  security_groups = [aws_security_group.efs_sg.id]
}

# ══════════════════════════════════════════════════════════════════════════════
# AMI DATA SOURCES — 3 different operating systems
# ══════════════════════════════════════════════════════════════════════════════

# Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name";                values = ["amzn2-ami-hvm-*-x86_64-gp2"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}

# Ubuntu 22.04
data "aws_ami" "ubuntu_22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter { name = "name";                values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}

# Red Hat Enterprise Linux 9
data "aws_ami" "rhel_9" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat
  filter { name = "name";                values = ["RHEL-9*GA*x86_64*"] }
  filter { name = "virtualization-type"; values = ["hvm"] }
}

# ══════════════════════════════════════════════════════════════════════════════
# EC2 INSTANCES — one per OS
# ══════════════════════════════════════════════════════════════════════════════

# Instance 1 — Amazon Linux 2
resource "aws_instance" "amazon_linux" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../scripts/mount-efs-amazon-linux.sh", {
    efs_dns = aws_efs_file_system.shared_fs.dns_name
    mount_point = "/mnt/shared-efs"
  })

  tags = { Name = "${var.project_name}-amazon-linux-2", OS = "Amazon Linux 2" }
  depends_on = [aws_efs_mount_target.efs_mount]
}

# Instance 2 — Ubuntu 22.04
resource "aws_instance" "ubuntu" {
  ami                         = data.aws_ami.ubuntu_22.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../scripts/mount-efs-ubuntu.sh", {
    efs_dns = aws_efs_file_system.shared_fs.dns_name
    mount_point = "/mnt/shared-efs"
  })

  tags = { Name = "${var.project_name}-ubuntu-22", OS = "Ubuntu 22.04" }
  depends_on = [aws_efs_mount_target.efs_mount]
}

# Instance 3 — Red Hat Linux
resource "aws_instance" "redhat" {
  ami                         = data.aws_ami.rhel_9.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/../scripts/mount-efs-rhel.sh", {
    efs_dns = aws_efs_file_system.shared_fs.dns_name
    mount_point = "/mnt/shared-efs"
  })

  tags = { Name = "${var.project_name}-rhel-9", OS = "Red Hat Enterprise Linux 9" }
  depends_on = [aws_efs_mount_target.efs_mount]
}
