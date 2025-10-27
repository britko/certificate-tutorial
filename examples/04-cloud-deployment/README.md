# 클라우드 배포 예제

이 폴더에는 주요 클라우드 제공업체에서 인증서를 관리하는 실습 예제들이 포함되어 있습니다.

## 📁 파일 구조

```
cloud-deployment/
├── aws/
│   ├── acm/
│   │   ├── certificate.yaml        # ACM 인증서 설정
│   │   ├── alb.yaml                # ALB SSL 설정
│   │   └── cloudfront.yaml         # CloudFront SSL 설정
│   ├── terraform/
│   │   ├── main.tf                 # Terraform 메인 설정
│   │   ├── variables.tf            # 변수 정의
│   │   ├── outputs.tf              # 출력 정의
│   │   └── modules/
│   │       ├── acm/
│   │       ├── alb/
│   │       └── cloudfront/
│   └── cloudformation/
│       ├── certificate.yaml        # CloudFormation 템플릿
│       ├── alb.yaml                # ALB 템플릿
│       └── cloudfront.yaml         # CloudFront 템플릿
├── gcp/
│   ├── ssl-certificates/
│   │   ├── certificate.yaml        # SSL 인증서 설정
│   │   ├── load-balancer.yaml      # 로드밸런서 설정
│   │   └── cloud-run.yaml          # Cloud Run 설정
│   ├── terraform/
│   │   ├── main.tf                 # Terraform 메인 설정
│   │   ├── variables.tf            # 변수 정의
│   │   └── modules/
│   │       ├── ssl-cert/
│   │       └── load-balancer/
│   └── deployment-manager/
│       ├── ssl-cert.yaml           # Deployment Manager 템플릿
│       └── load-balancer.yaml      # 로드밸런서 템플릿
├── azure/
│   ├── key-vault/
│   │   ├── certificate.yaml        # Key Vault 인증서 설정
│   │   ├── app-service.yaml        # App Service SSL 설정
│   │   └── application-gateway.yaml # Application Gateway 설정
│   ├── terraform/
│   │   ├── main.tf                 # Terraform 메인 설정
│   │   ├── variables.tf            # 변수 정의
│   │   └── modules/
│   │       ├── key-vault/
│   │       └── app-service/
│   └── arm-templates/
│       ├── key-vault.json          # ARM 템플릿
│       └── app-service.json        # App Service 템플릿
├── multi-cloud/
│   ├── terraform/
│   │   ├── aws.tf                  # AWS 리소스
│   │   ├── gcp.tf                  # GCP 리소스
│   │   ├── azure.tf                # Azure 리소스
│   │   └── modules/
│   │       ├── aws-cert/
│   │       ├── gcp-cert/
│   │       └── azure-cert/
│   └── ansible/
│       ├── playbook.yml            # Ansible 플레이북
│       ├── inventory.yml           # 인벤토리 설정
│       └── roles/
│           ├── aws-cert/
│           ├── gcp-cert/
│           └── azure-cert/
└── scripts/
    ├── setup-aws.sh                # AWS 환경 설정
    ├── setup-gcp.sh                # GCP 환경 설정
    ├── setup-azure.sh              # Azure 환경 설정
    ├── deploy.sh                   # 통합 배포 스크립트
    └── cleanup.sh                  # 정리 스크립트
```

## 🚀 빠른 시작

### 1. AWS 환경 설정
```bash
# AWS CLI 설정
aws configure

# Terraform 초기화
cd aws/terraform
terraform init
terraform plan
terraform apply
```

### 2. GCP 환경 설정
```bash
# gcloud CLI 설정
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Terraform 초기화
cd gcp/terraform
terraform init
terraform plan
terraform apply
```

### 3. Azure 환경 설정
```bash
# Azure CLI 로그인
az login
az account set --subscription "Your Subscription"

# Terraform 초기화
cd azure/terraform
terraform init
terraform plan
terraform apply
```

## ☁️ AWS Certificate Manager

