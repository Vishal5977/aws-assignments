terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── Primary provider — US-East-1 (N. Virginia) ─────────────────────────────────
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# ── Secondary provider — US-West-2 (Oregon) ───────────────────────────────────
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

# ══════════════════════════════════════════════════════════════════════════════
# NETWORKING — US-East-1
# ══════════════════════════════════════════════════════════════════════════════

data "aws_vpc" "default" {
  provider = aws.us_east_1
  default  = true
}

data "aws_subnets" "default" {
  provider = aws.us_east_1
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── Security Group ─────────────────────────────────────────────────────────────
resource "aws_security_group" "web_sg" {
  provider    = aws.us_east_1
  name        = "${var.project_name}-web-sg"
  description = "Allow SSH and HTTP for web server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-web-sg" }
}
# ══════════════════════════════════════════════════════════════════════════════
# TASK 1 — EC2 Instance in US-East-1 with Linux
#══════════════════════════════════════════════════════════════════════════════

data "aws_ami" "amazon_linux_2" {
  provider    = aws.us_east_1
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
  provider                    = aws.us_east_1
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/../scripts/bootstrap-webserver.sh")

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  tags = { Name = "${var.project_name}-web-server", Region = "us-east-1" }
}

# ══════════════════════════════════════════════════════════════════════════════
# TASK 2 — AMI from instance + copy to US-West-2
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_ami_from_instance" "web_server_ami" {
  provider           = aws.us_east_1
  name               = "${var.project_name}-web-ami-${formatdate("YYYYMMDD", timestamp())}"
  source_instance_id = aws_instance.web_server.id
  description        = "AMI created from ${var.project_name} web server for cross-region replication"

  tags = { Name = "${var.project_name}-web-ami" }
}

resource "aws_ami_copy" "web_server_ami_west" {
  provider          = aws.us_west_2
  name              = "${var.project_name}-web-ami-replica"
  description       = "Replica of ${var.project_name} web server AMI — replicated from us-east-1"
  source_ami_id     = aws_ami_from_instance.web_server_ami.id
  source_ami_region = "us-east-1"
  encrypted         = true

  tags = { Name = "${var.project_name}-web-ami-replica", Region = "us-west-2" }
}

# Replicated instance in US-West-2 using copied AMI
resource "aws_instance" "web_server_replica" {
  provider      = aws.us_west_2
  ami           = aws_ami_copy.web_server_ami_west.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  tags = { Name = "${var.project_name}-web-server-replica", Region = "us-west-2" }
}

# ══════════════════════════════════════════════════════════════════════════════
# TASK 3 — Two EBS Volumes attached to US-East-1 instance
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_ebs_volume" "volume_a" {
  provider          = aws.us_east_1
  availability_zone = aws_instance.web_server.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true

  tags = { Name = "${var.project_name}-volume-a", Purpose = "data" }
}

resource "aws_ebs_volume" "volume_b" {
  provider          = aws.us_east_1
  availability_zone = aws_instance.web_server.availability_zone
  size              = 10
  type              = "gp3"
  encrypted         = true

  tags = { Name = "${var.project_name}-volume-b", Purpose = "backup-target" }
}

resource "aws_volume_attachment" "volume_a_attach" {
  provider    = aws.us_east_1
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.volume_a.id
  instance_id = aws_instance.web_server.id
}

resource "aws_volume_attachment" "volume_b_attach" {
  provider    = aws.us_east_1
  device_name = "/dev/xvdg"
  volume_id   = aws_ebs_volume.volume_b.id
  instance_id = aws_instance.web_server.id
}

# ══════════════════════════════════════════════════════════════════════════════
# TASK 5 — EBS Snapshot (backup) of Volume A
# ══════════════════════════════════════════════════════════════════════════════

resource "aws_ebs_snapshot" "volume_a_snapshot" {
  provider  = aws.us_east_1
  volume_id = aws_ebs_volume.volume_a.id

  tags = {
    Name        = "${var.project_name}-volume-a-snapshot"
    Description = "Backup snapshot of volume-a"
    CreatedBy   = "Terraform"
  }

  depends_on = [aws_volume_attachment.volume_a_attach]
}


#This is the last line 
