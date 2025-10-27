# 디버깅 가이드

## 🎯 이 장에서 배울 내용

이 장에서는 인증서 관련 문제를 체계적으로 진단하고 해결하는 방법을 학습합니다. OpenSSL 디버깅 도구부터 네트워크 분석까지, 문제 해결에 필요한 모든 도구와 기법을 다룹니다.

## 🔧 OpenSSL 디버깅 도구

### 기본 디버깅 명령어

#### 인증서 정보 확인
```bash
# 인증서 상세 정보 출력
openssl x509 -in certificate.crt -text -noout

# 인증서 요약 정보
openssl x509 -in certificate.crt -noout -subject -issuer -dates

# 인증서 지문 확인
openssl x509 -in certificate.crt -noout -fingerprint -sha256

# 인증서 공개키 정보
openssl x509 -in certificate.crt -noout -pubkey
```

#### 개인키 검증
```bash
# 개인키 형식 확인
openssl rsa -in private.key -text -noout

# 개인키와 인증서 매칭 확인
openssl x509 -noout -modulus -in certificate.crt | openssl md5
openssl rsa -noout -modulus -in private.key | openssl md5

# 개인키 암호화 확인
openssl rsa -in private.key -check -noout
```

### SSL 연결 테스트

#### 기본 연결 테스트
```bash
# SSL 서버 연결 테스트
openssl s_client -connect example.com:443

# 특정 SNI로 연결 테스트
openssl s_client -connect example.com:443 -servername example.com

# 연결 상태만 확인
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | grep -E "(Verify return code|subject|issuer)"
```

#### 고급 연결 테스트
```bash
# TLS 버전별 테스트
openssl s_client -connect example.com:443 -tls1_2
openssl s_client -connect example.com:443 -tls1_3

# 암호화 스위트 확인
openssl s_client -connect example.com:443 -cipher 'ECDHE-RSA-AES256-GCM-SHA384'

# 인증서 체인 확인
openssl s_client -connect example.com:443 -showcerts
```

## 🔍 네트워크 분석

### Wireshark를 사용한 패킷 분석

#### SSL/TLS 패킷 필터링
```
# SSL/TLS 패킷만 표시
ssl

# 특정 호스트의 SSL 패킷
ssl and host example.com

# SSL 핸드셰이크만 표시
ssl.handshake

# SSL 알림 메시지
ssl.record.content_type == 21
```

#### 핸드셰이크 분석
```
# Client Hello 분석
ssl.handshake.type == 1

# Server Hello 분석
ssl.handshake.type == 2

# Certificate 메시지 분석
ssl.handshake.type == 11

# Certificate Verify 분석
ssl.handshake.type == 15
```

### tcpdump를 사용한 실시간 분석

```bash
# SSL 패킷 캡처
sudo tcpdump -i any -s 0 -w ssl_capture.pcap port 443

# 특정 호스트의 SSL 패킷
sudo tcpdump -i any -s 0 -w ssl_capture.pcap host example.com and port 443

# SSL 핸드셰이크만 캡처
sudo tcpdump -i any -s 0 -w ssl_handshake.pcap 'tcp port 443 and tcp[tcpflags] & (tcp-syn|tcp-fin) != 0'
```

## 📊 로그 분석

### 웹서버 로그 분석

#### Nginx 로그 분석
```bash
# SSL 연결 오류 확인
grep "SSL" /var/log/nginx/error.log

# 인증서 관련 오류
grep -i "certificate" /var/log/nginx/error.log

# SSL 핸드셰이크 실패
grep "SSL_do_handshake" /var/log/nginx/error.log
```

#### Apache 로그 분석
```bash
# SSL 관련 오류 확인
grep -i "ssl" /var/log/apache2/error.log

# 인증서 검증 실패
grep -i "certificate verify failed" /var/log/apache2/error.log

# SSL 프로토콜 오류
grep -i "ssl protocol" /var/log/apache2/error.log
```

### 애플리케이션 로그 분석

#### Node.js 애플리케이션
```bash
# SSL 관련 오류 확인
grep -i "ssl\|tls\|certificate" /var/log/nodejs/app.log

# 연결 오류 확인
grep -i "connection\|handshake" /var/log/nodejs/app.log
```

#### Python 애플리케이션
```bash
# SSL 관련 오류 확인
grep -i "ssl\|certificate" /var/log/python/app.log

# 인증서 검증 오류
grep -i "certificate verify failed" /var/log/python/app.log
```

## 🛠️ 성능 문제 진단

### SSL/TLS 성능 분석

#### 연결 시간 측정
```bash
#!/bin/bash
# ssl-performance-test.sh

DOMAIN="example.com"
ITERATIONS=10

echo "SSL 연결 성능 테스트: $DOMAIN"
echo "=================================="

for i in $(seq 1 $ITERATIONS); do
    echo -n "테스트 $i: "
    
    # 연결 시간 측정
    time_output=$(time (echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN >/dev/null 2>&1) 2>&1)
    
    # 실제 시간 추출
    real_time=$(echo "$time_output" | grep real | awk '{print $2}')
    echo "$real_time"
done

echo "=================================="
echo "평균 연결 시간 계산 중..."
```

