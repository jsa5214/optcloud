# Any resource declared with for_each becomes a MAP of instances, so you must reference them using ["key"].attribute
# ex(for_each): aws_resource_name.terraform_name["public-us-east-1a-1"].id

# ---------- OUTPUTS EC2 ----------
# Maps preserve the instance keys you defined with for_each (e.g., "public-us-east-1a-1")
# This makes it easy to correlate attributes back to their instances.

output "public_instance_ids" {
  description = "EC2 public instances IDs keyed by instance key"
  value = {
    for inst_key, inst in aws_instance.ec2_public :
    inst_key => inst.id
  }
}

output "public_instance_public_ips" {
  description = "EC2 public instances public IPs keyed by instance key"
  value = {
    for inst_key, inst in aws_instance.ec2_public :
    inst_key => inst.public_ip
  }
}

output "public_instance_private_ips" {
  description = "EC2 public instances private IPs keyed by instance key"
  value = {
    for inst_key, inst in aws_instance.ec2_public :
    inst_key => inst.private_ip
  }
}

output "private_instance_ids" {
  description = "EC2 private instances IDs keyed by instance key"
  value = {
    for inst_key, inst in aws_instance.ec2_private :
    inst_key => inst.id
  }
}

output "private_instance_private_ips" {
  description = "EC2 private instances private IPs keyed by instance key"
  value = {
    for inst_key, inst in aws_instance.ec2_private :
    inst_key => inst.private_ip
  }
}

# ---------- OUTPUT S3 ----------
# Use of try() avoids errors when the bucket doesn't exist.
# If not created, expose null.
output "s3_bucket_name" {
  description = "Bucket name if created, otherwise null"
  value       = try(aws_s3_bucket.s3_bucket[0].bucket, null)
}