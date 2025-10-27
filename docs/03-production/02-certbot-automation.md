# certbot 자동화

## 🎯 이 장에서 배울 내용

이 장에서는 certbot을 사용한 고급 자동화 기법을 학습합니다. 웹서버별 통합부터 DNS 챌린지까지, 프로덕션 환경에서 필요한 모든 자동화 기술을 다룹니다.

## 🔧 웹서버별 자동 설정

### Nginx 통합

#### 자동 설정
```bash
# Nginx와 함께 자동 설정
sudo certbot --nginx -d example.com -d www.example.com

# 설정 파일 자동 수정 확인
sudo nginx -t
```

#### 수동 설정 후 인증서만 발급
```bash
# 기존 Nginx 설정 유지하면서 인증서만 발급
sudo certbot certonly --nginx -d example.com
```

### Apache 통합

#### 자동 설정
```bash
# Apache와 함께 자동 설정
sudo certbot --apache -d example.com -d www.example.com

# 설정 파일 자동 수정 확인
sudo apache2ctl configtest
```

#### 가상 호스트 설정
```apache
<VirtualHost *:443>
    ServerName example.com
    DocumentRoot /var/www/html
    
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/example.com/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/example.com/chain.pem
</VirtualHost>
```

## 🌐 DNS 챌린지 방식

### 와일드카드 인증서 발급

```bash
# DNS 챌린지로 와일드카드 인증서 발급
sudo certbot certonly --manual --preferred-challenges dns \
    -d *.example.com -d example.com
```

### 자동화된 DNS 챌린지

#### Cloudflare 플러그인 사용
```bash
# Cloudflare 플러그인 설치
sudo apt install python3-certbot-dns-cloudflare

# API 토큰 설정
sudo mkdir -p /etc/letsencrypt/cloudflare
sudo nano /etc/letsencrypt/cloudflare/cloudflare.ini
```

```ini
# cloudflare.ini
dns_cloudflare_api_token = YOUR_API_TOKEN
```

```bash
# 자동화된 와일드카드 인증서 발급
sudo certbot certonly --dns-cloudflare \
    --dns-cloudflare-credentials /etc/letsencrypt/cloudflare/cloudflare.ini \
    -d *.example.com -d example.com
```

## 🔄 자동 갱신 설정

### 기본 갱신 설정

```bash
# 갱신 테스트
sudo certbot renew --dry-run

# 실제 갱신 실행
sudo certbot renew
```

### 고급 갱신 설정

#### 웹서버 재시작 포함
```bash
# 갱신 후 웹서버 재시작
sudo certbot renew --post-hook "systemctl reload nginx"
sudo certbot renew --post-hook "systemctl reload apache2"
```

#### 여러 서비스 재시작
```bash
# 복합 명령어 실행
sudo certbot renew --post-hook "
    systemctl reload nginx &&
    systemctl restart docker-compose@myapp &&
    /opt/myapp/restart.sh
"
```

### Crontab 설정

```bash
# 매일 오전 2시에 갱신 확인
echo "0 2 * * * /usr/bin/certbot renew --quiet --post-hook 'systemctl reload nginx'" | sudo crontab -
```

## 📊 모니터링 및 알림

### 갱신 상태 모니터링

```bash
#!/bin/bash
# renew-check.sh

LOG_FILE="/var/log/certbot-renew.log"
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# 갱신 실행
certbot renew --quiet >> $LOG_FILE 2>&1

# 결과 확인
if [ $? -eq 0 ]; then
    echo "✅ 인증서 갱신 성공" >> $LOG_FILE
else
    echo "❌ 인증서 갱신 실패" >> $LOG_FILE
    # Slack 알림 전송
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"인증서 갱신 실패! 확인이 필요합니다."}' \
        $WEBHOOK_URL
fi
```

### 만료일 모니터링

