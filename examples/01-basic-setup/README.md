# 기본 설정 예제

이 폴더에는 간단한 웹서버 HTTPS 설정 예제들이 포함되어 있습니다.

## 📁 파일 구조

```
basic-setup/
├── nginx/
│   ├── nginx.conf          # Nginx SSL 설정
│   ├── ssl.conf            # SSL 전용 설정
│   └── docker-compose.yml  # Docker 환경
├── apache/
│   ├── httpd.conf          # Apache SSL 설정
│   ├── ssl.conf            # SSL 전용 설정
│   └── docker-compose.yml  # Docker 환경
├── nodejs/
│   ├── server.js           # Node.js HTTPS 서버
│   ├── package.json        # 의존성 관리
│   └── docker-compose.yml  # Docker 환경
└── python/
    ├── app.py              # Python Flask HTTPS 서버
    ├── requirements.txt    # 의존성 관리
    └── docker-compose.yml  # Docker 환경
```

## 🚀 빠른 시작

### 1. Nginx HTTPS 설정
```bash
cd nginx
docker-compose up -d
# https://localhost 접속
```

### 2. Apache HTTPS 설정
```bash
cd apache
docker-compose up -d
# https://localhost 접속
```

### 3. Node.js HTTPS 서버
```bash
cd nodejs
npm install
node server.js
# https://localhost:3000 접속
```

### 4. Python Flask HTTPS 서버
```bash
cd python
pip install -r requirements.txt
python app.py
# https://localhost:5000 접속
```

## 📋 사전 요구사항

- Docker (컨테이너 환경 사용 시)
- Node.js 16+ (Node.js 예제 사용 시)
- Python 3.8+ (Python 예제 사용 시)
- OpenSSL 또는 mkcert

## 🔧 인증서 생성

### mkcert 사용 (권장)
```bash
# mkcert 설치
mkcert -install

# localhost 인증서 생성
mkcert localhost 127.0.0.1 ::1

# 생성된 파일을 각 예제 폴더에 복사
cp localhost.pem localhost-key.pem nginx/
cp localhost.pem localhost-key.pem apache/
cp localhost.pem localhost-key.pem nodejs/
cp localhost.pem localhost-key.pem python/
```

### OpenSSL 사용
```bash
# 자체 서명 인증서 생성
openssl req -x509 -newkey rsa:4096 -keyout localhost-key.pem -out localhost.pem -days 365 -nodes -subj "/CN=localhost"
```

## 📚 각 예제 설명

### Nginx
- 고성능 웹서버의 SSL/TLS 설정
- HTTP to HTTPS 리다이렉션
- 보안 헤더 설정

### Apache
- 전통적인 웹서버의 SSL/TLS 설정
- 가상 호스트 설정
- 모듈 기반 설정

### Node.js
- Express.js 기반 HTTPS 서버
- 미들웨어를 통한 보안 설정
- 환경별 설정 관리

### Python
- Flask 기반 HTTPS 서버
- WSGI 서버 설정
- 보안 헤더 및 설정

## 🔍 문제 해결

### 일반적인 문제
1. **인증서 오류**: 브라우저에서 "Not Secure" 경고
   - 해결: mkcert로 생성한 인증서 사용

2. **포트 충돌**: 443 포트 사용 중
   - 해결: 다른 포트 사용 또는 기존 서비스 중지

3. **권한 오류**: 파일 접근 권한 문제
   - 해결: 파일 권한 확인 및 수정

## 📖 추가 학습

- [개발 환경 가이드](../../docs/development/README.md)
- [문제 해결 가이드](../../docs/troubleshooting/README.md)
- [실제 시나리오](../../docs/scenarios/README.md)

---

**💡 팁**: 각 예제를 실행하기 전에 해당 폴더의 README.md를 확인하세요!
