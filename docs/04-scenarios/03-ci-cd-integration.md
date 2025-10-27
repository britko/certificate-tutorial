# CI/CD 통합

## 🎯 이 장에서 배울 내용

이 장에서는 자동화된 보안 배포 파이프라인을 구축하는 방법을 학습합니다. 인증서 자동 배포부터 보안 검증까지, DevOps 환경에서 필요한 모든 자동화 기술을 다룹니다.

## 🚀 GitHub Actions 워크플로우

### 기본 인증서 배포 파이프라인

```yaml
# .github/workflows/certificate-deployment.yml
name: Certificate Deployment Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # 매일 오전 2시에 갱신 확인

jobs:
  security-setup:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup CA and Certificates
      run: |
        echo "🔐 CI/CD 환경 보안 설정 시작..."
        
        # CA 디렉토리 생성
        mkdir -p ca/{certs,private,crl,newcerts}
        mkdir -p certs
        
        # Root CA 생성
        openssl genrsa -out ca/private/ci-ca.key 4096
        openssl req -new -x509 -days 3650 -key ca/private/ci-ca.key \
            -out ca/certs/ci-ca.crt \
            -subj "/C=KR/ST=Seoul/L=Seoul/O=CI/OU=DevOps/CN=CI Root CA"
        
        # CA 설정 파일 생성
        cat > ca/ca.conf << 'EOF'
        [ ca ]
        default_ca = CA_default
        
        [ CA_default ]
        dir = ./ca
        certs = $dir/certs
        crl_dir = $dir/crl
        new_certs_dir = $dir/newcerts
        database = $dir/index.txt
        serial = $dir/serial
        RANDFILE = $dir/.rand
        
        private_key = $dir/private/ci-ca.key
        certificate = $dir/certs/ci-ca.crt
        
        default_md = sha256
        default_days = 365
        policy = policy_strict
        
        [ policy_strict ]
        countryName = match
        stateOrProvinceName = match
        organizationName = match
        commonName = supplied
        
        [ server_cert ]
        basicConstraints = CA:FALSE
        nsCertType = server
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid,issuer:always
        keyUsage = critical, digitalSignature, keyEncipherment
        extendedKeyUsage = serverAuth
        EOF
        
        # CA 데이터베이스 초기화
        touch ca/index.txt
        echo 1000 > ca/serial
        
        echo "✅ CI/CD 보안 설정 완료"
    
    - name: Upload Certificates
      uses: actions/upload-artifact@v3
      with:
        name: ssl-certificates
        path: |
          ca/
          certs/

  test-services:
    runs-on: ubuntu-latest
    needs: security-setup
    steps:
    - uses: actions/checkout@v3
    
    - name: Download Certificates
      uses: actions/download-artifact@v3
      with:
        name: ssl-certificates
        path: ./
    
    - name: Setup Test Environment
      run: |
        # CA 인증서를 시스템에 추가
        sudo cp ca/certs/ci-ca.crt /usr/local/share/ca-certificates/
        sudo update-ca-certificates
        
        # Docker Compose로 테스트 환경 시작
        docker-compose up -d
    
    - name: Run Security Tests
      run: |
        # SSL/TLS 보안 테스트
        echo "🔍 SSL/TLS 보안 검증 시작..."
        
        # 인증서 유효성 검증
        openssl verify -CAfile ca/certs/ci-ca.crt certs/api-gateway-cert.pem
        
        # TLS 연결 테스트
        echo | openssl s_client -connect localhost:443 -servername api-dev.example.com
        
        echo "✅ 보안 테스트 완료"
    
    - name: Cleanup
      if: always()
      run: |
        docker-compose down
        docker system prune -f

  deploy-staging:
    runs-on: ubuntu-latest
    needs: test-services
    if: github.ref == 'refs/heads/develop'
    environment: staging
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Staging
      run: |
        echo "🚀 스테이징 환경 배포 시작..."
        
        # 스테이징 환경에 인증서 배포
        kubectl apply -f k8s/staging/
        
        # 배포 상태 확인
        kubectl rollout status deployment/api-gateway -n staging
        kubectl rollout status deployment/user-service -n staging
        
        echo "✅ 스테이징 배포 완료"

  deploy-production:
    runs-on: ubuntu-latest
    needs: test-services
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to Production
      run: |
        echo "🚀 프로덕션 환경 배포 시작..."
        
        # 프로덕션 환경에 인증서 배포
        kubectl apply -f k8s/production/
        
        # 배포 상태 확인
        kubectl rollout status deployment/api-gateway -n production
        kubectl rollout status deployment/user-service -n production
        
        echo "✅ 프로덕션 배포 완료"
```

## 🔐 환경별 인증서 관리

### 환경별 설정 파일

```yaml
# k8s/staging/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
---
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
# k8s/production/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
---
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

### 환경별 인증서 템플릿

```yaml
# k8s/templates/certificate-template.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ .Values.certificateName }}
  namespace: {{ .Values.namespace }}
spec:
  secretName: {{ .Values.certificateName }}-tls
  issuerRef:
    name: {{ .Values.issuerName }}
    kind: ClusterIssuer
  dnsNames:
  {{- range .Values.domains }}
  - {{ . }}
  {{- end }}
  duration: {{ .Values.duration | default "2160h" }}
  renewBefore: {{ .Values.renewBefore | default "360h" }}