### ACM 인증서 설정
```yaml
# aws/acm/certificate.yaml
Resources:
  SSLCertificate:
    Type: AWS::CertificateManager::Certificate
    Properties:
      DomainName: !Ref DomainName
      SubjectAlternativeNames:
        - !Sub "*.${DomainName}"
      ValidationMethod: DNS
      DomainValidationOptions:
        - DomainName: !Ref DomainName
          ValidationDomain: !Ref DomainName
        - DomainName: !Sub "*.${DomainName}"
          ValidationDomain: !Ref DomainName

Parameters:
  DomainName:
    Type: String
    Default: example.com
```

### ALB SSL 설정
```yaml
# aws/acm/alb.yaml
Resources:
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub "${AWS::StackName}-alb"
      Scheme: internet-facing
      Type: application
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup

  HTTPSListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 443
      Protocol: HTTPS
      Certificates:
        - CertificateArn: !Ref SSLCertificate
```

## 🌐 Google Cloud SSL

### SSL 인증서 설정
```hcl
# gcp/terraform/main.tf
resource "google_compute_ssl_certificate" "default" {
  name        = "example-ssl-cert"
  description = "SSL certificate for example.com"
  
  private_key = file("path/to/private.key")
  certificate = file("path/to/certificate.crt")
}

resource "google_compute_target_https_proxy" "default" {
  name             = "example-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_ssl_certificate.default.id]
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "example-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.default.address
}
```

### Cloud Run SSL 설정
```yaml
# gcp/ssl-certificates/cloud-run.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: example-service
  annotations:
    run.googleapis.com/ingress: all
    run.googleapis.com/ingress-status: all
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/execution-environment: gen2
    spec:
      containers:
      - image: gcr.io/PROJECT_ID/example-app
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
```

## 🔷 Azure Key Vault

### Key Vault 인증서 설정
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "keyVaultName": {
      "type": "string",
      "defaultValue": "example-keyvault"
    },
    "certificateName": {
      "type": "string",
      "defaultValue": "example-cert"
    }
  },
  "resources": [
    {
      "type": "Microsoft.KeyVault/vaults",
      "apiVersion": "2021-10-01",
      "name": "[parameters('keyVaultName')]",
      "location": "[resourceGroup().location]",
      "properties": {
        "sku": {
          "family": "A",
          "name": "standard"
        },
        "tenantId": "[subscription().tenantId]",
        "accessPolicies": [],
        "enabledForDeployment": false,
        "enabledForDiskEncryption": false,
        "enabledForTemplateDeployment": false
      }
    },
    {
      "type": "Microsoft.KeyVault/vaults/certificates",
      "apiVersion": "2021-10-01",
      "name": "[concat(parameters('keyVaultName'), '/', parameters('certificateName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.KeyVault/vaults', parameters('keyVaultName'))]"
      ],
      "properties": {
        "certificatePolicy": {
          "keyProperties": {
            "exportable": true,
            "keySize": 2048,
            "keyType": "RSA"
          },
          "secretProperties": {
            "contentType": "application/x-pkcs12"
          },
          "x509CertificateProperties": {
            "subject": "CN=example.com",
            "validityInMonths": 12
          }
        }
      }
    }
  ]
}
```

## 🔄 멀티 클라우드 전략

### 통합 Terraform 설정
```hcl
# multi-cloud/terraform/main.tf
# AWS 리소스
module "aws_cert" {
  source = "./modules/aws-cert"
  
  domain_name = var.domain_name
  environment = var.environment
}

# GCP 리소스
module "gcp_cert" {
  source = "./modules/gcp-cert"
  
  domain_name = var.domain_name
  environment = var.environment
}

# Azure 리소스
module "azure_cert" {
  source = "./modules/azure-cert"
  
  domain_name = var.domain_name
  environment = var.environment
}
```

### Ansible 플레이북
```yaml
# multi-cloud/ansible/playbook.yml
---
- name: Deploy SSL certificates across clouds
  hosts: all
  become: yes
  roles:
    - aws-cert
    - gcp-cert
    - azure-cert
  
  vars:
    domain_name: "example.com"
    environment: "production"
