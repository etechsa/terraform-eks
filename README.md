# EKS Infrastructure as Code

AWS EKS 클러스터를 Terraform으로 완전 자동화하여 배포하는 프로젝트입니다.

## 📋 **프로젝트 개요**

이 프로젝트는 다음 리소스들을 자동으로 생성합니다:
- **VPC 및 네트워크 인프라** (3개 AZ 퍼블릭/프라이빗 서브넷, NAT Gateway)
- **EKS 클러스터** (Kubernetes 1.32 Production 환경)
- **EKS 워커 노드그룹** (t3.medium 인스턴스, 3개 AZ 분산)
- **Bastion 서버** (EIP, kubectl, helm, AWS CLI 사전 설치)
- **IAM 사용자/역할** (환경별 분리된 EKS 접근 권한)
- **보안그룹** (최소 권한 원칙)
- **EC2 키페어** (SSH 접속용)
- **EKS 애드온** (VPC CNI Prefix Delegation, CoreDNS, EBS CSI Driver 등)

## 🏗️ **아키텍처 구조**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           VPC (10.0.0.0/16)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  Public Subnets (a,c,d zone)    │  Private Subnets (a,c,d zone)             │
│  ┌─────────────────────────┐     │  ┌─────────────────────────────────────┐  │
│  │ Bastion Server          │     │  │ EKS Worker Nodes (3 AZ)             │  │
│  │ - kubectl, helm, AWS CLI│     │  │ - t3.medium instances               │  │
│  │ - SSH 접속 가능         │     │  │ - Auto Scaling Group                │  │
│  │ - EKS 관리 도구         │     │  │ - Max 110 Pods per Node             │  │
│  └─────────────────────────┘     │  └─────────────────────────────────────┘  │
│                                  │                                           │
│                                  │  Private Data Subnets (3 AZ)             │
│                                  │  ┌─────────────────────────────────────┐  │
│                                  │  │ Database Layer                      │  │
│                                  │  │ (향후 RDS 등 배치용)               │  │
│                                  │  └─────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📁 **디렉토리 구조**

```
EKS/
├── main.tf                    # 메인 모듈 호출
├── variables.tf               # 전역 변수 정의
├── terraform.tfvars           # 변수 값 설정
├── output.tf                  # 출력값 정의
└── modules/
    ├── iam/                   # IAM 사용자/역할 관리
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── vpc/                   # 네트워크 인프라
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── eks/                   # EKS 클러스터
    │   ├── main.tf
    │   ├── aws-auth.tf        # 접근 권한 자동 설정
    │   ├── variables.tf
    │   └── output.tf
    ├── nodegroup/             # EKS 워커 노드
    │   ├── main.tf
    │   ├── user_data.sh.tpl   # Pod 수 증가 설정 스크립트
    │   ├── variables.tf
    │   └── outputs.tf
    ├── bastion/               # Bastion 서버
    │   ├── main.tf
    │   ├── user_data.sh.tpl   # 초기 설정 스크립트
    │   ├── variables.tf
    │   └── outputs.tf
    └── addons/                # EKS 애드온
        ├── main.tf
        └── variables.tf
```

## 🔐 **IAM 구조 및 권한**

### 📋 **생성되는 IAM 리소스**

| 리소스 | 타입 | 용도 | 권한 |
|--------|------|------|------|
| `etech-hatiolab-developer` | User | 개발자 로컬 환경 | EKS 클러스터 관리자 |
| `etech-hatiolab-service-account` | Role | AWS 콘솔 접근 | EKS 클러스터 관리자 |
| `etech-hatiolab-bastion-server-role` | Role | Bastion 서버 | EKS 접근 + kubectl 실행 |
| `etech-hatiolab-eks-prd-nodegroup-service-role` | Role | Production 워커 노드 | EKS 노드 운영 권한 |
| `etech-hatiolab-eks-prd-cluster-service-role` | Role | Production EKS 클러스터 | 클러스터 운영 권한 |

### 🎯 **EKS 접근 권한 매트릭스**

