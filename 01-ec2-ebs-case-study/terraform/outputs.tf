output "web_server_public_ip" {
  description = "Public IP of web server in US-East-1"
  value       = aws_instance.web_server.public_ip
}

output "web_server_instance_id" {
  description = "Instance ID of web server in US-East-1"
  value       = aws_instance.web_server.id
}

output "ami_id" {
  description = "AMI created from the web server instance"
  value       = aws_ami_from_instance.web_server_ami.id
}

output "ami_replica_id" {
  description = "Replicated AMI in US-West-2"
  value       = aws_ami_copy.web_server_ami_west.id
}

output "replica_instance_id" {
  description = "Replicated instance ID in US-West-2"
  value       = aws_instance.web_server_replica.id
}

output "volume_a_id" {
  description = "EBS Volume A ID"
  value       = aws_ebs_volume.volume_a.id
}

output "volume_b_id" {
  description = "EBS Volume B ID"
  value       = aws_ebs_volume.volume_b.id
}

output "snapshot_id" {
  description = "Snapshot ID of Volume A backup"
  value       = aws_ebs_snapshot.volume_a_snapshot.id
}
