# 클라우드 제공업체

## 🎯 이 장에서 배울 내용

이 장에서는 주요 클라우드 제공업체의 인증서 관리 서비스를 학습합니다. AWS, Google Cloud, Azure의 네이티브 인증서 서비스와 멀티 클라우드 전략을 다룹니다.

## ☁️ AWS Certificate Manager (ACM)

### 기본 설정

```bash
# AWS CLI 설정
aws configure

# 인증서 요청
aws acm request-certificate \
    --domain-name example.com \
    --subject-alternative-names www.example.com,api.example.com \
    --validation-method DNS \
    --region us-east-1
```

### CloudFormation 템플릿

```yaml
# certificate.yaml
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

### ALB와 통합

```yaml
# alb-with-ssl.yaml
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

### 기본 설정

```bash
# gcloud CLI 설정
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# SSL 인증서 생성
gcloud compute ssl-certificates create example-ssl-cert \
    --domains=example.com,www.example.com \
    --global
```

### Terraform 설정

```hcl
# ssl-certificate.tf
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

### Cloud Run과 통합

```yaml
# cloud-run-service.yaml
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

### 기본 설정

```bash
# Azure CLI 설정
az login
az account set --subscription "Your Subscription"

# Key Vault 생성
az keyvault create \
    --name example-keyvault \
    --resource-group example-rg \
    --location eastus

# 인증서 생성
az keyvault certificate create \
    --vault-name example-keyvault \
    --name example-cert \
    --policy @certificate-policy.json
```

### ARM 템플릿

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

### 통합 관리 솔루션

```yaml
# multi-cloud-cert-manager.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: aws-acm-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: aws-acm-issuer
    solvers:
    - dns01:
        route53:
          region: us-east-1
          accessKeyID: YOUR_AWS_ACCESS_KEY_ID
          secretAccessKeySecretRef:
            name: aws-secret
            key: secret-access-key
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: gcp-dns-issuer
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: gcp-dns-issuer
    solvers:
    - dns01:
        cloudDNS:
          project: YOUR_GCP_PROJECT
          serviceAccountSecretRef:
            name: gcp-service-account
            key: key.json
```

### 환경별 인증서 전략

```yaml
# environment-strategy.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: production-cert
  namespace: production
spec:
  secretName: production-tls
  issuerRef:
    name: aws-acm-issuer
    kind: ClusterIssuer
  dnsNames:
  - prod.example.com
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: staging-cert
  namespace: staging
spec:
  secretName: staging-tls
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
  dnsNames:
  - staging.example.com
```

## 📊 모니터링 및 알림

### 클라우드별 모니터링

#### AWS CloudWatch
```bash
# CloudWatch 알람 설정
aws cloudwatch put-metric-alarm \
    --alarm-name "SSL-Certificate-Expiry" \
    --alarm-description "SSL Certificate Expiry Warning" \
    --metric-name DaysToExpiry \
    --namespace AWS/CertificateManager \
    --statistic Average \
    --period 86400 \
    --threshold 30 \
    --comparison-operator LessThanThreshold
```

#### Google Cloud Monitoring
```bash
# Cloud Monitoring 알림 정책
gcloud alpha monitoring policies create \
    --policy-from-file=ssl-cert-policy.yaml
```

#### Azure Monitor
```bash
# Azure Monitor 알림 규칙
az monitor metrics alert create \
    --name "SSL-Certificate-Expiry" \
    --resource-group example-rg \
    --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/example-rg/providers/Microsoft.KeyVault/vaults/example-keyvault \
    --condition "avg Microsoft.KeyVault/vaults CertificateExpiresInDays < 30" \
    --description "SSL Certificate Expiry Warning"
```

## 🔧 비용 최적화

### 클라우드별 비용 비교

| 서비스 | 무료 제공량 | 추가 비용 |
|--------|-------------|-----------|
| **AWS ACM** | 무제한 | 무료 |
| **Google Cloud SSL** | 무제한 | 무료 |
| **Azure Key Vault** | 월 10,000 트랜잭션 | $0.03/10,000 트랜잭션 |
| **Let's Encrypt** | 무제한 | 무료 |

### 비용 최적화 전략

```bash
#!/bin/bash
# cost-optimization.sh

# AWS: 사용하지 않는 인증서 정리
aws acm list-certificates --query 'CertificateSummaryList[?Status==`ISSUED`]' --output table

# Google Cloud: 사용하지 않는 SSL 인증서 정리
gcloud compute ssl-certificates list --filter="status!=ACTIVE"

# Azure: 사용하지 않는 Key Vault 인증서 정리
az keyvault certificate list --vault-name example-keyvault --query "[?attributes.enabled==false]"
```

## 📚 다음 단계

클라우드 제공업체 인증서 관리를 완료했다면 다음 단계로 진행하세요:

- **[고급 주제](../advanced/README.md)** - 전문가 수준의 인증서 관리
- **[실제 시나리오](../scenarios/README.md)** - 복잡한 아키텍처 적용
- **[문제 해결](../troubleshooting/README.md)** - 운영 중 발생하는 문제들

## 💡 핵심 정리

- **AWS ACM**: 무료 무제한 인증서, ALB/CloudFront 통합
- **Google Cloud SSL**: 글로벌 로드밸런서 통합, Cloud Run 지원
- **Azure Key Vault**: 엔터프라이즈급 보안, RBAC 지원
- **멀티 클라우드**: 환경별 최적화된 전략 수립
- **비용 최적화**: 사용하지 않는 리소스 정리 및 모니터링

---

**다음: [고급 주제](../advanced/README.md)**
