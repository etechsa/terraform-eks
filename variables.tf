# variables.tf
# EKS 인프라 구성을 위한 전역 변수 정의
# 모든 모듈에서 공통으로 사용되는 설정값들

# ==================================================
# 기본 설정
# ==================================================

variable "aws_region" {
  description = "AWS 리전 (리소스가 생성될 지역)"
  type        = string
  default     = "ap-northeast-2"  # 서울 리전
}

variable "prefix" {
  description = "모든 리소스 이름에 사용될 접두사 (리소스 식별용)"
  type        = string
  default     = "sdp"
}

# ==================================================
# EKS 클러스터 설정
# ==================================================

variable "kubernetes_version" {
  description = "EKS Kubernetes 버전 (지원되는 버전 확인 필요)"
  type        = string
  default     = "1.32"
}

variable "node_instance_type" {
  description = "EKS 워커 노드 EC2 인스턴스 타입 (워크로드에 따라 조정)"
  type        = string
  default     = "t3.medium"  # 2 vCPU, 4GB RAM
}