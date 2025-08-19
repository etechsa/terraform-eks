# modules/iam/outputs.tf
# IAM 모듈 출력값 정의

# ==================================================
# 개발자 사용자 정보
# ==================================================

output "developer_user_arn" {
  description = "개발자 IAM 사용자 ARN"
  value       = aws_iam_user.developer.arn
}

output "developer_access_key_id" {
  description = "개발자 액세스 키 ID"
  value       = aws_iam_access_key.developer.id
}

output "developer_secret_access_key" {
  description = "개발자 시크릿 액세스 키"
  value       = aws_iam_access_key.developer.secret
  sensitive   = true
}

# ==================================================
# 서비스 계정 역할 정보
# ==================================================

output "service_account_role_arn" {
  description = "서비스 계정 IAM 역할 ARN"
  value       = aws_iam_role.service_account.arn
}

# ==================================================
# EC2 키페어 정보
# ==================================================

output "key_pair_name" {
  description = "생성된 EC2 키페어 이름"
  value       = aws_key_pair.ec2_key.key_name
}

output "private_key_pem" {
  description = "EC2 접속용 프라이빗 키 (PEM 형식)"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

# ==================================================
# Bastion IAM 역할 정보
# ==================================================

output "bastion_role_arn" {
  description = "Bastion 서버 IAM 역할 ARN"
  value       = aws_iam_role.bastion_role.arn
}

output "bastion_instance_profile_name" {
  description = "Bastion 인스턴스 프로파일 이름"
  value       = aws_iam_instance_profile.bastion_profile.name
}