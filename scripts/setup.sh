#!/bin/bash

# 사설 인증서 튜토리얼 설정 스크립트
# 이 스크립트는 튜토리얼 환경을 자동으로 설정합니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 시스템 정보 확인
check_system() {
    log_info "시스템 정보 확인 중..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        log_success "Linux 시스템 감지됨"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_success "macOS 시스템 감지됨"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        log_success "Windows 시스템 감지됨"
    else
        log_error "지원되지 않는 운영체제: $OSTYPE"
        exit 1
    fi
}

# 필수 도구 설치 확인
check_dependencies() {
    log_info "필수 도구 확인 중..."
    
    local missing_tools=()
    
    # OpenSSL 확인
    if ! command -v openssl &> /dev/null; then
        missing_tools+=("openssl")
    else
        log_success "OpenSSL 설치됨: $(openssl version)"
    fi
    
    # Git 확인
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    else
        log_success "Git 설치됨: $(git --version)"
    fi
    
    # mkcert 확인
    if ! command -v mkcert &> /dev/null; then
        missing_tools+=("mkcert")
    else
        log_success "mkcert 설치됨: $(mkcert -version)"
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_warning "누락된 도구들: ${missing_tools[*]}"
        install_dependencies "${missing_tools[@]}"
    fi
}

# 누락된 도구 설치
install_dependencies() {
    local tools=("$@")
    
    log_info "누락된 도구 설치 중..."
    
    for tool in "${tools[@]}"; do
        case $tool in
            "openssl")
                install_openssl
                ;;
            "git")
                install_git
                ;;
            "mkcert")
                install_mkcert
                ;;
        esac
    done
}

# OpenSSL 설치
install_openssl() {
    log_info "OpenSSL 설치 중..."
    
    case $OS in
        "linux")
            if command -v apt-get &> /dev/null; then
                sudo apt-get update
                sudo apt-get install -y openssl
            elif command -v yum &> /dev/null; then
                sudo yum install -y openssl
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y openssl
            else
                log_error "패키지 매니저를 찾을 수 없습니다."
                exit 1
            fi
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install openssl
            else
                log_error "Homebrew가 설치되지 않았습니다."
                exit 1
            fi
            ;;
        "windows")
            log_warning "Windows에서는 수동으로 OpenSSL을 설치해주세요."
            log_info "다운로드: https://slproweb.com/products/Win32OpenSSL.html"
            ;;
    esac
}

# Git 설치
install_git() {
    log_info "Git 설치 중..."
    
    case $OS in
        "linux")
            if command -v apt-get &> /dev/null; then
                sudo apt-get install -y git
            elif command -v yum &> /dev/null; then
                sudo yum install -y git
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y git
            fi
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install git
            else
                log_error "Homebrew가 설치되지 않았습니다."
                exit 1
            fi
            ;;
        "windows")
            log_warning "Windows에서는 수동으로 Git을 설치해주세요."
            log_info "다운로드: https://git-scm.com/download/win"
            ;;
    esac
}

# mkcert 설치
install_mkcert() {
    log_info "mkcert 설치 중..."
    
    case $OS in
        "linux")
            # NSS 도구 설치
            if command -v apt-get &> /dev/null; then
                sudo apt-get install -y libnss3-tools
            elif command -v yum &> /dev/null; then
                sudo yum install -y nss-tools
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y nss-tools
            fi
            
            # mkcert 다운로드
            wget -O mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64
            chmod +x mkcert
            sudo mv mkcert /usr/local/bin/
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install mkcert
            else
                log_error "Homebrew가 설치되지 않았습니다."
                exit 1
            fi
            ;;
        "windows")
            log_warning "Windows에서는 수동으로 mkcert를 설치해주세요."
            log_info "다운로드: https://github.com/FiloSottile/mkcert/releases"
            ;;
    esac
}

# 프로젝트 디렉토리 구조 생성
create_project_structure() {
    log_info "프로젝트 디렉토리 구조 생성 중..."
    
    # 기본 디렉토리 생성
    mkdir -p certs/{ca,server,client}
    mkdir -p config
    mkdir -p scripts
    mkdir -p examples/{nodejs,python,nginx,apache}
    mkdir -p monitoring
    
    # 설정 파일 생성
    create_config_files
    
    log_success "프로젝트 디렉토리 구조 생성 완료"
}

