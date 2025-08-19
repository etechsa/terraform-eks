# modules/vpc/outputs.tf
# VPC 모듈 출력값 정의

# ==================================================
# VPC 정보
# ==================================================

output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

# ==================================================
# 서브넷 정보
# ==================================================

output "public_subnet_a_id" {
  description = "퍼블릭 서브넷 A ID"
  value       = aws_subnet.public_a.id
}

output "public_subnet_c_id" {
  description = "퍼블릭 서브넷 C ID"
  value       = aws_subnet.public_c.id
}

output "public_subnet_d_id" {
  description = "퍼블릭 서브넷 D ID"
  value       = aws_subnet.public_d.id
}

output "private_subnet_a_id" {
  description = "프라이빗 서브넷 A ID"
  value       = aws_subnet.private_a.id
}

output "private_subnet_c_id" {
  description = "프라이빗 서브넷 C ID"
  value       = aws_subnet.private_c.id
}

output "private_subnet_d_id" {
  description = "프라이빗 서브넷 D ID"
  value       = aws_subnet.private_d.id
}

output "private_data_subnet_a_id" {
  description = "프라이빗 데이터 서브넷 A ID"
  value       = aws_subnet.private_data_a.id
}

output "private_data_subnet_c_id" {
  description = "프라이빗 데이터 서브넷 C ID"
  value       = aws_subnet.private_data_c.id
}

output "private_data_subnet_d_id" {
  description = "프라이빗 데이터 서브넷 D ID"
  value       = aws_subnet.private_data_d.id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 리스트 (EKS용)"
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id, aws_subnet.public_d.id]
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 리스트 (EKS용)"
  value       = [aws_subnet.private_a.id, aws_subnet.private_c.id, aws_subnet.private_d.id]
}

output "private_data_subnet_ids" {
  description = "프라이빗 데이터 서브넷 ID 리스트 (DB용)"
  value       = [aws_subnet.private_data_a.id, aws_subnet.private_data_c.id, aws_subnet.private_data_d.id]
}

# ==================================================
# 보안그룹 정보
# ==================================================

output "bastion_security_group_id" {
  description = "Bastion 서버 보안그룹 ID"
  value       = aws_security_group.bastion.id
}

output "nodegroup_security_group_id" {
  description = "EKS 노드그룹 보안그룹 ID"
  value       = aws_security_group.nodegroup.id
}