```

## 🔍 보안 검증 파이프라인

### 정적 보안 분석

```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
    
    - name: Run OWASP ZAP Baseline Scan
      uses: zaproxy/action-baseline@v0.7.0
      with:
        target: 'https://staging.example.com'
        rules_file_name: '.zap/rules.tsv'
        cmd_options: '-a'
```

### 동적 보안 테스트

```yaml
# .github/workflows/dynamic-security-test.yml
name: Dynamic Security Test

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 3 * * *'  # 매일 오전 3시에 실행

jobs:
  dynamic-security-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run OWASP ZAP Full Scan
      uses: zaproxy/action-full-scan@v0.4.0
      with:
        target: 'https://staging.example.com'
        rules_file_name: '.zap/rules.tsv'
        cmd_options: '-a -j'
    
    - name: SSL Labs API Test
      run: |
        # SSL Labs API를 사용한 SSL 설정 분석
        curl -X POST "https://api.ssllabs.com/api/v3/analyze" \
          -d "host=staging.example.com&publish=off&startNew=on" \
          -o ssl-analysis.json
        
        # 결과 확인
        cat ssl-analysis.json | jq '.status'
```

## 🔄 롤백 및 복구 전략

### 자동 롤백 설정

```yaml
# k8s/rollback-strategy.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: api-gateway-rollout
  namespace: production
spec:
  replicas: 3
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 10m}
      - setWeight: 40
      - pause: {duration: 10m}
      - setWeight: 60
      - pause: {duration: 10m}
      - setWeight: 80
      - pause: {duration: 10m}
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: api-gateway-service
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: nginx:alpine
        ports:
        - containerPort: 443
        volumeMounts:
        - name: ssl-certs
          mountPath: /etc/ssl/certs
          readOnly: true
      volumes:
      - name: ssl-certs
        secret:
          secretName: api-gateway-tls
```

### 복구 스크립트

```bash
#!/bin/bash
# rollback.sh

NAMESPACE=${1:-production}
DEPLOYMENT=${2:-api-gateway}
REVISION=${3:-1}

echo "🔄 롤백 시작: $DEPLOYMENT in $NAMESPACE to revision $REVISION"

# 현재 배포 상태 확인
kubectl rollout history deployment/$DEPLOYMENT -n $NAMESPACE

# 롤백 실행
kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE --to-revision=$REVISION

# 롤백 상태 확인
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

# 헬스체크
kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT

echo "✅ 롤백 완료"
```

## 📊 배포 모니터링

### 배포 상태 모니터링

```yaml
# monitoring/deployment-monitor.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: deployment-monitor-config
data:
  monitor.sh: |
    #!/bin/bash
    
    NAMESPACE="production"
    WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
    
    # 배포 상태 확인
    kubectl get deployments -n $NAMESPACE -o json | jq -r '.items[] | select(.status.readyReplicas != .spec.replicas) | .metadata.name' | while read deployment; do
        if [ ! -z "$deployment" ]; then
            MESSAGE="⚠️ 배포 문제: $deployment 배포에 문제가 있습니다!"
            curl -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$MESSAGE\"}" \
                $WEBHOOK_URL
        fi
    done
    
    # 인증서 상태 확인
    kubectl get certificates -n $NAMESPACE -o json | jq -r '.items[] | select(.status.conditions[].status == "False") | .metadata.name' | while read cert; do
        if [ ! -z "$cert" ]; then
            MESSAGE="⚠️ 인증서 문제: $cert 인증서에 문제가 있습니다!"
            curl -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$MESSAGE\"}" \
                $WEBHOOK_URL
        fi
    done
```

### 성능 모니터링

```yaml
# monitoring/performance-monitor.yaml
apiVersion: v1
kind: ServiceMonitor
metadata:
  name: performance-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: api-gateway
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

## 🔧 문제 해결

### 일반적인 문제들

#### 1. 배포 실패
```bash
# 배포 상태 확인
kubectl get deployments -n production
kubectl describe deployment api-gateway -n production

# 이벤트 확인
kubectl get events -n production --sort-by=.metadata.creationTimestamp
```

#### 2. 인증서 배포 실패
```bash
# 인증서 상태 확인
kubectl get certificates -n production
kubectl describe certificate api-gateway-cert -n production

# Secret 확인
kubectl get secrets -n production
kubectl describe secret api-gateway-tls -n production
```

#### 3. 롤백 실패
```bash
# 롤백 히스토리 확인
kubectl rollout history deployment/api-gateway -n production

# 수동 롤백
kubectl rollout undo deployment/api-gateway -n production
```

## 📚 다음 단계

CI/CD 통합을 완료했다면 다음 단계로 진행하세요:

- **[고급 주제](../advanced/README.md)** - 전문가 수준의 인증서 관리
- **[문제 해결](../troubleshooting/README.md)** - 운영 중 발생하는 문제들
- **[실제 시나리오](../scenarios/README.md)** - 복잡한 아키텍처 적용

## 💡 핵심 정리

- **자동화**: GitHub Actions를 통한 완전 자동화된 배포
- **환경 분리**: 스테이징과 프로덕션 환경별 인증서 관리
- **보안 검증**: 정적/동적 보안 분석 통합
- **롤백 전략**: 자동 롤백 및 복구 메커니즘
- **모니터링**: 실시간 배포 상태 및 성능 모니터링

---

**다음: [고급 주제](../advanced/README.md)**
