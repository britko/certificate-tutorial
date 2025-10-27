# 🏠 개발 환경

## 📋 이 섹션에서 배울 내용

개발 단계에서 빠르고 안전한 인증서 관리 방법을 학습합니다. 복잡한 설정 없이도 개발 환경을 보안으로 강화할 수 있는 실용적인 도구들과 기법들을 다룹니다.

## 📚 학습 순서

### 1. [OpenSSL 기초](./01-openssl-basics.md)
**전통적이지만 강력한 인증서 생성 도구**

- Root CA 생성
- 서버/클라이언트 인증서 발급
- 고급 보안 설정
- 자동화 스크립트 작성

**학습 시간**: 2시간  
**난이도**: ⭐⭐⭐⭐☆

### 2. [mkcert 빠른 시작](./02-mkcert-quickstart.md)
**개발자 친화적인 간편 도구**

- 원클릭 설치 및 설정
- 자동 브라우저 신뢰
- 개발자 친화적 도구 활용
- 다양한 환경 지원

**학습 시간**: 30분  
**난이도**: ⭐⭐☆☆☆

### 3. [로컬 개발 환경](./03-local-development.md)
**실제 프로젝트에 적용하기**

- 웹 서버 설정 (Nginx, Apache)
- API 서버 보안
- 모바일 앱 연결
- Docker 환경 통합

**학습 시간**: 1시간  
**난이도**: ⭐⭐⭐☆☆

## 🎯 학습 목표

이 섹션을 완료하면 다음을 할 수 있습니다:

- ✅ OpenSSL을 사용하여 사설 인증서 생성
- ✅ mkcert로 간편하게 개발 환경 보안 강화
- ✅ 웹 서버에 HTTPS 적용
- ✅ API 서버 보안 설정
- ✅ 모바일 앱과 개발 서버 연결
- ✅ Docker 환경에서 인증서 사용

## 🛠️ 필요한 도구

- **OpenSSL**: 인증서 생성 및 관리
- **mkcert**: 간편한 개발용 인증서
- **웹 서버**: Nginx 또는 Apache
- **개발 환경**: Node.js, Python, 또는 선호하는 언어
- **Docker**: 컨테이너 환경 (선택사항)

## 🚀 다음 단계

개발 환경 설정을 완료했다면 다음 섹션으로 진행하세요:

- **[실제 시나리오](./../scenarios/README.md)** - 복잡한 아키텍처에서의 적용
- **[프로덕션 환경](./../production/README.md)** - 실제 서비스 배포
- **[문제 해결](./../troubleshooting/README.md)** - 발생할 수 있는 문제들

## 💡 학습 팁

- **실습 중심**: 모든 예제를 직접 따라해보세요
- **환경별 테스트**: 다양한 환경에서 테스트해보세요
- **자동화**: 반복 작업은 스크립트로 자동화하세요
- **문서화**: 설정 과정을 문서로 남겨두세요

## 🔧 빠른 참조

### 자주 사용하는 명령어
```bash
# mkcert 설치 및 설정
mkcert -install
mkcert localhost 127.0.0.1

# OpenSSL 인증서 생성
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr
openssl x509 -req -in server.csr -signkey server.key -out server.crt
```

### 유용한 링크
- [mkcert GitHub](https://github.com/FiloSottile/mkcert)
- [OpenSSL 공식 문서](https://www.openssl.org/docs/)
- [Nginx SSL 설정 가이드](https://nginx.org/en/docs/http/configuring_https_servers.html)

---

**🚀 시작하려면 [OpenSSL 기초](./01-openssl-basics.md)부터 읽어보세요!**
