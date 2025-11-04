# Any resource declared with count becomes a list of instances, so you must reference them using []. 
# ex(count): aws_resource_name.terraform_name[index].attribute
# ex(for_each): aws_resource_name.terraform_name["key"].attribute

# ---------- OUTPUTS EC2 ----------
output "public_instance_ids" {
  description = "IDs of public EC2 instances"
  #  inst_key, inst pair example // inst_key => instance object
  #  "public-us-east-1a-1" = { id = "i-0123456789abcdef0", public_ip = "54.45.12.34", private_ip = "10.0.1.10" }
  value = {
    for inst_key, inst in aws_instance.ec2_public :
    inst_key => inst.id
  }
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
