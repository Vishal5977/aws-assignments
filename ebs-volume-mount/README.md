# AWS EBS Volume – Mount and Unmount on EC2 (Ubuntu)

## Objective

Attach an AWS EBS (Elastic Block Store) volume to a running EC2 instance, format it, mount it to a directory, verify it, and unmount it cleanly.

---

## Pre-requisites

- AWS account with EC2 access
- A running EC2 instance (Ubuntu 22.04, t2.micro)
- An EBS volume created in the **same Availability Zone** as the EC2 instance
- EBS volume attached to the EC2 instance via AWS Console (as `/dev/xvdf`)

---

## AWS Console Steps

1. Go to **EC2 → Volumes → Create Volume**
2. Choose size (e.g., 8 GiB), same AZ as your instance
3. After creation, select the volume → **Actions → Attach Volume**
4. Select your instance and set device name as `/dev/xvdf`

---

## Commands Used

### 1. Update the package list
```bash
sudo apt update -y
```

### 2. Check existing disk usage (before attaching EBS)
```bash
df -h
lsblk
```
> `df -h` shows mounted filesystems and usage. `lsblk` lists all block devices — confirms EBS volume is visible as `/dev/xvdf`.

### 3. Format the EBS volume
```bash
sudo mkfs -t ext4 /dev/xvdf
```
> Formats the new EBS volume with the ext4 filesystem. **Do this only once** — formatting erases all data on the volume.

### 4. Create a mount point
```bash
sudo mkdir /data
```
> Creates a directory `/data` that will serve as the mount point.

### 5. Mount the EBS volume
```bash
sudo mount /dev/xvdf /data
```
> Mounts the formatted EBS volume to `/data`.

### 6. Verify the mount
```bash
df -h
lsblk
```
> Confirm `/dev/xvdf` is now listed with `/data` as its mount point and available space is visible.

### 7. Unmount the volume
```bash
sudo umount /data
```
> Safely unmounts the volume. Always unmount before detaching from AWS Console.

### 8. Verify after unmount
```bash
df -h
lsblk
```
> Confirms `/data` is no longer listed as a mounted filesystem.

---

## Screenshots

| Step | Screenshot |
|------|------------|
| Before mount – `lsblk` output | *(add screenshot)* |
| After mount – `df -h` showing `/data` | *(add screenshot)* |
| After unmount – `df -h` confirming removal | *(add screenshot)* |

---

## Key Learnings

- EBS is **block storage** — it behaves like a physical hard disk attached to an EC2 instance
- A new EBS volume must be **formatted** before it can be used (unlike EFS which is pre-formatted)
- `lsblk` shows all block devices; `df -h` shows only **mounted** filesystems
- Mounting is **not persistent** across reboots — to make it permanent, add an entry in `/etc/fstab`
- Always **unmount before detaching** from AWS Console to avoid data corruption

---

## Difference: EBS vs EFS

| Feature | EBS | EFS |
|---------|-----|-----|
| Type | Block storage | Network file system (NFS) |
| Attached to | One EC2 instance at a time | Multiple EC2 instances simultaneously |
| Mount command | `mount /dev/xvdf /data` | `mount -t nfs4 <efs-dns>:/ /data` |
| Formatting needed | Yes (mkfs) | No |
| Use case | OS disk, databases | Shared storage across instances |

---

## Tools & Services Used

- AWS EC2
- AWS EBS (Elastic Block Store)
- Ubuntu 22.04
- Linux commands: `lsblk`, `df`, `mkfs`, `mount`, `umount`

---

<img width="977" height="733" alt="image" src="https://github.com/user-attachments/assets/222d605a-2882-44d0-952a-c33d0a72cdfc" />

*Assignment completed as part of AWS/DevOps hands-on training.*
