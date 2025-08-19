output "instance_id" {
  value = aws_instance.bastion.id
}

output "public_ip" {
  value = aws_eip.bastion.public_ip
}

output "eip_allocation_id" {
  value = aws_eip.bastion.id
}

# Bastion IAM 역할은 이제 IAM 모듈에서 관리