#### 암호화 스위트 성능 비교
```bash
#!/bin/bash
# cipher-performance-test.sh

DOMAIN="example.com"
CIPHERS=(
    "ECDHE-RSA-AES256-GCM-SHA384"
    "ECDHE-RSA-AES128-GCM-SHA256"
    "ECDHE-RSA-AES256-SHA384"
    "ECDHE-RSA-AES128-SHA256"
    "AES256-GCM-SHA384"
    "AES128-GCM-SHA256"
)

echo "암호화 스위트 성능 테스트: $DOMAIN"
echo "=================================="

for cipher in "${CIPHERS[@]}"; do
    echo -n "테스트 $cipher: "
    
    # 연결 시간 측정
    time_output=$(time (echo | openssl s_client -connect $DOMAIN:443 -cipher "$cipher" >/dev/null 2>&1) 2>&1)
    
    # 실제 시간 추출
    real_time=$(echo "$time_output" | grep real | awk '{print $2}')
    echo "$real_time"
done
```

### 메모리 사용량 분석

```bash
# SSL 프로세스 메모리 사용량 확인
ps aux | grep -E "(nginx|apache|node|python)" | grep -v grep

# SSL 연결별 메모리 사용량
ss -tuln | grep :443
netstat -an | grep :443 | wc -l

# SSL 세션 캐시 상태
openssl s_client -connect example.com:443 -sess_out session.pem
openssl sess_id -in session.pem -text
```

## 🔍 문제 진단 체크리스트

### 연결 문제 진단

#### 1. 네트워크 연결 확인
```bash
# 기본 연결 테스트
ping example.com
telnet example.com 443

# DNS 확인
nslookup example.com
dig example.com
```

#### 2. SSL 포트 확인
```bash
# 포트 상태 확인
nmap -p 443 example.com
nc -zv example.com 443

# 방화벽 확인
sudo iptables -L | grep 443
sudo ufw status | grep 443
```

#### 3. 인증서 체인 확인
```bash
# 인증서 체인 검증
openssl verify -CAfile ca-bundle.crt certificate.crt

# 중간 인증서 확인
openssl s_client -connect example.com:443 -showcerts

# 루트 CA 확인
openssl s_client -connect example.com:443 -CAfile ca-bundle.crt
```

### 인증서 문제 진단

#### 1. 인증서 유효성 확인
```bash
# 인증서 만료일 확인
openssl x509 -in certificate.crt -noout -dates

# 인증서 주체 확인
openssl x509 -in certificate.crt -noout -subject

# 인증서 발급자 확인
openssl x509 -in certificate.crt -noout -issuer
```

#### 2. 도메인 매칭 확인
```bash
# SAN 확인
openssl x509 -in certificate.crt -text -noout | grep -A 1 "Subject Alternative Name"

# 도메인 매칭 테스트
openssl s_client -connect example.com:443 -servername example.com
```

#### 3. 키 매칭 확인
```bash
# 공개키 매칭 확인
openssl x509 -noout -modulus -in certificate.crt | openssl md5
openssl rsa -noout -modulus -in private.key | openssl md5

# CSR과 인증서 매칭 확인
openssl req -noout -modulus -in certificate.csr | openssl md5
openssl x509 -noout -modulus -in certificate.crt | openssl md5
```

## 🚨 긴급 상황 대응

### 인증서 만료 긴급 대응

```bash
#!/bin/bash
# emergency-cert-renewal.sh

DOMAIN="example.com"
BACKUP_DIR="/backup/certificates/$(date +%Y%m%d_%H%M%S)"

echo "🚨 긴급 인증서 갱신 시작: $DOMAIN"

# 백업 생성
mkdir -p $BACKUP_DIR
cp /etc/ssl/certs/$DOMAIN* $BACKUP_DIR/
cp /etc/ssl/private/$DOMAIN* $BACKUP_DIR/

# 새 인증서 발급
certbot certonly --nginx -d $DOMAIN --force-renewal

# 웹서버 재시작
systemctl reload nginx

# 상태 확인
openssl s_client -connect $DOMAIN:443 -servername $DOMAIN

echo "✅ 긴급 갱신 완료"
```

### 서비스 중단 복구

```bash
#!/bin/bash
# service-recovery.sh

SERVICE="nginx"
CERT_PATH="/etc/ssl/certs"
KEY_PATH="/etc/ssl/private"

echo "🔧 서비스 복구 시작: $SERVICE"

# 서비스 상태 확인
systemctl status $SERVICE

# 설정 파일 검증
nginx -t

# 인증서 파일 권한 확인
ls -la $CERT_PATH/
ls -la $KEY_PATH/

# 서비스 재시작
systemctl restart $SERVICE

# 상태 확인
systemctl status $SERVICE
curl -I https://localhost

echo "✅ 서비스 복구 완료"
```

## 📚 다음 단계

디버깅 가이드를 완료했다면 다음 단계로 진행하세요:

- **[성능 튜닝](./03-performance-tuning.md)** - SSL/TLS 성능 최적화
- **[고급 주제](../advanced/README.md)** - 전문가 수준의 인증서 관리
- **[실제 시나리오](../scenarios/README.md)** - 복잡한 아키텍처 적용

## 💡 핵심 정리

- **체계적 접근**: 문제 정의 → 증상 수집 → 가설 설정 → 검증 → 해결
- **도구 활용**: OpenSSL, Wireshark, tcpdump 등 다양한 디버깅 도구
- **로그 분석**: 웹서버, 애플리케이션 로그를 통한 문제 원인 파악
- **성능 측정**: 연결 시간, 메모리 사용량 등 정량적 분석
- **긴급 대응**: 인증서 만료, 서비스 중단 등 위기 상황 대응

---

**다음: [성능 튜닝](./03-performance-tuning.md)**
