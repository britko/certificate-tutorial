# Kubernetes 예제

이 폴더에는 Kubernetes 환경에서 인증서를 관리하는 실습 예제들이 포함되어 있습니다.

## 📁 파일 구조

```
kubernetes/
├── cert-manager/
│   ├── cluster-issuer.yaml         # ClusterIssuer 설정
│   ├── certificate.yaml            # Certificate 리소스
│   ├── ingress.yaml                # Ingress TLS 설정
│   └── namespace.yaml              # 네임스페이스 설정
├── istio/
│   ├── gateway.yaml                # Istio Gateway 설정
│   ├── virtual-service.yaml        # VirtualService 설정
│   ├── destination-rule.yaml       # DestinationRule 설정
│   └── peer-authentication.yaml   # PeerAuthentication 설정
├── monitoring/
│   ├── prometheus-config.yaml      # Prometheus 설정
│   ├── grafana-dashboard.yaml      # Grafana 대시보드
│   └── alertmanager.yaml           # AlertManager 설정
├── applications/
│   ├── nginx/
│   │   ├── deployment.yaml         # Nginx 배포
│   │   ├── service.yaml            # Nginx 서비스
│   │   └── configmap.yaml          # Nginx 설정
│   ├── api-gateway/
│   │   ├── deployment.yaml         # API Gateway 배포
│   │   ├── service.yaml            # API Gateway 서비스
│   │   └── ingress.yaml            # API Gateway Ingress
│   └── microservices/
│       ├── user-service.yaml       # 사용자 서비스
│       ├── payment-service.yaml    # 결제 서비스
│       └── notification-service.yaml # 알림 서비스
└── scripts/
    ├── setup.sh                    # 환경 설정 스크립트
    ├── deploy.sh                    # 배포 스크립트
    └── cleanup.sh                   # 정리 스크립트
```

## 🚀 빠른 시작

### 1. 환경 설정
```bash
# Kubernetes 클러스터 확인
kubectl cluster-info

# cert-manager 설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Istio 설치 (선택사항)
istioctl install --set values.pilot.env.EXTERNAL_ISTIOD=false
```

### 2. 기본 인증서 설정
```bash
# ClusterIssuer 생성
kubectl apply -f cert-manager/cluster-issuer.yaml

# 네임스페이스 생성
kubectl apply -f cert-manager/namespace.yaml

# 인증서 발급
kubectl apply -f cert-manager/certificate.yaml
```

### 3. 애플리케이션 배포
```bash
# Nginx 배포
kubectl apply -f applications/nginx/

# API Gateway 배포
kubectl apply -f applications/api-gateway/

# 마이크로서비스 배포
kubectl apply -f applications/microservices/
```

## 🔐 cert-manager 설정

### ClusterIssuer 설정
```yaml
# cert-manager/cluster-issuer.yaml
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

### Certificate 리소스
```yaml
# cert-manager/certificate.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-cert
  namespace: production
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
  - www.example.com
  - api.example.com
```

## 🌐 Istio Service Mesh

### Gateway 설정
```yaml
# istio/gateway.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: example-gateway
  namespace: production
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: example-com-tls
    hosts:
    - example.com
    - www.example.com
    - api.example.com
```

### VirtualService 설정
```yaml
# istio/virtual-service.yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: example-vs
  namespace: production
spec:
  hosts:
  - example.com
  - www.example.com
  - api.example.com
  gateways:
  - example-gateway
  http:
  - match:
    - uri:
        prefix: /api/
    route:
    - destination:
        host: api-gateway-service
        port:
          number: 80
  - route:
    - destination:
        host: nginx-service
        port:
          number: 80
```

## 📊 모니터링 설정

### Prometheus 설정
```yaml
# monitoring/prometheus-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'kubernetes-pods'
      kubernetes_sd_configs:
      - role: pod
    - job_name: 'cert-manager'
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        action: keep
        regex: cert-manager
```

### Grafana 대시보드
```yaml
# monitoring/grafana-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-certificates
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  certificate-dashboard.json: |
    {
      "dashboard": {
        "title": "Certificate Monitoring",
        "panels": [
          {
            "title": "Certificate Status",
            "type": "stat",
            "targets": [
              {
                "expr": "certmanager_certificate_ready_status",
                "legendFormat": "Ready"
              }
            ]
          }
        ]
      }
    }
```

## 🔧 고급 설정

### 다중 환경 관리
```bash
# 환경별 네임스페이스 생성
kubectl create namespace staging
kubectl create namespace production

# 환경별 ClusterIssuer 설정
kubectl apply -f cert-manager/cluster-issuer-staging.yaml
kubectl apply -f cert-manager/cluster-issuer-prod.yaml

# 환경별 인증서 발급
kubectl apply -f cert-manager/certificate-staging.yaml -n staging
kubectl apply -f cert-manager/certificate-prod.yaml -n production
```

### 자동 갱신 설정
```yaml
# cert-manager/auto-renewal.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: auto-renewal-cert
  namespace: production
spec:
  secretName: auto-renewal-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
  duration: 2160h  # 90일
  renewBefore: 360h # 만료 15일 전 갱신
```

## 🧪 테스트 시나리오

### 1. 기본 기능 테스트
```bash
# 인증서 상태 확인
kubectl get certificates -n production

# 인증서 상세 정보 확인
kubectl describe certificate example-com-cert -n production

# Secret 확인
kubectl get secrets -n production
kubectl describe secret example-com-tls -n production
```

### 2. TLS 연결 테스트
```bash
# 포트 포워딩으로 로컬 테스트
kubectl port-forward service/nginx-service 8443:443 -n production

# TLS 연결 테스트
openssl s_client -connect localhost:8443 -servername example.com
```

### 3. 부하 테스트
```bash
# Apache Bench를 사용한 부하 테스트
kubectl run ab-test --image=httpd:alpine --rm -it -- ab -n 1000 -c 10 https://example.com/
```

## 🔍 문제 해결

### 일반적인 문제들
1. **인증서 발급 실패**
   - 해결: ClusterIssuer 상태 확인, DNS 설정 검토

2. **TLS 연결 실패**
   - 해결: Secret 존재 확인, Ingress 설정 검토

3. **Istio Gateway 오류**
   - 해결: Gateway 설정 확인, VirtualService 매칭 검토

## 📚 추가 학습

- [Kubernetes cert-manager](../../docs/03-production/03-kubernetes-cert-manager.md)
- [마이크로서비스 보안](../../docs/04-scenarios/02-microservices.md)
- [문제 해결 가이드](../../docs/05-troubleshooting/README.md)

## 💡 핵심 정리

- **cert-manager**: Kubernetes 네이티브 인증서 관리
- **Istio**: 서비스 메시를 통한 고급 보안 정책
- **모니터링**: Prometheus와 Grafana를 통한 실시간 모니터링
- **자동화**: 자동 갱신과 환경별 관리
- **테스트**: 체계적인 테스트 시나리오

---

**💡 팁**: 각 예제를 실행하기 전에 해당 폴더의 README.md를 확인하세요!
