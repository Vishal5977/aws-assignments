#!/bin/bash
# mount-efs-ubuntu.sh — EFS mount on Ubuntu 22.04
set -euo pipefail
EFS_DNS="${efs_dns}"
MOUNT_POINT="${mount_point}"

apt-get update -y
apt-get install -y nfs-common binutils

# Install amazon-efs-utils from source (not in Ubuntu apt repo)
apt-get install -y git
git clone https://github.com/aws/efs-utils /tmp/efs-utils
cd /tmp/efs-utils
./build-deb.sh
apt-get install -y ./build/amazon-efs-utils*deb

mkdir -p "$MOUNT_POINT"

mount -t efs -o tls "$EFS_DNS":/ "$MOUNT_POINT"

echo "$EFS_DNS:/ $MOUNT_POINT efs defaults,tls,_netdev 0 0" >> /etc/fstab

echo "EFS mounted at $MOUNT_POINT on Ubuntu 22.04"
df -h "$MOUNT_POINT"
