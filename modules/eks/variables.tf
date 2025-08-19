# modules/eks/variables.tf
# EKS 클러스터 모듈 입력 변수 정의

# ==================================================
# 기본 설정
# ==================================================

variable "prefix" {
  description = "모든 EKS 리소스 이름에 사용될 접두사"
  type        = string
}

# ==================================================
# 네트워크 설정
# ==================================================

variable "vpc_id" {
  description = "EKS 클러스터가 사용할 VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "EKS 클러스터가 배치될 프라이빗 서브넷 ID 리스트 (다중 AZ 권장)"
  type        = list(string)
}

# ==================================================
# EKS 설정
# ==================================================

variable "kubernetes_version" {
  description = "EKS 클러스터에서 사용할 Kubernetes 버전"
  type        = string
}

variable "service_account_role_arn" {
  description = "AWS 콘솔에서 EKS 클러스터 접근을 위한 서비스 계정 IAM Role ARN"
  type        = string
}

variable "bastion_role_arn" {
  description = "Bastion 서버 IAM 역할 ARN"
  type        = string
}

variable "developer_user_arn" {
  description = "개발자 IAM 사용자 ARN"
  type        = string
}