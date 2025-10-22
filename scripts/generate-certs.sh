#!/bin/bash

# 사설 인증서 생성 스크립트
# OpenSSL을 사용하여 Root CA와 서버/클라이언트 인증서를 생성합니다.

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

# 설정 변수
CERT_DIR="./certs"
CA_DIR="$CERT_DIR/ca"
SERVER_DIR="$CERT_DIR/server"
CLIENT_DIR="$CERT_DIR/client"
CONFIG_DIR="./config"
BACKUP_DIR="$CERT_DIR/backup"

# CA 설정
CA_COUNTRY="KR"
CA_STATE="Seoul"
CA_CITY="Seoul"
CA_ORGANIZATION="MyCompany"
CA_OU="IT Department"
CA_EMAIL="admin@mycompany.com"

# 인증서 설정
CERT_VALIDITY_DAYS=365
KEY_SIZE=4096

# 디렉토리 생성
create_directories() {
    log_info "디렉토리 구조 생성 중..."
    
    mkdir -p "$CA_DIR"
    mkdir -p "$SERVER_DIR"
    mkdir -p "$CLIENT_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$CONFIG_DIR"
    
    log_success "디렉토리 구조 생성 완료"
}

# 기존 인증서 백업
backup_existing_certificates() {
    log_info "기존 인증서 백업 중..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/$timestamp"
    
    mkdir -p "$backup_path"
    
    # 기존 인증서 파일들 백업
    if [ -f "$CA_DIR/ca-cert.pem" ]; then
        cp "$CA_DIR/ca-cert.pem" "$backup_path/"
        log_info "CA 인증서 백업: $backup_path/ca-cert.pem"
    fi
    
    if [ -f "$CA_DIR/ca-key.pem" ]; then
        cp "$CA_DIR/ca-key.pem" "$backup_path/"
        log_info "CA 개인키 백업: $backup_path/ca-key.pem"
    fi
    
    if [ -f "$SERVER_DIR/server-cert.pem" ]; then
        cp "$SERVER_DIR/server-cert.pem" "$backup_path/"
        log_info "서버 인증서 백업: $backup_path/server-cert.pem"
    fi
    
    if [ -f "$SERVER_DIR/server-key.pem" ]; then
        cp "$SERVER_DIR/server-key.pem" "$backup_path/"
        log_info "서버 개인키 백업: $backup_path/server-key.pem"
    fi
    
    log_success "기존 인증서 백업 완료: $backup_path"
}

# Root CA 생성
create_root_ca() {
    log_info "Root CA 생성 중..."
    
    # CA 개인키 생성
    openssl genrsa -out "$CA_DIR/ca-key.pem" $KEY_SIZE
    chmod 600 "$CA_DIR/ca-key.pem"
    log_success "CA 개인키 생성 완료"
    
    # CA 인증서 생성
    openssl req -new -x509 -days $((CERT_VALIDITY_DAYS * 10)) -key "$CA_DIR/ca-key.pem" -out "$CA_DIR/ca-cert.pem" \
        -subj "/C=$CA_COUNTRY/ST=$CA_STATE/L=$CA_CITY/O=$CA_ORGANIZATION/OU=$CA_OU/CN=MyCompany Root CA/emailAddress=$CA_EMAIL"
    
    log_success "CA 인증서 생성 완료"
    
    # CA 데이터베이스 초기화
    touch "$CA_DIR/index.txt"
    echo 1000 > "$CA_DIR/serial"
    echo 1000 > "$CA_DIR/crlnumber"
    
    log_success "CA 데이터베이스 초기화 완료"
}

# 서버 인증서 생성
create_server_certificate() {
    local domain=$1
    local cert_file="$SERVER_DIR/${domain}-cert.pem"
    local key_file="$SERVER_DIR/${domain}-key.pem"
    local csr_file="$SERVER_DIR/${domain}.csr"
    
    log_info "서버 인증서 생성 중: $domain"
    
    # 서버 개인키 생성
    openssl genrsa -out "$key_file" $KEY_SIZE
    chmod 600 "$key_file"
    log_success "서버 개인키 생성 완료: $key_file"
    
    # 서버 인증서 요청서(CSR) 생성
    openssl req -new -key "$key_file" -out "$csr_file" \
        -subj "/C=$CA_COUNTRY/ST=$CA_STATE/L=$CA_CITY/O=$CA_ORGANIZATION/OU=$CA_OU/CN=$domain/emailAddress=$CA_EMAIL"
    
    log_success "서버 CSR 생성 완료: $csr_file"
    
    # 서버 인증서 서명
    openssl ca -config "$CONFIG_DIR/ca.conf" -extensions server_cert -days $CERT_VALIDITY_DAYS -notext -md sha256 \
        -in "$csr_file" -out "$cert_file"
    
    log_success "서버 인증서 생성 완료: $cert_file"
    
    # CSR 파일 삭제 (보안상)
    rm "$csr_file"
    log_info "CSR 파일 삭제 완료"
}

