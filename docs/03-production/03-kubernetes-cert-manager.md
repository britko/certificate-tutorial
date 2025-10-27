# Kubernetes cert-manager

## 🎯 이 장에서 배울 내용

이 장에서는 Kubernetes 환경에서 cert-manager를 사용한 인증서 관리 방법을 학습합니다. 자동 발급부터 고가용성 설정까지, 컨테이너 환경에서 필요한 모든 인증서 관리 기술을 다룹니다.

## 🚀 cert-manager 설치

### Helm을 사용한 설치 (권장)

```bash
# Helm 저장소 추가
helm repo add jetstack https://charts.jetstack.io
helm repo update

# cert-manager 설치
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.13.0 \
    --set installCRDs=true
```

### kubectl을 사용한 설치

```bash
# CRD 설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 설치 확인
kubectl get pods -n cert-manager
```

## 🔧 ClusterIssuer 설정

### Let's Encrypt ClusterIssuer

```yaml
# letsencrypt-staging.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
```

```yaml
# letsencrypt-prod.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
# ClusterIssuer 적용
kubectl apply -f letsencrypt-staging.yaml
kubectl apply -f letsencrypt-prod.yaml

# 상태 확인
kubectl get clusterissuer
```

## 🌐 Ingress와 인증서 통합

### 기본 Ingress 설정

```yaml
# ingress-basic.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - example.com
    - www.example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

### 와일드카드 인증서 설정

```yaml
# wildcard-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wildcard-example-com
  namespace: default
spec:
  secretName: wildcard-example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - "*.example.com"
  - "example.com"
```

```yaml
# ingress-wildcard.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: wildcard-ingress
spec:
  tls:
  - hosts:
    - "*.example.com"
    - "example.com"
    secretName: wildcard-example-com-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 80
```

## 🔐 DNS 챌린지 설정

### Cloudflare DNS 챌린지

```yaml
# cloudflare-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-api-token
  namespace: cert-manager
type: Opaque
stringData:
  api-token: YOUR_CLOUDFLARE_API_TOKEN
```

```yaml
# cloudflare-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cloudflare
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-cloudflare
    solvers:
    - dns01:
        cloudflare:
          apiTokenSecretRef:
            name: cloudflare-api-token
            key: api-token
```

### Route53 DNS 챌린지

```yaml
# route53-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: route53-secret
  namespace: cert-manager
type: Opaque
stringData:
  secret-access-key: YOUR_AWS_SECRET_ACCESS_KEY
```

```yaml
# route53-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-route53
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-route53
    solvers:
    - dns01:
        route53:
          region: us-east-1
          accessKeyID: YOUR_AWS_ACCESS_KEY_ID
          secretAccessKeySecretRef:
            name: route53-secret
            key: secret-access-key
```

## 📊 고가용성 설정

### 다중 ClusterIssuer 설정

```yaml
# multi-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-primary
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-primary
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-backup
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-backup
    solvers:
    - http01:
        ingress:
          class: nginx
```

### Certificate 리소스로 고급 관리

```yaml
# advanced-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-cert
  namespace: default
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-primary
    kind: ClusterIssuer
  dnsNames:
  - example.com
  - www.example.com
  - api.example.com
  duration: 2160h  # 90일
  renewBefore: 360h # 만료 15일 전 갱신
  usages:
  - digital signature
  - key encipherment
  - server auth
```

## 🔍 모니터링 및 알림

### Prometheus 메트릭 설정

```yaml
# cert-manager-monitoring.yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: cert-manager
  namespace: cert-manager
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: cert-manager
  endpoints:
  - port: tcp-prometheus-servicemonitor
    interval: 30s
```

### 인증서 상태 모니터링

```bash
#!/bin/bash
# cert-monitor.sh

NAMESPACE="default"
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# 인증서 상태 확인
kubectl get certificates -n $NAMESPACE -o json | jq -r '.items[] | select(.status.conditions[].status == "False") | .metadata.name' | while read cert_name; do
    if [ ! -z "$cert_name" ]; then
        MESSAGE="⚠️ 인증서 오류: $cert_name 인증서에 문제가 있습니다!"
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$MESSAGE\"}" \
            $WEBHOOK_URL
    fi
done

# 만료 예정 인증서 확인
kubectl get certificates -n $NAMESPACE -o json | jq -r '.items[] | select(.status.notAfter != null) | "\(.metadata.name) \(.status.notAfter)"' | while read cert_name expiry_date; do
    EXPIRY_TIMESTAMP=$(date -d "$expiry_date" +%s)
    CURRENT_TIMESTAMP=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))
    
    if [ $DAYS_LEFT -lt 30 ]; then
        MESSAGE="⚠️ 인증서 만료 경고: $cert_name 인증서가 $DAYS_LEFT일 후 만료됩니다!"
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$MESSAGE\"}" \
            $WEBHOOK_URL
    fi
done
```

## 🛠️ 고급 설정

### 네임스페이스별 Issuer

```yaml
# namespace-issuer.yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt-namespace
  namespace: production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-namespace
    solvers:
    - http01:
        ingress:
          class: nginx
```

### 커스텀 인증서 템플릿

```yaml
# custom-certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: custom-cert
  namespace: default
spec:
  secretName: custom-cert-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
  commonName: example.com
  subject:
    organizations:
    - "My Company"
    organizationalUnits:
    - "IT Department"
    countries:
    - "KR"
    localities:
    - "Seoul"
    provinces:
    - "Seoul"
```

## 🔧 문제 해결

### 일반적인 문제들

#### 1. ClusterIssuer 상태 확인
```bash
kubectl describe clusterissuer letsencrypt-prod
kubectl get clusterissuer letsencrypt-prod -o yaml
```

#### 2. Certificate 상태 확인
```bash
kubectl describe certificate example-com-cert
kubectl get certificate example-com-cert -o yaml
```

#### 3. Challenge 상태 확인
```bash
kubectl get challenges
kubectl describe challenge <challenge-name>
```

#### 4. Order 상태 확인
```bash
kubectl get orders
kubectl describe order <order-name>
```

### 디버깅 명령어

```bash
# cert-manager 로그 확인
kubectl logs -n cert-manager deployment/cert-manager

# 인증서 이벤트 확인
kubectl get events --sort-by=.metadata.creationTimestamp

# Secret 확인
kubectl get secrets
kubectl describe secret example-com-tls
```

## 📚 다음 단계

Kubernetes cert-manager를 완료했다면 다음 단계로 진행하세요:

- **[클라우드 제공업체](./04-cloud-providers.md)** - 클라우드 네이티브 솔루션
- **[고급 주제](../advanced/README.md)** - 전문가 수준의 인증서 관리
- **[문제 해결](../troubleshooting/README.md)** - 운영 중 발생하는 문제들

## 💡 핵심 정리

- **자동화**: Kubernetes 리소스로 완전 자동화된 인증서 관리
- **고가용성**: 다중 ClusterIssuer와 백업 전략
- **모니터링**: Prometheus 메트릭과 알림 시스템
- **DNS 챌린지**: 와일드카드 인증서 발급 가능
- **네임스페이스**: 환경별 인증서 관리 전략

---

**다음: [클라우드 제공업체](./04-cloud-providers.md)**