| 주체 | kubectl | AWS CLI | 콘솔 접근 | 용도 |
|------|---------|---------|-----------|------|
| terraform 실행자 | ✅ | ✅ | ✅ | 인프라 관리 |
| sdp-developer | ✅ | ✅ | ✅ | 개발자 환경 |
| sdp-bastion-server-role | ✅ | ✅ | ❌ | Bastion 서버 |
| sdp-service-account | ✅ | ✅ | ✅ | 콘솔 접근 |

## 🚀 **사용 방법**

### 1️⃣ **사전 준비**

```bash
# 1. AWS CLI 설치 및 설정
aws configure
AWS Access Key ID: [관리자 권한 키]
AWS Secret Access Key: [관리자 시크릿]
Default region name: ap-northeast-2
Default output format: json

# 2. Terraform 설치 (1.4.0 이상)
terraform --version
```

### 2️⃣ **설정 파일 수정**

`terraform.tfvars` 파일에서 원하는 값으로 수정:

```hcl
# 기본 설정
aws_region = "ap-northeast-2"  # 서울 리전
prefix     = "etech-hatiolab"   # 리소스 이름 접두사

# EKS 클러스터 설정
kubernetes_version = "1.32"       # Kubernetes 버전
node_instance_type = "t3.medium"  # 워커 노드 타입
```

### 3️⃣ **배포 실행**

```bash
# 1. 초기화
terraform init

# 2. 계획 확인
terraform plan

# 3. 배포 실행
terraform apply
# "yes" 입력하여 확인

# 4. SSH 키 저장 (Bastion 접속용)
terraform output -raw private_key_pem > etech-hatiolab-key.pem
chmod 400 etech-hatiolab-key.pem
```

### 4️⃣ **Bastion 서버 접속**

```bash
# 1. Bastion IP 확인
terraform output bastion_public_ip

# 2. SSH 접속 (MobaXterm 또는 터미널)
ssh -i etech-hatiolab-key.pem ec2-user@[BASTION_IP]

# 3. EKS 클러스터 확인
kubectl get nodes
kubectl cluster-info
```

## 📋 **생성되는 AWS 리소스 목록**

### 🔐 **IAM 리소스 (8개)**
- `etech-hatiolab-developer` (IAM User)
- `etech-hatiolab-service-account` (IAM Role)
- `etech-hatiolab-bastion-server-role` (IAM Role)
- `etech-hatiolab-bastion-server-instance-profile` (Instance Profile)
- `etech-hatiolab-bastion-server-eks-access` (IAM Policy)
- `etech-hatiolab-eks-prd-cluster-service-role` (IAM Role)
- `etech-hatiolab-eks-prd-nodegroup-service-role` (IAM Role)
- `etech-hatiolab-key` (EC2 Key Pair)

### 🌐 **VPC 리소스 (15개)**
- `etech-hatiolab-vpc` (VPC)
- `etech-hatiolab-igw` (Internet Gateway)
- `etech-hatiolab-public-subnet-a/c/d` (Public Subnets)
- `etech-hatiolab-private-subnet-a/c/d` (Private Subnets)
- `etech-hatiolab-private-data-subnet-a/c/d` (Private Data Subnets)
- `etech-hatiolab-nat-eip` (NAT Gateway EIP)
- `etech-hatiolab-nat-gateway` (NAT Gateway)
- `etech-hatiolab-public-rt` (Public Route Table)
- `etech-hatiolab-private-rt` (Private Route Table)

### 🔒 **보안그룹 (2개)**
- `etech-hatiolab-bastion-sg` (Bastion Security Group)
- `etech-hatiolab-nodegroup-sg` (NodeGroup Security Group)

### ⚙️ **EKS 리소스 (2개) - Production**
- `etech-hatiolab-eks-prd` (EKS Cluster)
- `etech-hatiolab-eks-prd-node-grp` (EKS NodeGroup)

### 🖥️ **EC2 리소스 (2개)**
- `etech-hatiolab-bastion` (Bastion EC2 Instance)
- `etech-hatiolab-bastion-eip` (Bastion EIP)

