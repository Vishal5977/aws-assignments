# AWS Assignments

Hands-on AWS assignments covering EC2, EBS, EFS, AMI management, and cross-region replication.

## Assignments

| Folder | Assignment | Services Used |
|---|---|---|
| `01-ec2-ebs-case-study` | EC2 instance setup, AMI cross-region replication, EBS volume management and snapshots | EC2, EBS, AMI, Snapshots |
| `02-ec2-efs-assignment` | EFS shared filesystem mounted on 3 EC2 instances with different OS | EC2, EFS, NFS, Security Groups |

## Each assignment includes
- Terraform files for full infrastructure provisioning
- Shell scripts for instance bootstrapping and automation
- AWS CLI reference commands for each task
- Architecture diagram
- README with setup instructions and concept explanations

## Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0
- An existing EC2 key pair in your AWS account
