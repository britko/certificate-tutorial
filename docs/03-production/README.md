# 🚀 프로덕션 환경

## 📋 이 섹션에서 배울 내용

실제 서비스에서 사용하는 공인 인증서 관리 방법을 학습합니다. Let's Encrypt부터 클라우드 제공업체까지, 프로덕션 환경에서 필요한 모든 인증서 관리 기술을 다룹니다.

## 📚 학습 순서

### 1. [Let's Encrypt](./01-lets-encrypt.md)
**무료 공인 인증서의 혁신**

- Let's Encrypt란 무엇인가?
- 무료 공인 인증서의 장단점
- ACME 프로토콜 이해
- Rate Limit과 제한사항

**학습 시간**: 45분  
**난이도**: ⭐⭐⭐☆☆

### 2. [certbot 자동화](./02-certbot-automation.md)
**자동화된 인증서 관리**

- 자동 설치 및 설정
- 웹서버별 통합 (Apache, Nginx)
- 자동 갱신 및 모니터링
- DNS 챌린지 방식

**학습 시간**: 1시간  
**난이도**: ⭐⭐⭐☆☆

### 3. [Kubernetes cert-manager](./03-kubernetes-cert-manager.md)
**컨테이너 환경 인증서 관리**

- Kubernetes 환경에서 인증서 관리
- 자동 발급 및 갱신
- 고가용성 설정
- 서비스 메시 통합

**학습 시간**: 1.5시간  
**난이도**: ⭐⭐⭐⭐☆

### 4. [클라우드 제공업체](./04-cloud-providers.md)
**클라우드 네이티브 인증서 관리**

- AWS Certificate Manager
- Google Cloud SSL
- Azure Key Vault
- 멀티 클라우드 전략

**학습 시간**: 1시간  
**난이도**: ⭐⭐⭐☆☆

## 🎯 학습 목표

이 섹션을 완료하면 다음을 할 수 있습니다:

- ✅ Let's Encrypt로 무료 공인 인증서 발급
- ✅ certbot으로 자동화된 인증서 관리
- ✅ Kubernetes 환경에서 인증서 자동 관리
- ✅ 클라우드 제공업체 인증서 서비스 활용
- ✅ 고가용성 인증서 인프라 구축
- ✅ 인증서 모니터링 및 알림 설정

## 🛠️ 필요한 도구

- **certbot**: Let's Encrypt 클라이언트
- **Kubernetes**: 컨테이너 오케스트레이션
- **cert-manager**: Kubernetes 인증서 관리자
- **클라우드 계정**: AWS, GCP, Azure 중 하나
- **모니터링 도구**: Prometheus, Grafana 등

## 🚀 다음 단계

프로덕션 환경 설정을 완료했다면 다음 섹션으로 진행하세요:

- **[고급 주제](./../advanced/README.md)** - 전문가 수준의 인증서 관리
- **[문제 해결](./../troubleshooting/README.md)** - 운영 중 발생하는 문제들
- **[실제 시나리오](./../scenarios/README.md)** - 복잡한 아키텍처 적용

## 💡 학습 팁

- **단계별 적용**: 개발 → 스테이징 → 프로덕션 순서로 적용
- **백업 전략**: 인증서와 설정의 백업 계획 수립
- **모니터링**: 인증서 만료 알림 설정 필수
- **보안 정책**: 회사 정책에 맞는 인증서 관리 절차 수립

## 🔧 빠른 참조

### 자주 사용하는 명령어
```bash
# certbot 설치 및 설정
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d example.com

# Kubernetes cert-manager 설치
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 인증서 상태 확인
certbot certificates
kubectl get certificates
```

### 유용한 링크
- [Let's Encrypt 공식 사이트](https://letsencrypt.org/)
- [certbot 공식 문서](https://certbot.eff.org/)
- [cert-manager 공식 문서](https://cert-manager.io/)

---

**🚀 시작하려면 [Let's Encrypt](./01-lets-encrypt.md)부터 읽어보세요!**
