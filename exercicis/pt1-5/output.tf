# Any resource declared with count becomes a list of instances, so you must reference them using []. 
# ex(count): aws_resource_name.terraform_name[index].attribute
# ex(for_each): aws_resource_name.terraform_name["key"].attribute

# ---------- OUTPUTS EC2 ----------
output "public_instance_ids" {
  description = "EC2 public instances ID's"
  value       = aws_instance.ec2_public[*].id
}

output "public_instance_public_ips" {
  description = "EC2 public instances public IP's"
  value       = aws_instance.ec2_public[*].public_ip
}

output "public_instance_private_ips" {
  description = "EC2 public instances private IP's"
  value       = aws_instance.ec2_public[*].private_ip
}


output "private_instance_ids" {
  description = "EC2 private instances ID's"
  value       = aws_instance.ec2_private[*].id
}

output "private_instance_private_ips" {
  description = "EC2 private instances private IP's"
  value       = aws_instance.ec2_private[*].private_ip
}

# ---------- OUTPUT S3 ----------
output "s3_bucket_name" {
  description = "Bucket Name"
  value       = var.create_s3_bucket ? aws_s3_bucket.s3_bucket[0].bucket : "S3 bucket creation is set to false"
}
