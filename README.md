# 인증서 관리 완전 가이드

## 🎯 이 레포지토리에서 배울 수 있는 것

이 레포지토리는 **개발부터 프로덕션까지** 인증서 관리의 전체 라이프사이클을 다룹니다. 사설 인증서로 시작해서 공인 인증서까지, 실제 업무에서 필요한 모든 인증서 관리 기술을 단계별로 학습할 수 있습니다.

## 🚀 빠른 시작

### 🆕 처음 시작하는 분
**[기본 개념 이해](./docs/01-getting-started/01-basic-concepts.md)** → **[mkcert 빠른 시작](./docs/02-development/02-mkcert-quickstart.md)** → **[실제 시나리오](./docs/04-scenarios/01-startup-security.md)**

### 👨‍💻 개발자
**[로컬 개발 환경](./docs/02-development/03-local-development.md)** → **[마이크로서비스 보안](./docs/04-scenarios/02-microservices.md)** → **[문제 해결](./docs/05-troubleshooting/01-common-issues.md)**

### 🚀 운영자
**[Let's Encrypt](./docs/03-production/01-lets-encrypt.md)** → **[Kubernetes 관리](./docs/03-production/03-kubernetes-cert-manager.md)** → **[고급 주제](./docs/06-advanced/01-pki-design.md)**

## 📚 전체 학습 경로

### 🎓 기초 학습
**개발자가 알아야 할 인증서 기본기**

- **[기본 개념 이해](./docs/01-getting-started/01-basic-concepts.md)**
  - 인증서란 무엇인가?
  - 공인 vs 사설 인증서
  - PKI 기본 개념

- **[인증서가 필요한 이유](./docs/01-getting-started/02-why-certificates.md)**
  - 보안의 중요성
  - 개발 환경에서의 필요성
  - 비용 효율성

### 🏠 개발 환경
**개발 단계에서 빠르고 안전한 인증서 관리**

- **[OpenSSL 기초](./docs/02-development/01-openssl-basics.md)**
  - Root CA 생성
  - 서버/클라이언트 인증서 발급
  - 고급 보안 설정

- **[mkcert 빠른 시작](./docs/02-development/02-mkcert-quickstart.md)**
  - 원클릭 설치 및 설정
  - 자동 브라우저 신뢰
  - 개발자 친화적 도구

- **[로컬 개발 환경](./docs/02-development/03-local-development.md)**
  - 웹 서버 설정
  - API 서버 보안
  - 모바일 앱 연결

### 🚀 프로덕션 환경
**실제 서비스에서 사용하는 공인 인증서 관리**

- **[Let's Encrypt](./docs/03-production/01-lets-encrypt.md)**
  - 무료 공인 인증서 발급
  - ACME 프로토콜 이해
  - Rate Limit 관리

- **[certbot 자동화](./docs/03-production/02-certbot-automation.md)**
  - 자동 설치 및 설정
  - 웹서버별 통합
  - 자동 갱신 및 모니터링

- **[Kubernetes cert-manager](./docs/03-production/03-kubernetes-cert-manager.md)**
  - 컨테이너 환경 인증서 관리
  - 자동 발급 및 갱신
  - 고가용성 설정

- **[클라우드 제공업체](./docs/03-production/04-cloud-providers.md)**
  - AWS Certificate Manager
  - Google Cloud SSL
  - Azure Key Vault

### 🎭 실제 시나리오
**실제 회사에서 발생하는 문제와 해결책**

- **[스타트업 보안 문제](./docs/04-scenarios/01-startup-security.md)**
  - 급성장하는 회사의 보안 인프라 구축
  - 개발팀의 보안 허점 해결
  - 비용 효율적인 보안 전략

- **[마이크로서비스 아키텍처](./docs/04-scenarios/02-microservices.md)**
  - 서비스 간 보안 통신
  - API Gateway 보안 설정
  - 서비스 메시 보안

- **[CI/CD 통합](./docs/04-scenarios/03-ci-cd-integration.md)**
  - 자동 인증서 배포
  - 환경별 인증서 관리
  - 보안 검증 파이프라인

### 🔧 문제 해결
**실무에서 마주치는 문제들의 해결책**

- **[일반적인 문제](./docs/05-troubleshooting/01-common-issues.md)**
  - 브라우저 경고 해결
  - 연결 오류 해결
  - 인증서 검증 실패

- **[디버깅 가이드](./docs/05-troubleshooting/02-debugging-guide.md)**
  - OpenSSL 디버깅 도구
  - 네트워크 분석
  - 로그 분석 방법

- **[성능 튜닝](./docs/05-troubleshooting/03-performance-tuning.md)**
  - SSL/TLS 성능 최적화
  - 인증서 크기 최적화
  - 연결 풀링 설정

### 🧠 고급 주제
**전문가를 위한 심화 내용**

- **[PKI 설계](./docs/06-advanced/01-pki-design.md)**
  - 엔터프라이즈 PKI 설계
  - 계층적 CA 구조
  - 정책 및 절차 수립

- **[인증서 로테이션](./docs/06-advanced/02-certificate-rotation.md)**
  - 무중단 인증서 교체
  - 자동 로테이션 전략
  - 롤백 계획

- **[모니터링 및 알림](./docs/06-advanced/03-monitoring-alerts.md)**
  - 인증서 만료 모니터링
  - 자동 알림 시스템
  - 대시보드 구축

## 📁 실습 예제

- **[기본 설정](./examples/01-basic-setup/)** - 간단한 웹서버 HTTPS 설정
- **[마이크로서비스](./examples/02-microservices/)** - 서비스 간 보안 통신
- **[Kubernetes](./examples/03-kubernetes/)** - 컨테이너 환경 설정
- **[클라우드 배포](./examples/04-cloud-deployment/)** - AWS/GCP/Azure 설정

## 🎯 사용자별 추천 경로

### 🆕 초보자 (개발자)
1. **[기본 개념 이해](./docs/01-getting-started/01-basic-concepts.md)**
2. **[mkcert 빠른 시작](./docs/02-development/02-mkcert-quickstart.md)**
3. **[로컬 개발 환경](./docs/02-development/03-local-development.md)**
4. **[일반적인 문제](./docs/05-troubleshooting/01-common-issues.md)**

### 👨‍💻 중급자 (풀스택 개발자)
1. **[OpenSSL 기초](./docs/02-development/01-openssl-basics.md)**
2. **[마이크로서비스](./docs/04-scenarios/02-microservices.md)**
3. **[Let's Encrypt](./docs/03-production/01-lets-encrypt.md)**
4. **[디버깅 가이드](./docs/05-troubleshooting/02-debugging-guide.md)**

### 🚀 고급자 (DevOps/SRE)
1. **[스타트업 보안 문제](./docs/04-scenarios/01-startup-security.md)**
2. **[Kubernetes cert-manager](./docs/03-production/03-kubernetes-cert-manager.md)**
3. **[CI/CD 통합](./docs/04-scenarios/03-ci-cd-integration.md)**
4. **[PKI 설계](./docs/06-advanced/01-pki-design.md)**

### 🧠 전문가 (보안 아키텍트)
1. **[고급 주제 전체](./docs/06-advanced/)**
2. **[모든 시나리오](./docs/04-scenarios/)**
3. **[성능 튜닝](./docs/05-troubleshooting/03-performance-tuning.md)**

## 📋 사전 요구사항

- **기본**: Windows 10/11, macOS, 또는 Linux
- **중급**: Docker, Kubernetes 기본 지식
- **고급**: 클라우드 플랫폼 경험, 네트워킹 지식

## 🎯 학습 목표

### 🏠 개발 환경
- ✅ 사설 인증서로 개발 환경 보안 강화
- ✅ 브라우저 경고 없는 안전한 개발
- ✅ 모바일 앱과 개발 서버 연결
- ✅ 마이크로서비스 간 보안 통신

### 🚀 프로덕션 환경
- ✅ Let's Encrypt로 무료 공인 인증서 발급
- ✅ 자동 인증서 갱신 및 모니터링
- ✅ Kubernetes 환경에서 인증서 관리
- ✅ 고가용성 인증서 인프라 구축

### 🛠️ 실무 적용
- ✅ 실제 프로젝트에 HTTPS 적용
- ✅ 인증서 관련 문제 해결
- ✅ 보안 취약점 사전 방지
- ✅ 비용 효율적인 인증서 관리

## 💡 사용 팁

- **목적별 학습**: 원하는 목적에 맞는 섹션부터 시작하세요
- **실습 중심**: 이론보다는 실습을 통해 직접 경험해보세요
- **문제 해결**: 문제 발생 시 해당 섹션의 문제 해결 가이드를 참고하세요
- **커뮤니티**: 추가 질문이 있으면 이슈를 등록해주세요

## 📝 라이선스

이 튜토리얼은 MIT 라이선스 하에 제공됩니다.

## 🤝 기여하기

버그 리포트, 기능 요청, 또는 개선 사항이 있으시면 언제든지 기여해주세요!

---

**🚀 시작하려면 [기본 개념 이해](./docs/01-getting-started/01-basic-concepts.md)부터 읽어보세요!**
