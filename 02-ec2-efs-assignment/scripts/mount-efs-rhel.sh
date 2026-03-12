#!/bin/bash
# mount-efs-rhel.sh — EFS mount on Red Hat Enterprise Linux 9
set -euo pipefail
EFS_DNS="${efs_dns}"
MOUNT_POINT="${mount_point}"

yum update -y
yum install -y nfs-utils amazon-efs-utils

mkdir -p "$MOUNT_POINT"

mount -t efs -o tls "$EFS_DNS":/ "$MOUNT_POINT"

echo "$EFS_DNS:/ $MOUNT_POINT efs defaults,tls,_netdev 0 0" >> /etc/fstab

echo "EFS mounted at $MOUNT_POINT on RHEL 9"
df -h "$MOUNT_POINT"
