# modules/nodegroup/outputs.tf
# EKS 노드그룹 모듈 출력값 정의

# ==================================================
# IAM 역할 정보
# ==================================================

output "node_role_arn" {
  description = "EKS 워커 노드 IAM 역할 ARN"
  value       = aws_iam_role.node_role.arn
}

output "node_role_name" {
  description = "EKS 워커 노드 IAM 역할 이름"
  value       = aws_iam_role.node_role.name
}

# ==================================================
# 노드그룹 정보
# ==================================================

output "node_group_arn" {
  description = "EKS 노드그룹 ARN"
  value       = aws_eks_node_group.node_group.arn
}

output "node_group_status" {
  description = "EKS 노드그룹 상태"
  value       = aws_eks_node_group.node_group.status
}