### 🔧 **EKS 애드온 (5개)**
- `vpc-cni` (VPC CNI 애드온)
- `kube-proxy` (Kube Proxy 애드온)
- `coredns` (CoreDNS 애드온)
- `aws-ebs-csi-driver` (EBS CSI Driver 애드온)
- `eks-pod-identity-agent` (Pod Identity Agent 애드온)

### 🎯 **총 리소스 개수: 34개**

## 🌐 **네트워크 구성**

### 📋 **서브넷 구조 (3개 AZ 고가용성)**

| 서브넷 | CIDR | Zone | 용도 |
|--------|------|------|------|
| public-subnet-a | 10.0.1.0/24 | a | Bastion, NAT Gateway |
| public-subnet-c | 10.0.2.0/24 | c | 로드밸런서 등 |
| **public-subnet-d** | **10.0.3.0/24** | **d** | **로드밸런서 등** |
| private-subnet-a | 10.0.10.0/24 | a | EKS 워커 노드 |
| private-subnet-c | 10.0.20.0/24 | c | EKS 워커 노드 |
| **private-subnet-d** | **10.0.50.0/24** | **d** | **EKS 워커 노드** |
| private-data-subnet-a | 10.0.30.0/24 | a | 데이터베이스 |
| private-data-subnet-c | 10.0.40.0/24 | c | 데이터베이스 |
| **private-data-subnet-d** | **10.0.60.0/24** | **d** | **데이터베이스** |

### 🔒 **보안그룹 규칙**

#### Bastion 보안그룹
- **Inbound**: SSH (22) - 현재 IP만 허용
- **Outbound**: 모든 트래픽 허용

#### NodeGroup 보안그룹
- **Inbound**: Bastion에서 SSH (22) 허용
- **Outbound**: 모든 트래픽 허용

## 🛠️ **주요 기능**

### ✅ **고가용성 아키텍처**
- **3개 AZ (A, C, D)** 에 걸쳐 리소스 분산 배치
- EKS 워커 노드 자동 분산 (라운드 로빈 방식)
- 장애 복구 능력 향상

### ✅ **완전 자동화**
- 모든 리소스가 코드로 관리됨
- 수동 설정 없이 배포 완료
- EKS 접근 권한 자동 설정
- **애드온 버전 동적 관리** (EKS 버전과 자동 호환)

### ✅ **보안 강화**
- 최소 권한 원칙 적용
- 프라이빗 서브넷에 워커 노드 배치
- 현재 IP만 SSH 접근 허용
- EKS 엔드포인트 접근 제어

### ✅ **운영 편의성**
- Bastion 서버에 관리 도구 사전 설치
- kubectl, helm, AWS CLI 즉시 사용 가능
- SSH 키 자동 생성
- **최대 110개 Pod/노드** (VPC CNI Prefix Delegation)

## 🗑️ **리소스 정리**

```bash
# 모든 리소스 삭제
terraform destroy
# "yes" 입력하여 확인
```

## 🔧 **문제 해결**

### ❓ **kubectl 명령어 에러**
```bash
# kubeconfig 재설정
aws eks update-kubeconfig --region ap-northeast-2 --name etech-hatiolab-eks-prd
```

### ❓ **SSH 접속 실패**
```bash
# 현재 IP 확인
curl http://ipv4.icanhazip.com

# 보안그룹 업데이트
terraform apply -refresh-only
```

### ❓ **권한 에러**
- IAM 사용자에 충분한 권한이 있는지 확인
- EKS, EC2, VPC, IAM 관련 권한 필요

## 📞 **지원**

문제가 발생하면 다음을 확인하세요:
1. AWS 자격 증명 설정
2. Terraform 버전 (1.4.0 이상)
3. 리전별 가용 영역 지원 여부
4. IAM 권한 충족 여부
5. kubectl 설치 파일 버전 확인 (EKS 버전과 맞는지 확인 필요)

---

**⚠️ 주의사항**: 이 코드는 학습/개발 목적으로 제작되었습니다. 프로덕션 환경에서는 추가적인 보안 설정이 필요할 수 있습니다.