# 클라이언트 인증서 생성
create_client_certificate() {
    local client_name=$1
    local cert_file="$CLIENT_DIR/${client_name}-cert.pem"
    local key_file="$CLIENT_DIR/${client_name}-key.pem"
    local csr_file="$CLIENT_DIR/${client_name}.csr"
    local p12_file="$CLIENT_DIR/${client_name}.p12"
    
    log_info "클라이언트 인증서 생성 중: $client_name"
    
    # 클라이언트 개인키 생성
    openssl genrsa -out "$key_file" $KEY_SIZE
    chmod 600 "$key_file"
    log_success "클라이언트 개인키 생성 완료: $key_file"
    
    # 클라이언트 인증서 요청서(CSR) 생성
    openssl req -new -key "$key_file" -out "$csr_file" \
        -subj "/C=$CA_COUNTRY/ST=$CA_STATE/L=$CA_CITY/O=$CA_ORGANIZATION/OU=$CA_OU/CN=$client_name/emailAddress=$CA_EMAIL"
    
    log_success "클라이언트 CSR 생성 완료: $csr_file"
    
    # 클라이언트 인증서 서명
    openssl ca -config "$CONFIG_DIR/ca.conf" -extensions usr_cert -days $CERT_VALIDITY_DAYS -notext -md sha256 \
        -in "$csr_file" -out "$cert_file"
    
    log_success "클라이언트 인증서 생성 완료: $cert_file"
    
    # PKCS#12 형식으로 변환
    openssl pkcs12 -export -out "$p12_file" -inkey "$key_file" -in "$cert_file" -certfile "$CA_DIR/ca-cert.pem"
    log_success "PKCS#12 인증서 생성 완료: $p12_file"
    
    # CSR 파일 삭제 (보안상)
    rm "$csr_file"
    log_info "CSR 파일 삭제 완료"
}

