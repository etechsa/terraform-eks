# modules/bastion/variables.tf
# Bastion 호스트 모듈 입력 변수 정의

# ==================================================
# 기본 설정
# ==================================================

variable "prefix" {
  description = "Bastion 리소스 이름에 사용될 접두사"
  type        = string
}

# ==================================================
# 네트워크 설정
# ==================================================

variable "public_subnet_id" {
  description = "Bastion 서버가 배치될 퍼블릭 서브넷 ID (외부 접근 가능)"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Bastion 서버에 연결할 기존 보안 그룹 ID (SSH 접근 규칙 포함)"
  type        = string
}

# ==================================================
# 접근 설정
# ==================================================

variable "key_name" {
  description = "Bastion 서버 SSH 접속용 EC2 키페어 이름"
  type        = string
}

# ==================================================
# EKS 연동 설정
# ==================================================

variable "eks_cluster_name" {
  description = "관리할 EKS 클러스터 이름 (kubeconfig 설정용)"
  type        = string
}

variable "aws_region" {
  description = "AWS 리전 (AWS CLI 및 kubeconfig 설정용)"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes 버전 (kubectl 다운로드용)"
  type        = string
}

variable "bastion_instance_profile_name" {
  description = "Bastion 인스턴스 프로파일 이름 (IAM 모듈에서 생성)"
  type        = string
}