# 설정 파일 생성
create_config_files() {
    log_info "설정 파일 생성 중..."
    
    # OpenSSL CA 설정 파일
    cat > config/ca.conf << 'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir = ./certs/ca
certs = $dir
crl_dir = $dir/crl
new_certs_dir = $dir/newcerts
database = $dir/index.txt
serial = $dir/serial
RANDFILE = $dir/.rand

private_key = $dir/ca-key.pem
certificate = $dir/ca-cert.pem

crlnumber = $dir/crlnumber
crl = $dir/crl.pem
crl_extensions = crl_ext
default_crl_days = 30

default_md = sha256
name_opt = ca_default
cert_opt = ca_default
default_days = 365
preserve = no
policy = policy_strict

[ policy_strict ]
countryName = match
stateOrProvinceName = match
organizationName = match
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[ policy_loose ]
countryName = optional
stateOrProvinceName = optional
localityName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional

[ req ]
default_bits = 4096
distinguished_name = req_distinguished_name
string_mask = utf8only
default_md = sha256
x509_extensions = v3_ca

[ req_distinguished_name ]
countryName = Country Name (2 letter code)
stateOrProvinceName = State or Province Name
localityName = Locality Name
0.organizationName = Organization Name
organizationalUnitName = Organizational Unit Name
commonName = Common Name
emailAddress = Email Address

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
authorityKeyIdentifier = keyid:always
EOF

    # 환경 설정 파일
    cat > .env << 'EOF'
# 사설 인증서 튜토리얼 환경 설정

# 기본 설정
CERT_DIR="./certs"
CONFIG_DIR="./config"
SCRIPTS_DIR="./scripts"

# CA 설정
CA_COUNTRY="KR"
CA_STATE="Seoul"
CA_CITY="Seoul"
CA_ORGANIZATION="MyCompany"
CA_OU="IT Department"

# 인증서 설정
CERT_VALIDITY_DAYS=365
KEY_SIZE=4096

# 알림 설정
NOTIFICATION_EMAIL="admin@example.com"
SLACK_WEBHOOK=""

# 모니터링 설정
MONITORING_ENABLED=true
LOG_LEVEL="INFO"
EOF

    log_success "설정 파일 생성 완료"
}

# mkcert 초기화
setup_mkcert() {
    log_info "mkcert 초기화 중..."
    
    # mkcert CA 설치
    mkcert -install
    
    log_success "mkcert CA 설치 완료"
}

# 예제 인증서 생성
create_example_certificates() {
    log_info "예제 인증서 생성 중..."
    
    # localhost 인증서 생성
    mkcert localhost 127.0.0.1 ::1
    
    # API 서버용 인증서 생성
    mkcert api.localhost 127.0.0.1 ::1
    
    # 관리자용 인증서 생성
    mkcert admin.localhost 127.0.0.1 ::1
    
    log_success "예제 인증서 생성 완료"
}

# 예제 애플리케이션 생성
create_example_applications() {
    log_info "예제 애플리케이션 생성 중..."
    
    # Node.js 예제
    create_nodejs_example
    
    # Python 예제
    create_python_example
    
    # Nginx 예제
    create_nginx_example
    
    # Apache 예제
    create_apache_example
    
    log_success "예제 애플리케이션 생성 완료"
}

# Node.js 예제 생성
create_nodejs_example() {
    cat > examples/nodejs/package.json << 'EOF'
{
  "name": "https-example",
  "version": "1.0.0",
  "description": "HTTPS 예제 애플리케이션",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

    cat > examples/nodejs/server.js << 'EOF'
const express = require('express');
const https = require('https');
const fs = require('fs');
const path = require('path');

const app = express();

// 미들웨어 설정
app.use(express.json());
app.use(express.static('public'));

// 보안 헤더 미들웨어
app.use((req, res, next) => {
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    next();
});

// 라우트 설정
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>HTTPS 예제</title>
            <meta charset="utf-8">
        </head>
        <body>
            <h1>🔒 HTTPS 연결 성공!</h1>
            <p>현재 프로토콜: ${req.protocol}</p>
            <p>보안 연결이 활성화되었습니다.</p>
        </body>
        </html>
    `);
});

app.get('/api/status', (req, res) => {
    res.json({
        status: 'success',
        protocol: req.protocol,
        secure: req.secure,
        timestamp: new Date().toISOString()
    });
});

// HTTPS 서버 설정
const options = {
    key: fs.readFileSync('../../localhost-key.pem'),
    cert: fs.readFileSync('../../localhost.pem')
};

const PORT = process.env.PORT || 443;
https.createServer(options, app).listen(PORT, () => {
    console.log(`🚀 HTTPS 서버가 https://localhost:${PORT}에서 실행 중입니다.`);
});
EOF
}