# 인증서 검증
verify_certificates() {
    log_info "인증서 검증 중..."
    
    # CA 인증서 검증
    if openssl x509 -in "$CA_DIR/ca-cert.pem" -noout -checkend 0; then
        log_success "CA 인증서 유효성 검증 통과"
    else
        log_error "CA 인증서 유효성 검증 실패"
        return 1
    fi
    
    # 서버 인증서 검증
    for cert_file in "$SERVER_DIR"/*-cert.pem; do
        if [ -f "$cert_file" ]; then
            local domain=$(basename "$cert_file" -cert.pem)
            if openssl verify -CAfile "$CA_DIR/ca-cert.pem" "$cert_file" > /dev/null 2>&1; then
                log_success "서버 인증서 검증 통과: $domain"
            else
                log_error "서버 인증서 검증 실패: $domain"
                return 1
            fi
        fi
    done
    
    # 클라이언트 인증서 검증
    for cert_file in "$CLIENT_DIR"/*-cert.pem; do
        if [ -f "$cert_file" ]; then
            local client_name=$(basename "$cert_file" -cert.pem)
            if openssl verify -CAfile "$CA_DIR/ca-cert.pem" "$cert_file" > /dev/null 2>&1; then
                log_success "클라이언트 인증서 검증 통과: $client_name"
            else
                log_error "클라이언트 인증서 검증 실패: $client_name"
                return 1
            fi
        fi
    done
    
    log_success "모든 인증서 검증 완료"
}

# 인증서 정보 출력
show_certificate_info() {
    log_info "인증서 정보 출력 중..."
    
    echo ""
    echo "📋 생성된 인증서 정보"
    echo "======================"
    
    # CA 인증서 정보
    echo ""
    echo "🔐 Root CA 인증서:"
    openssl x509 -in "$CA_DIR/ca-cert.pem" -noout -subject -issuer -dates
    
    # 서버 인증서 정보
    echo ""
    echo "🖥️ 서버 인증서들:"
    for cert_file in "$SERVER_DIR"/*-cert.pem; do
        if [ -f "$cert_file" ]; then
            local domain=$(basename "$cert_file" -cert.pem)
            echo "  - $domain:"
            openssl x509 -in "$cert_file" -noout -subject -dates
        fi
    done
    
    # 클라이언트 인증서 정보
    echo ""
    echo "👤 클라이언트 인증서들:"
    for cert_file in "$CLIENT_DIR"/*-cert.pem; do
        if [ -f "$cert_file" ]; then
            local client_name=$(basename "$cert_file" -cert.pem)
            echo "  - $client_name:"
            openssl x509 -in "$cert_file" -noout -subject -dates
        fi
    done
}

# 사용법 출력
show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help              도움말 출력"
    echo "  -d, --domains DOMAINS   서버 도메인 목록 (쉼표로 구분)"
    echo "  -c, --clients CLIENTS   클라이언트 이름 목록 (쉼표로 구분)"
    echo "  -b, --backup            기존 인증서 백업"
    echo "  -v, --verify            인증서 검증만 수행"
    echo "  -i, --info              인증서 정보 출력"
    echo ""
    echo "예시:"
    echo "  $0 -d localhost,api.localhost -c client1,client2"
    echo "  $0 --backup"
    echo "  $0 --verify"
    echo "  $0 --info"
}

# 메인 실행 함수
main() {
    local domains="localhost,api.localhost,admin.localhost"
    local clients="client1,client2"
    local backup=false
    local verify_only=false
    local info_only=false
    
    # 명령행 인수 처리
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -d|--domains)
                domains="$2"
                shift 2
                ;;
            -c|--clients)
                clients="$2"
                shift 2
                ;;
            -b|--backup)
                backup=true
                shift
                ;;
            -v|--verify)
                verify_only=true
                shift
                ;;
            -i|--info)
                info_only=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "🔐 사설 인증서 생성 스크립트"
    echo "=============================="
    
    # 정보만 출력하는 경우
    if [ "$info_only" = true ]; then
        show_certificate_info
        exit 0
    fi
    
    # 검증만 수행하는 경우
    if [ "$verify_only" = true ]; then
        verify_certificates
        exit 0
    fi
    
    # 디렉토리 생성
    create_directories
    
    # 기존 인증서 백업
    if [ "$backup" = true ]; then
        backup_existing_certificates
    fi
    
    # Root CA 생성
    create_root_ca
    
    # 서버 인증서 생성
    IFS=',' read -ra DOMAIN_ARRAY <<< "$domains"
    for domain in "${DOMAIN_ARRAY[@]}"; do
        create_server_certificate "$domain"
    done
    
    # 클라이언트 인증서 생성
    IFS=',' read -ra CLIENT_ARRAY <<< "$clients"
    for client in "${CLIENT_ARRAY[@]}"; do
        create_client_certificate "$client"
    done
    
    # 인증서 검증
    verify_certificates
    
    # 인증서 정보 출력
    show_certificate_info
    
    echo ""
    echo "✅ 모든 인증서 생성이 완료되었습니다!"
    echo ""
    echo "📁 생성된 파일들:"
    echo "  - CA 인증서: $CA_DIR/ca-cert.pem"
    echo "  - CA 개인키: $CA_DIR/ca-key.pem"
    echo "  - 서버 인증서: $SERVER_DIR/*-cert.pem"
    echo "  - 서버 개인키: $SERVER_DIR/*-key.pem"
    echo "  - 클라이언트 인증서: $CLIENT_DIR/*-cert.pem"
    echo "  - 클라이언트 개인키: $CLIENT_DIR/*-key.pem"
    echo "  - 클라이언트 PKCS#12: $CLIENT_DIR/*.p12"
    echo ""
    echo "🔧 다음 단계:"
    echo "  1. CA 인증서를 시스템 신뢰 저장소에 추가"
    echo "  2. 서버 인증서를 웹 서버에 설정"
    echo "  3. 클라이언트 인증서를 브라우저에 설치"
    echo ""
    echo "📚 자세한 사용법은 튜토리얼 문서를 참고하세요."
}

# 스크립트 실행
main "$@"