```

## 📊 모니터링 및 알림

### 클라우드별 모니터링
```bash
#!/bin/bash
# scripts/monitor-cloud-certs.sh

# AWS CloudWatch 알람
aws cloudwatch put-metric-alarm \
    --alarm-name "SSL-Certificate-Expiry-AWS" \
    --alarm-description "SSL Certificate Expiry Warning" \
    --metric-name DaysToExpiry \
    --namespace AWS/CertificateManager \
    --statistic Average \
    --period 86400 \
    --threshold 30 \
    --comparison-operator LessThanThreshold

# Google Cloud Monitoring 알림
gcloud alpha monitoring policies create \
    --policy-from-file=gcp-monitoring-policy.yaml

# Azure Monitor 알림
az monitor metrics alert create \
    --name "SSL-Certificate-Expiry-Azure" \
    --resource-group example-rg \
    --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/example-rg/providers/Microsoft.KeyVault/vaults/example-keyvault \
    --condition "avg Microsoft.KeyVault/vaults CertificateExpiresInDays < 30" \
    --description "SSL Certificate Expiry Warning"
```

## 🔧 비용 최적화

### 클라우드별 비용 비교
```bash
#!/bin/bash
# scripts/cost-analysis.sh

echo "클라우드별 인증서 비용 분석"
echo "=========================="

# AWS: 사용하지 않는 인증서 정리
echo "AWS ACM 인증서:"
aws acm list-certificates --query 'CertificateSummaryList[?Status==`ISSUED`]' --output table

# Google Cloud: 사용하지 않는 SSL 인증서 정리
echo "Google Cloud SSL 인증서:"
gcloud compute ssl-certificates list --filter="status!=ACTIVE"

# Azure: 사용하지 않는 Key Vault 인증서 정리
echo "Azure Key Vault 인증서:"
az keyvault certificate list --vault-name example-keyvault --query "[?attributes.enabled==false]"
```

## 🧪 테스트 시나리오

### 1. 기본 기능 테스트
```bash
# AWS ALB 테스트
curl -I https://example.com

# Google Cloud 로드밸런서 테스트
curl -I https://example.com

# Azure App Service 테스트
curl -I https://example.com
```

### 2. SSL/TLS 보안 테스트
```bash
# SSL Labs API 테스트
curl -X POST "https://api.ssllabs.com/api/v3/analyze" \
  -d "host=example.com&publish=off&startNew=on" \
  -o ssl-analysis.json

# 결과 확인
cat ssl-analysis.json | jq '.status'
```

### 3. 성능 테스트
```bash
# Apache Bench를 사용한 부하 테스트
ab -n 1000 -c 10 -k https://example.com/

# 응답 시간 측정
curl -w "@curl-format.txt" -o /dev/null -s https://example.com/
```

## 🔍 문제 해결

### 일반적인 문제들
1. **인증서 발급 실패**
   - 해결: DNS 설정 확인, 도메인 소유권 검증

2. **로드밸런서 SSL 설정 오류**
   - 해결: 인증서 ARN 확인, 리스너 설정 검토

3. **멀티 클라우드 동기화 문제**
   - 해결: Terraform 상태 확인, Ansible 연결 검토

## 📚 추가 학습

- [클라우드 제공업체](../../docs/03-production/04-cloud-providers.md)
- [CI/CD 통합](../../docs/04-scenarios/03-ci-cd-integration.md)
- [문제 해결 가이드](../../docs/05-troubleshooting/README.md)

## 💡 핵심 정리

- **AWS ACM**: 무료 무제한 인증서, ALB/CloudFront 통합
- **Google Cloud SSL**: 글로벌 로드밸런서 통합, Cloud Run 지원
- **Azure Key Vault**: 엔터프라이즈급 보안, RBAC 지원
- **멀티 클라우드**: Terraform과 Ansible을 통한 통합 관리
- **비용 최적화**: 사용하지 않는 리소스 정리 및 모니터링

---

**💡 팁**: 각 클라우드 제공업체의 예제를 실행하기 전에 해당 폴더의 README.md를 확인하세요!
