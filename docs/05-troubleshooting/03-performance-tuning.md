# 성능 튜닝

## 🎯 이 장에서 배울 내용

이 장에서는 SSL/TLS 성능을 최적화하는 방법을 학습합니다. 인증서 크기 최적화부터 하드웨어 가속까지, 고성능 SSL/TLS 환경을 구축하는 모든 기법을 다룹니다.

## ⚡ SSL/TLS 성능 최적화

### TLS 버전 최적화

#### 최신 TLS 버전 사용
```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    
    # 최신 TLS 버전만 사용
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # 최적화된 암호화 스위트
    ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    
    # TLS 1.3 최적화
    ssl_early_data on;
}
```

#### Apache 설정
```apache
# httpd.conf
<VirtualHost *:443>
    # TLS 버전 설정
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    
    # 암호화 스위트 설정
    SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305
    SSLHonorCipherOrder off
    
    # TLS 1.3 최적화
    SSLEarlyData on
</VirtualHost>
```

### 세션 재사용 최적화

#### 세션 캐시 설정
```nginx
# nginx.conf
http {
    # SSL 세션 캐시 설정
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets on;
    
    # 세션 티켓 키 파일
    ssl_session_ticket_key /etc/nginx/ssl/session_ticket.key;
}
```

#### 세션 티켓 키 생성
```bash
# 세션 티켓 키 생성
openssl rand 80 > /etc/nginx/ssl/session_ticket.key

# 권한 설정
chmod 600 /etc/nginx/ssl/session_ticket.key
chown nginx:nginx /etc/nginx/ssl/session_ticket.key
```

### OCSP Stapling 설정

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    
    # OCSP Stapling 설정
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/ssl/certs/ca-bundle.crt;
    
    # DNS 리졸버 설정
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
}
```

## 🔧 인증서 크기 최적화

### 인증서 체인 최적화

#### 최적화된 인증서 체인 생성
```bash
#!/bin/bash
# optimize-cert-chain.sh

CERT_FILE="server.crt"
CHAIN_FILE="chain.crt"
FULLCHAIN_FILE="fullchain.crt"

echo "🔧 인증서 체인 최적화 시작..."

# 인증서 체인 순서 최적화
cat $CERT_FILE $CHAIN_FILE > $FULLCHAIN_FILE

# 불필요한 공백 제거
sed -i '/^$/d' $FULLCHAIN_FILE

# 인증서 크기 확인
echo "인증서 크기:"
ls -lh $CERT_FILE $CHAIN_FILE $FULLCHAIN_FILE

# 인증서 정보 확인
openssl x509 -in $CERT_FILE -text -noout | grep -E "(Subject|Issuer|Not Before|Not After)"
```

#### ECC 인증서 사용

```bash
# ECC 개인키 생성
openssl ecparam -genkey -name prime256v1 -out ecc-key.pem

# ECC CSR 생성
openssl req -new -key ecc-key.pem -out ecc.csr -subj "/C=KR/ST=Seoul/L=Seoul/O=Example/CN=example.com"

# ECC 인증서 서명
openssl x509 -req -in ecc.csr -CA ca-cert.pem -CAkey ca-key.pem -out ecc-cert.pem -days 365
```

### 인증서 압축

```bash
#!/bin/bash
# compress-certificates.sh

CERT_DIR="/etc/ssl/certs"
COMPRESSED_DIR="/etc/ssl/certs/compressed"

mkdir -p $COMPRESSED_DIR

