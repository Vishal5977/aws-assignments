# ══════════════════════════════════════════════════════════════════════════════
# AWS CLI Reference — EC2 + EFS Assignment
# ══════════════════════════════════════════════════════════════════════════════
# Replace <...> placeholders with your actual resource IDs.
# ══════════════════════════════════════════════════════════════════════════════

REGION="us-east-1"

# ── Step 1: Create EFS File System ────────────────────────────────────────────
aws efs create-file-system \
    --creation-token "ec2-efs-assignment" \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --encrypted \
    --tags Key=Name,Value=ec2-efs-shared \
    --region "$REGION"

# Get EFS ID
aws efs describe-file-systems \
    --query "FileSystems[?Name=='ec2-efs-shared'].FileSystemId" \
    --output text \
    --region "$REGION"

# ── Step 2: Create EFS Mount Target in your subnet ────────────────────────────
aws efs create-mount-target \
    --file-system-id <EFS_ID> \
    --subnet-id <SUBNET_ID> \
    --security-groups <EFS_SG_ID> \
    --region "$REGION"

# Wait for mount target to become available
aws efs describe-mount-targets \
    --file-system-id <EFS_ID> \
    --region "$REGION"

# ── Step 3: Launch 3 EC2 Instances (different OS) ─────────────────────────────

# Amazon Linux 2
aws ec2 run-instances \
    --image-id <AMAZON_LINUX_2_AMI> \
    --instance-type t2.micro \
    --key-name <KEY_PAIR_NAME> \
    --security-group-ids <EC2_SG_ID> \
    --user-data file://scripts/mount-efs-amazon-linux.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=efs-amazon-linux}]' \
    --region "$REGION"

# Ubuntu 22.04
aws ec2 run-instances \
    --image-id <UBUNTU_22_AMI> \
    --instance-type t2.micro \
    --key-name <KEY_PAIR_NAME> \
    --security-group-ids <EC2_SG_ID> \
    --user-data file://scripts/mount-efs-ubuntu.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=efs-ubuntu}]' \
    --region "$REGION"

# Red Hat Linux 9
aws ec2 run-instances \
    --image-id <RHEL_9_AMI> \
    --instance-type t2.micro \
    --key-name <KEY_PAIR_NAME> \
    --security-group-ids <EC2_SG_ID> \
    --user-data file://scripts/mount-efs-rhel.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=efs-rhel}]' \
    --region "$REGION"

# ── Step 4: Verify EFS mount on each instance ─────────────────────────────────
# SSH into each instance and run:
#   df -h /mnt/shared-efs          # confirm mount
#   echo "test" > /mnt/shared-efs/test.txt   # write from one instance
#   cat /mnt/shared-efs/test.txt             # read from another instance

# ── CLEANUP ───────────────────────────────────────────────────────────────────
# terraform destroy -var="key_pair_name=your-key"
