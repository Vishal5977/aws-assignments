# ══════════════════════════════════════════════════════════════════════════════
# AWS CLI Reference — EC2 + EBS Case Study
# ══════════════════════════════════════════════════════════════════════════════
# These commands document each task step-by-step as an alternative to Terraform.
# Replace placeholder values (<...>) with your actual resource IDs.
# ══════════════════════════════════════════════════════════════════════════════


# ── TASK 1: Launch EC2 Instance in US-East-1 ──────────────────────────────────

# Get latest Amazon Linux 2 AMI ID
aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
              "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text \
    --region us-east-1

# Launch EC2 instance
aws ec2 run-instances \
    --image-id <AMI_ID> \
    --instance-type t2.micro \
    --key-name <KEY_PAIR_NAME> \
    --security-group-ids <SG_ID> \
    --user-data file://scripts/bootstrap-webserver.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=xyz-corp-web-server}]' \
    --region us-east-1


# ── TASK 2: Create AMI and Replicate to US-West-2 ────────────────────────────

# Create AMI from running instance
aws ec2 create-image \
    --instance-id <INSTANCE_ID> \
    --name "xyz-corp-web-ami" \
    --description "Web server AMI for cross-region replication" \
    --region us-east-1

# Wait for AMI to become available
aws ec2 wait image-available \
    --image-ids <AMI_ID> \
    --region us-east-1

# Copy AMI to US-West-2
aws ec2 copy-image \
    --source-image-id <AMI_ID> \
    --source-region us-east-1 \
    --region us-west-2 \
    --name "xyz-corp-web-ami-replica" \
    --description "Replica of xyz-corp web server AMI from us-east-1"

# Launch replicated instance in US-West-2
aws ec2 run-instances \
    --image-id <REPLICA_AMI_ID> \
    --instance-type t2.micro \
    --key-name <KEY_PAIR_NAME> \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=xyz-corp-web-server-replica}]' \
    --region us-west-2


# ── TASK 3: Create and Attach Two EBS Volumes ────────────────────────────────

# Get availability zone of your instance
aws ec2 describe-instances \
    --instance-ids <INSTANCE_ID> \
    --query "Reservations[0].Instances[0].Placement.AvailabilityZone" \
    --output text \
    --region us-east-1

# Create Volume A (10 GB, gp3, encrypted)
aws ec2 create-volume \
    --availability-zone us-east-1a \
    --size 10 \
    --volume-type gp3 \
    --encrypted \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=xyz-corp-volume-a}]' \
    --region us-east-1

# Create Volume B (10 GB, gp3, encrypted)
aws ec2 create-volume \
    --availability-zone us-east-1a \
    --size 10 \
    --volume-type gp3 \
    --encrypted \
    --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=xyz-corp-volume-b}]' \
    --region us-east-1

# Wait for volumes to be available
aws ec2 wait volume-available --volume-ids <VOLUME_A_ID> <VOLUME_B_ID> --region us-east-1

# Attach Volume A to instance
aws ec2 attach-volume \
    --volume-id <VOLUME_A_ID> \
    --instance-id <INSTANCE_ID> \
    --device /dev/xvdf \
    --region us-east-1

# Attach Volume B to instance
aws ec2 attach-volume \
    --volume-id <VOLUME_B_ID> \
    --instance-id <INSTANCE_ID> \
    --device /dev/xvdg \
    --region us-east-1


# ── TASK 4a: Detach and Delete Volume B ──────────────────────────────────────

aws ec2 detach-volume --volume-id <VOLUME_B_ID> --region us-east-1
aws ec2 wait volume-available --volume-ids <VOLUME_B_ID> --region us-east-1
aws ec2 delete-volume --volume-id <VOLUME_B_ID> --region us-east-1


# ── TASK 4b: Extend Volume A from 10 GB to 20 GB ─────────────────────────────

aws ec2 modify-volume \
    --volume-id <VOLUME_A_ID> \
    --size 20 \
    --region us-east-1

# Verify modification state
aws ec2 describe-volumes-modifications \
    --volume-ids <VOLUME_A_ID> \
    --region us-east-1

# SSH into instance and extend the filesystem
# sudo growpart /dev/xvdf 1
# sudo resize2fs /dev/xvdf1
# df -h   # verify new size


# ── TASK 5: Take Snapshot (Backup) of Volume A ───────────────────────────────

aws ec2 create-snapshot \
    --volume-id <VOLUME_A_ID> \
    --description "Backup snapshot of xyz-corp-volume-a" \
    --tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=xyz-corp-volume-a-snapshot}]' \
    --region us-east-1

# Wait for snapshot to complete
aws ec2 wait snapshot-completed --snapshot-ids <SNAPSHOT_ID> --region us-east-1

# Verify snapshot
aws ec2 describe-snapshots \
    --snapshot-ids <SNAPSHOT_ID> \
    --query "Snapshots[0].{ID:SnapshotId,Size:VolumeSize,State:State}" \
    --output table \
    --region us-east-1


# ── CLEANUP (run after assignment is verified) ────────────────────────────────
# terraform destroy -var="key_pair_name=your-key"