# 인증서 압축
for cert in $CERT_DIR/*.crt; do
    if [ -f "$cert" ]; then
        filename=$(basename "$cert")
        gzip -c "$cert" > "$COMPRESSED_DIR/${filename}.gz"
        echo "압축 완료: $filename"
    fi
done

# 압축률 확인
echo "압축률:"
for cert in $CERT_DIR/*.crt; do
    if [ -f "$cert" ]; then
        filename=$(basename "$cert")
        original_size=$(stat -c%s "$cert")
        compressed_size=$(stat -c%s "$COMPRESSED_DIR/${filename}.gz")
        ratio=$((compressed_size * 100 / original_size))
        echo "$filename: ${ratio}% (${original_size} → ${compressed_size} bytes)"
    fi
done
```

## 🚀 연결 풀링 설정

### Nginx 연결 풀링

```nginx
# nginx.conf
http {
    # 업스트림 연결 풀 설정
    upstream backend {
        server backend1.example.com:443 weight=3 max_fails=2 fail_timeout=30s;
        server backend2.example.com:443 weight=2 max_fails=2 fail_timeout=30s;
        server backend3.example.com:443 weight=1 max_fails=2 fail_timeout=30s;
        
        # 연결 풀링 설정
        keepalive 32;
        keepalive_requests 100;
        keepalive_timeout 60s;
    }
    
    server {
        listen 443 ssl http2;
        
        # SSL 최적화
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;
        
        location / {
            proxy_pass https://backend;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            
            # SSL 연결 재사용
            proxy_ssl_session_reuse on;
            proxy_ssl_verify off;
        }
    }
}
```

### Apache 연결 풀링

```apache
# httpd.conf
<VirtualHost *:443>
    # SSL 최적화
    SSLSessionCache shmcb:/var/cache/mod_ssl/scache(512000)
    SSLSessionCacheTimeout 300
    
    # 프록시 설정
    ProxyPreserveHost On
    ProxyPass / https://backend.example.com/
    ProxyPassReverse / https://backend.example.com/
    
    # 연결 풀링
    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>

<Proxy balancer://mycluster>
    BalancerMember https://backend1.example.com:443
    BalancerMember https://backend2.example.com:443
    BalancerMember https://backend3.example.com:443
</Proxy>
```

## 💻 하드웨어 가속 활용

### OpenSSL 하드웨어 가속

#### AES-NI 지원 확인
```bash
# CPU AES-NI 지원 확인
grep -m1 -o aes /proc/cpuinfo

# OpenSSL AES-NI 지원 확인
openssl speed -evp aes-256-gcm

# 하드웨어 가속 테스트
openssl speed -evp aes-256-gcm -engine hw
```

#### OpenSSL 엔진 설정
```bash
# OpenSSL 설정 파일 수정
cat >> /etc/ssl/openssl.cnf << 'EOF'
[openssl_init]
engines = engine_section

[engine_section]
aesni = aesni_section

[aesni_section]
engine_id = aesni
dynamic_path = /usr/lib/x86_64-linux-gnu/engines-1.1/aesni.so
init = 1
EOF
```

### Nginx 하드웨어 가속

```nginx
# nginx.conf
http {
    # 하드웨어 가속 설정
    ssl_engine aesni;
    
    # SSL 최적화
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    
    # 세션 최적화
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets on;
}
```

## 📊 성능 모니터링

### SSL/TLS 성능 메트릭

#### 성능 측정 스크립트
```bash
#!/bin/bash
# ssl-performance-monitor.sh

DOMAIN="example.com"
LOG_FILE="/var/log/ssl-performance.log"

echo "$(date): SSL 성능 모니터링 시작" >> $LOG_FILE

# 연결 시간 측정
for i in {1..10}; do
    start_time=$(date +%s.%N)
    echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN >/dev/null 2>&1
    end_time=$(date +%s.%N)
    
    duration=$(echo "$end_time - $start_time" | bc)
    echo "$(date): 연결 시간 $i: ${duration}s" >> $LOG_FILE
done

# 평균 연결 시간 계산
avg_time=$(grep "연결 시간" $LOG_FILE | tail -10 | awk '{sum+=$NF} END {print sum/NR}')
echo "$(date): 평균 연결 시간: ${avg_time}s" >> $LOG_FILE

# 임계값 확인 (1초 이상이면 경고)
if (( $(echo "$avg_time > 1.0" | bc -l) )); then
    echo "$(date): ⚠️ 연결 시간이 임계값을 초과했습니다: ${avg_time}s" >> $LOG_FILE
fi
```

#### Prometheus 메트릭 수집
```yaml
# ssl-metrics-exporter.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ssl-metrics-exporter
data:
  ssl-exporter.py: |
    #!/usr/bin/env python3
    import time
    import subprocess
    import json
    from prometheus_client import start_http_server, Gauge, Counter
    
    # 메트릭 정의
    ssl_connection_time = Gauge('ssl_connection_time_seconds', 'SSL connection time in seconds')
    ssl_certificate_expiry = Gauge('ssl_certificate_expiry_days', 'SSL certificate expiry in days')
    ssl_handshake_failures = Counter('ssl_handshake_failures_total', 'Total SSL handshake failures')
    
    def measure_ssl_connection(host, port=443):
        try:
            start_time = time.time()
            result = subprocess.run([
                'openssl', 's_client', '-connect', f'{host}:{port}',
                '-servername', host, '-quiet'
            ], input=b'', capture_output=True, timeout=10)
            end_time = time.time()
            
            if result.returncode == 0:
                ssl_connection_time.set(end_time - start_time)
            else:
                ssl_handshake_failures.inc()
        except Exception as e:
            ssl_handshake_failures.inc()
    
    def check_certificate_expiry(host, port=443):
        try:
            result = subprocess.run([
                'openssl', 's_client', '-connect', f'{host}:{port}',
                '-servername', host, '-quiet'
            ], input=b'', capture_output=True, timeout=10)
            
            if result.returncode == 0:
                # 인증서 만료일 추출 (간단한 예시)
                # 실제로는 더 정교한 파싱이 필요
                pass
        except Exception as e:
            pass
    
    if __name__ == '__main__':
        start_http_server(8000)
        
        while True:
            measure_ssl_connection('example.com')
            check_certificate_expiry('example.com')
            time.sleep(30)
```

### 성능 대시보드

#### Grafana 대시보드 설정
```json
{
  "dashboard": {
    "title": "SSL/TLS Performance Dashboard",
    "panels": [
      {
        "title": "SSL Connection Time",
        "type": "graph",
        "targets": [
          {
            "expr": "ssl_connection_time_seconds",
            "legendFormat": "Connection Time"
          }
        ]
      },
      {
        "title": "Certificate Expiry",
        "type": "graph",
        "targets": [
          {
            "expr": "ssl_certificate_expiry_days",
            "legendFormat": "Days to Expiry"
          }
        ]
      },
      {
        "title": "Handshake Failures",
        "type": "stat",
        "targets": [
          {
            "expr": "rate(ssl_handshake_failures_total[5m])",
            "legendFormat": "Failures/sec"
          }
        ]
      }
    ]
  }
}
```

## 🔧 고급 최적화 기법

### HTTP/2 최적화

```nginx
# nginx.conf
http {
    # HTTP/2 설정
    http2_max_field_size 16k;
    http2_max_header_size 32k;
    http2_max_requests 1000;
    
    server {
        listen 443 ssl http2;
        
        # HTTP/2 푸시 설정
        location / {
            http2_push /style.css;
            http2_push /script.js;
        }
    }
}
```

### CDN 통합

```bash
#!/bin/bash
# cdn-ssl-setup.sh

DOMAIN="example.com"
CDN_PROVIDER="cloudflare"

echo "🌐 CDN SSL 설정 시작: $DOMAIN"

case $CDN_PROVIDER in
    "cloudflare")
        # Cloudflare SSL 설정
        curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/ssl" \
            -H "Authorization: Bearer $API_TOKEN" \
            -H "Content-Type: application/json" \
            --data '{"value":"full"}'
        ;;
    "aws")
        # AWS CloudFront SSL 설정
        aws cloudfront create-distribution \
            --distribution-config file://cloudfront-config.json
        ;;
esac

echo "✅ CDN SSL 설정 완료"
```

## 📚 다음 단계

성능 튜닝을 완료했다면 다음 단계로 진행하세요:

- **[고급 주제](../advanced/README.md)** - 전문가 수준의 인증서 관리
- **[실제 시나리오](../scenarios/README.md)** - 복잡한 아키텍처 적용
- **[문제 해결](../troubleshooting/README.md)** - 운영 중 발생하는 문제들

## 💡 핵심 정리

- **TLS 최적화**: 최신 TLS 버전과 암호화 스위트 사용
- **세션 재사용**: 세션 캐시와 티켓을 통한 성능 향상
- **인증서 최적화**: ECC 인증서와 체인 최적화
- **하드웨어 가속**: AES-NI와 OpenSSL 엔진 활용
- **모니터링**: 지속적인 성능 측정과 최적화

---

**다음: [고급 주제](../advanced/README.md)**
