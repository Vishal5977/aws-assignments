#!/bin/bash
# ebs-volume-management.sh
# Handles Task 4: detach + delete Volume B, extend Volume A
# Run this script AFTER terraform apply completes
# Usage: ./ebs-volume-management.sh <instance-id> <volume-a-id> <volume-b-id>

set -euo pipefail

INSTANCE_ID="${1:?ERROR: Pass instance ID as argument 1}"
VOLUME_A_ID="${2:?ERROR: Pass Volume A ID as argument 2}"
VOLUME_B_ID="${3:?ERROR: Pass Volume B ID as argument 3}"
REGION="us-east-1"
NEW_SIZE_GB=20    # extend Volume A from 10 GB to 20 GB

echo "=== EBS Volume Management ==="
echo "Instance  : $INSTANCE_ID"
echo "Volume A  : $VOLUME_A_ID  (will be extended to ${NEW_SIZE_GB}GB)"
echo "Volume B  : $VOLUME_B_ID  (will be detached and deleted)"
echo ""

# ── Step 1: Detach Volume B ────────────────────────────────────────────────────
echo "[1/4] Detaching Volume B ($VOLUME_B_ID)..."
aws ec2 detach-volume \
    --volume-id "$VOLUME_B_ID" \
    --instance-id "$INSTANCE_ID" \
    --region "$REGION"

echo "Waiting for Volume B to become available..."
aws ec2 wait volume-available \
    --volume-ids "$VOLUME_B_ID" \
    --region "$REGION"
echo "Volume B detached."

# ── Step 2: Delete Volume B ────────────────────────────────────────────────────
echo "[2/4] Deleting Volume B ($VOLUME_B_ID)..."
aws ec2 delete-volume \
    --volume-id "$VOLUME_B_ID" \
    --region "$REGION"
echo "Volume B deleted."

# ── Step 3: Extend Volume A ────────────────────────────────────────────────────
echo "[3/4] Extending Volume A to ${NEW_SIZE_GB}GB..."
aws ec2 modify-volume \
    --volume-id "$VOLUME_A_ID" \
    --size "$NEW_SIZE_GB" \
    --region "$REGION"

echo "Waiting for Volume A modification to complete..."
aws ec2 wait volume-available \
    --volume-ids "$VOLUME_A_ID" \
    --region "$REGION"
echo "Volume A extended to ${NEW_SIZE_GB}GB."

# ── Step 4: Extend filesystem on the instance ──────────────────────────────────
echo "[4/4] Extending filesystem on instance — connect via SSH and run:"
echo ""
echo "    sudo growpart /dev/xvdf 1"
echo "    sudo resize2fs /dev/xvdf1"
echo ""
echo "=== EBS Volume Management complete ==="