```bash
#!/bin/bash
# cert-expiry-check.sh

DOMAIN="example.com"
DAYS_THRESHOLD=30
WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# 인증서 만료일 확인
EXPIRY_DATE=$(openssl x509 -in /etc/letsencrypt/live/$DOMAIN/cert.pem -noout -dates | grep notAfter | cut -d= -f2)
EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
CURRENT_TIMESTAMP=$(date +%s)
DAYS_LEFT=$(( ($EXPIRY_TIMESTAMP - $CURRENT_TIMESTAMP) / 86400 ))

if [ $DAYS_LEFT -lt $DAYS_THRESHOLD ]; then
    MESSAGE="⚠️ 인증서 만료 경고: $DOMAIN 인증서가 $DAYS_LEFT일 후 만료됩니다!"
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"$MESSAGE\"}" \
        $WEBHOOK_URL
fi
```

## 🔧 고급 설정

### 환경별 설정

#### 스테이징 환경
```bash
# 스테이징 환경에서 테스트
sudo certbot --staging --nginx -d staging.example.com
```

#### 프로덕션 환경
```bash
# 프로덕션 환경 적용
sudo certbot --nginx -d example.com -d www.example.com
```

### 다중 도메인 관리

```bash
# 여러 도메인을 한 번에 관리
sudo certbot --nginx \
    -d example.com -d www.example.com \
    -d api.example.com -d admin.example.com \
    -d *.example.com
```

### 인증서 통합

```bash
# 여러 인증서를 하나로 통합
sudo certbot --nginx \
    -d example.com -d www.example.com \
    -d api.example.com -d admin.example.com
```

## 🛡️ 보안 설정

### 인증서 권한 설정

```bash
# 인증서 파일 권한 설정
sudo chmod 600 /etc/letsencrypt/live/*/privkey.pem
sudo chmod 644 /etc/letsencrypt/live/*/cert.pem
sudo chmod 644 /etc/letsencrypt/live/*/chain.pem
sudo chmod 644 /etc/letsencrypt/live/*/fullchain.pem
```

### 백업 전략

```bash
#!/bin/bash
# cert-backup.sh

BACKUP_DIR="/backup/letsencrypt"
DATE=$(date +%Y%m%d_%H%M%S)

# 백업 디렉토리 생성
mkdir -p $BACKUP_DIR/$DATE

# 인증서 백업
cp -r /etc/letsencrypt $BACKUP_DIR/$DATE/

# 압축
tar -czf $BACKUP_DIR/letsencrypt_$DATE.tar.gz -C $BACKUP_DIR $DATE

# 오래된 백업 삭제 (30일 이상)
find $BACKUP_DIR -name "letsencrypt_*.tar.gz" -mtime +30 -delete
```

## 🔍 문제 해결

### 일반적인 문제들

#### 1. Rate Limit 초과
```bash
# 해결 방법: 스테이징 환경에서 테스트
sudo certbot --staging --nginx -d example.com
```

#### 2. DNS 챌린지 실패
```bash
# 해결 방법: DNS 설정 확인
nslookup _acme-challenge.example.com
dig TXT _acme-challenge.example.com
```

#### 3. 웹서버 설정 오류
```bash
# 해결 방법: 설정 파일 검증
sudo nginx -t
sudo apache2ctl configtest
```

## 📚 다음 단계

certbot 자동화를 완료했다면 다음 단계로 진행하세요:

- **[Kubernetes cert-manager](./03-kubernetes-cert-manager.md)** - 컨테이너 환경 관리
- **[클라우드 제공업체](./04-cloud-providers.md)** - 클라우드 네이티브 솔루션
- **[문제 해결](../troubleshooting/README.md)** - 운영 중 발생하는 문제들

## 💡 핵심 정리

- **자동화**: 웹서버 통합으로 원클릭 설정
- **DNS 챌린지**: 와일드카드 인증서 발급 가능
- **모니터링**: 갱신 상태 및 만료일 알림 필수
- **보안**: 적절한 권한 설정 및 백업 전략 수립
- **환경 분리**: 스테이징과 프로덕션 환경 구분

---

**다음: [Kubernetes cert-manager](./03-kubernetes-cert-manager.md)**
