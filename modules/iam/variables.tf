# modules/iam/variables.tf
# IAM 모듈 입력 변수 정의

# ==================================================
# 기본 설정
# ==================================================

variable "prefix" {
  description = "IAM 리소스 이름에 사용될 접두사"
  type        = string
}