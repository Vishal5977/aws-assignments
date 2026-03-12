output "efs_id"          { value = aws_efs_file_system.shared_fs.id }
output "efs_dns_name"    { value = aws_efs_file_system.shared_fs.dns_name }
output "amazon_linux_ip" { value = aws_instance.amazon_linux.public_ip }
output "ubuntu_ip"       { value = aws_instance.ubuntu.public_ip }
output "redhat_ip"       { value = aws_instance.redhat.public_ip }
