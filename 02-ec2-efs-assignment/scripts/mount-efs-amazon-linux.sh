#!/bin/bash
# mount-efs-amazon-linux.sh — EFS mount on Amazon Linux 2
set -euo pipefail
EFS_DNS="${efs_dns}"
MOUNT_POINT="${mount_point}"

yum update -y
yum install -y amazon-efs-utils nfs-utils

mkdir -p "$MOUNT_POINT"

# Mount using EFS helper (handles TLS + IAM auth)
mount -t efs -o tls "$EFS_DNS":/ "$MOUNT_POINT"

# Persist mount across reboots
echo "$EFS_DNS:/ $MOUNT_POINT efs defaults,tls,_netdev 0 0" >> /etc/fstab

echo "EFS mounted at $MOUNT_POINT on Amazon Linux 2"
df -h "$MOUNT_POINT"
