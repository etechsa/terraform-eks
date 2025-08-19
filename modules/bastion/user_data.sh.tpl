#!/bin/bash
# Bastion 서버 초기 설정 스크립트
# EKS 클러스터 관리에 필요한 도구들을 자동 설치
# kubectl, eksctl 설치: https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/install-kubectl.html#kubectl-install-update

# ==================================================
# 시스템 업데이트 및 기본 패키지 설치
# ==================================================
echo "[시스템 업데이트 시작]"
sudo yum update -y
sudo yum install -y curl unzip git jq gettext bash-completion

# ==================================================
# AWS CLI v2 설치 (EKS 관리 필수)
# ==================================================
echo "[AWS CLI v2 설치 시작]"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws
echo "AWS CLI v2 설치 완료"

# ==================================================
# eksctl 설치 (EKS 관리 도구)
# ==================================================
echo "[eksctl 설치 시작]"
# eksctl 최신 버전 다운로드 및 설치
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
echo "eksctl 설치 완료"

# ==================================================
# kubectl 설치 (EKS 호환 버전)
# ==================================================
echo "[kubectl 설치 시작]"
curl -O "https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.3/2025-04-17/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
echo "kubectl 설치 완료"

# ==================================================
# Helm v3 설치 (Kubernetes 패키지 관리자)
# ==================================================
echo "[Helm v3 설치 시작]"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
echo "Helm 설치 완료"

# ==================================================
# EKS kubeconfig 설정
# ==================================================
echo "[EKS kubeconfig 설정 시작]"
sudo mkdir -p /home/ec2-user/.kube
sudo chown ec2-user:ec2-user /home/ec2-user/.kube
sudo aws eks --region ${aws_region} update-kubeconfig --name ${eks_cluster_name} --kubeconfig /home/ec2-user/.kube/config
sudo chown ec2-user:ec2-user /home/ec2-user/.kube/config

# kubeconfig 환경 변수 영구 설정
echo "export KUBECONFIG=/home/ec2-user/.kube/config" | sudo tee -a /home/ec2-user/.bashrc > /dev/null

# ==================================================
# 환경 변수 및 PATH 설정
# ==================================================
echo "[환경 변수 설정]"
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null

# ==================================================
# 설치 완료 로그
# ==================================================
echo "✅ Bastion 서버 도구 설치 완료" > /home/ec2-user/setup_complete.log
echo "- EKS 클러스터: ${eks_cluster_name}" >> /home/ec2-user/setup_complete.log
echo "- 리전: ${aws_region}" >> /home/ec2-user/setup_complete.log
sudo chown ec2-user:ec2-user /home/ec2-user/setup_complete.log