# Python 예제 생성
create_python_example() {
    cat > examples/python/requirements.txt << 'EOF'
Flask==2.3.3
Werkzeug==2.3.7
EOF

    cat > examples/python/app.py << 'EOF'
from flask import Flask, render_template, jsonify, request
import ssl
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/status')
def api_status():
    return jsonify({
        'status': 'success',
        'protocol': request.scheme,
        'secure': request.is_secure,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/headers')
def api_headers():
    return jsonify(dict(request.headers))

if __name__ == '__main__':
    # SSL 컨텍스트 설정
    context = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
    context.load_cert_chain('../../localhost.pem', '../../localhost-key.pem')
    
    # HTTPS 서버 시작
    app.run(
        host='0.0.0.0',
        port=443,
        ssl_context=context,
        debug=True
    )
EOF

    mkdir -p examples/python/templates
    cat > examples/python/templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HTTPS Flask App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { padding: 20px; background: #f0f0f0; border-radius: 5px; }
        .secure { color: green; }
        .insecure { color: red; }
    </style>
</head>
<body>
    <h1>🔒 Flask HTTPS 애플리케이션</h1>
    <div class="status">
        <p>프로토콜: <span id="protocol"></span></p>
        <p>보안 상태: <span id="security"></span></p>
        <p>타임스탬프: <span id="timestamp"></span></p>
    </div>
    
    <button onclick="checkStatus()">상태 확인</button>
    
    <script>
        async function checkStatus() {
            try {
                const response = await fetch('/api/status');
                const data = await response.json();
                
                document.getElementById('protocol').textContent = data.protocol;
                document.getElementById('security').textContent = data.secure ? '보안' : '비보안';
                document.getElementById('timestamp').textContent = data.timestamp;
            } catch (error) {
                console.error('상태 확인 실패:', error);
            }
        }
        
        // 페이지 로드 시 상태 확인
        checkStatus();
    </script>
</body>
</html>
EOF
}

# Nginx 예제 생성
create_nginx_example() {
    cat > examples/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    # SSL 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HTTP to HTTPS 리다이렉트
    server {
        listen 80;
        server_name localhost;
        return 301 https://$server_name$request_uri;
    }
    
    # HTTPS 서버
    server {
        listen 443 ssl http2;
        server_name localhost;
        
        # SSL 인증서 설정
        ssl_certificate /etc/nginx/ssl/localhost.pem;
        ssl_certificate_key /etc/nginx/ssl/localhost-key.pem;
        
        # 보안 헤더
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode= block";
        
        # 정적 파일 서빙
        root /var/www/html;
        index index.html index.htm;
        
        location / {
            try_files $uri $uri/ =404;
        }
        
        # API 프록시
        location /api/ {
            proxy_pass http://localhost:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF
}

# Apache 예제 생성
create_apache_example() {
    cat > examples/apache/httpd.conf << 'EOF'
# Apache HTTPS 설정 예제

# SSL 모듈 활성화
LoadModule ssl_module modules/mod_ssl.so

# HTTP to HTTPS 리다이렉트
<VirtualHost *:80>
    ServerName localhost
    Redirect permanent / https://localhost/
</VirtualHost>

# HTTPS 가상 호스트
<VirtualHost *:443>
    ServerName localhost
    DocumentRoot /var/www/html
    
    # SSL 설정
    SSLEngine on
    SSLCertificateFile /etc/apache2/ssl/localhost.pem
    SSLCertificateKeyFile /etc/apache2/ssl/localhost-key.pem
    
    # 보안 헤더
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    
    # SSL 보안 설정
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder off
    SSLSessionTickets off
</VirtualHost>
EOF
}

# 모니터링 설정
setup_monitoring() {
    log_info "모니터링 설정 중..."
    
    # 모니터링 스크립트 생성
    cat > monitoring/cert-monitor.sh << 'EOF'
#!/bin/bash

# 인증서 모니터링 스크립트
CERT_DIR="./certs"
LOG_FILE="./monitoring/cert-monitor.log"

# 인증서 상태 확인
check_certificate_status() {
    local cert_file=$1
    local domain=$2
    
    if [ ! -f "$cert_file" ]; then
        echo "ERROR: 인증서 파일을 찾을 수 없습니다: $cert_file"
        return 1
    fi
    
    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    local expiry_timestamp=$(date -d "$expiry_date" +%s)
    local current_timestamp=$(date +%s)
    local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $domain: 만료까지 $days_until_expiry일" >> "$LOG_FILE"
    
    if [ $days_until_expiry -le 30 ]; then
        echo "WARNING: $domain 인증서가 곧 만료됩니다 ($days_until_expiry일)"
    fi
}

# 모든 인증서 상태 확인
check_all_certificates() {
    check_certificate_status "./localhost.pem" "localhost"
    check_certificate_status "./api.localhost.pem" "api.localhost"
    check_certificate_status "./admin.localhost.pem" "admin.localhost"
}

# 메인 실행
main() {
    echo "인증서 모니터링 시작: $(date)"
    check_all_certificates
    echo "인증서 모니터링 완료: $(date)"
}

main "$@"
EOF

    chmod +x monitoring/cert-monitor.sh
    
    log_success "모니터링 설정 완료"
}

# Git 저장소 초기화
setup_git() {
    log_info "Git 저장소 초기화 중..."
    
    # .gitignore 파일 생성
    cat > .gitignore << 'EOF'
# 인증서 파일 (보안상 Git에 포함하지 않음)
*.pem
*.key
*.crt
*.csr
*.p12

# 로그 파일
*.log
logs/

# 백업 파일
backup/
*.backup

# 환경 설정
.env.local
.env.production

# IDE 설정
.vscode/
.idea/
*.swp
*.swo

# OS 생성 파일
.DS_Store
Thumbs.db

# Node.js
node_modules/
npm-debug.log*

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
env/
venv/

# 임시 파일
tmp/
temp/
EOF

    # Git 저장소 초기화
    git init
    git add .
    git commit -m "Initial commit: 사설 인증서 튜토리얼 프로젝트 설정"
    
    log_success "Git 저장소 초기화 완료"
}

# 메인 실행 함수
main() {
    echo "🚀 사설 인증서 튜토리얼 환경 설정을 시작합니다..."
    echo "=================================================="
    
    # 시스템 정보 확인
    check_system
    
    # 필수 도구 확인 및 설치
    check_dependencies
    
    # 프로젝트 구조 생성
    create_project_structure
    
    # mkcert 초기화
    setup_mkcert
    
    # 예제 인증서 생성
    create_example_certificates
    
    # 예제 애플리케이션 생성
    create_example_applications
    
    # 모니터링 설정
    setup_monitoring
    
    # Git 저장소 초기화
    setup_git
    
    echo ""
    echo "✅ 사설 인증서 튜토리얼 환경 설정이 완료되었습니다!"
    echo ""
    echo "📁 생성된 파일들:"
    echo "  - 인증서: localhost.pem, api.localhost.pem, admin.localhost.pem"
    echo "  - 예제 애플리케이션: examples/ 디렉토리"
    echo "  - 설정 파일: config/ 디렉토리"
    echo "  - 모니터링: monitoring/ 디렉토리"
    echo ""
    echo "🚀 다음 단계:"
    echo "  1. 튜토리얼 문서 읽기: README.md"
    echo "  2. 예제 애플리케이션 실행: examples/ 디렉토리"
    echo "  3. 모니터링 테스트: ./monitoring/cert-monitor.sh"
    echo ""
    echo "📚 튜토리얼 시작: https://github.com/your-repo/private-certificate-tutorial"
}

# 스크립트 실행
main "$@"
