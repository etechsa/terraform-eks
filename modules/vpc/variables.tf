# modules/vpc/variables.tf
# VPC 모듈 입력 변수 정의

# ==================================================
# 기본 설정
# ==================================================

variable "prefix" {
  description = "모든 VPC 리소스 이름에 사용될 접두사"
  type        = string
}

variable "aws_region" {
  description = "VPC가 생성될 AWS 리전"
  type        = string
}