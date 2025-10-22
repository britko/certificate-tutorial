#!/bin/bash

# 인증서 모니터링 스크립트
# 인증서 만료일을 확인하고 알림을 전송합니다.

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
LOG_FILE="./monitoring/cert-monitor.log"
ALERT_DAYS=30
CRITICAL_DAYS=7
EXPIRED_DAYS=0

# 알림 설정
EMAIL_ENABLED=false
SLACK_ENABLED=false
EMAIL_ADDRESS=""
SLACK_WEBHOOK=""

# 로그 디렉토리 생성
mkdir -p "$(dirname "$LOG_FILE")"

# 로그 함수
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# 인증서 만료일 계산
calculate_days_until_expiry() {
    local cert_file="$1"
    
    if [ ! -f "$cert_file" ]; then
        echo "ERROR"
        return 1
    fi
    
    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" +%s 2>/dev/null)
    local current_timestamp=$(date +%s)
    local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    echo "$days_until_expiry"
}

# 인증서 상태 확인
check_certificate_status() {
    local cert_file="$1"
    local cert_name="$2"
    
    if [ ! -f "$cert_file" ]; then
        log_message "ERROR: 인증서 파일을 찾을 수 없습니다: $cert_file"
        return 1
    fi
    
    local days_until_expiry=$(calculate_days_until_expiry "$cert_file")
    
    if [ "$days_until_expiry" = "ERROR" ]; then
        log_message "ERROR: $cert_name 인증서 정보를 읽을 수 없습니다"
        return 1
    fi
    
    local status
    local color
    
    if [ $days_until_expiry -lt $EXPIRED_DAYS ]; then
        status="EXPIRED"
        color="$RED"
    elif [ $days_until_expiry -le $CRITICAL_DAYS ]; then
        status="CRITICAL"
        color="$RED"
    elif [ $days_until_expiry -le $ALERT_DAYS ]; then
        status="WARNING"
        color="$YELLOW"
    else
        status="OK"
        color="$GREEN"
    fi
    
    echo -e "${color}[$status]${NC} $cert_name: 만료까지 $days_until_expiry일"
    log_message "$cert_name: $status (만료까지 $days_until_expiry일)"
    
    # 알림 전송
    case $status in
        "EXPIRED")
            send_alert "$cert_name" "EXPIRED" "$days_until_expiry"
            ;;
        "CRITICAL")
            send_alert "$cert_name" "CRITICAL" "$days_until_expiry"
            ;;
        "WARNING")
            send_alert "$cert_name" "WARNING" "$days_until_expiry"
            ;;
    esac
    
    return 0
}

# 이메일 알림 전송
send_email_alert() {
    local cert_name="$1"
    local status="$2"
    local days_until_expiry="$3"
    
    if [ "$EMAIL_ENABLED" != "true" ] || [ -z "$EMAIL_ADDRESS" ]; then
        return 0
    fi
    
    local subject
    local body
    
    case $status in
        "EXPIRED")
            subject="🚨 인증서 만료: $cert_name"
            body="인증서가 만료되었습니다: $cert_name"
            ;;
        "CRITICAL")
            subject="🔴 인증서 만료 임박: $cert_name"
            body="인증서가 곧 만료됩니다: $cert_name (만료까지 $days_until_expiry일)"
            ;;
        "WARNING")
            subject="🟡 인증서 갱신 권장: $cert_name"
            body="인증서 갱신을 권장합니다: $cert_name (만료까지 $days_until_expiry일)"
            ;;
    esac
    
    # 이메일 전송 (sendmail 사용)
    {
        echo "To: $EMAIL_ADDRESS"
        echo "From: cert-monitor@$(hostname)"
        echo "Subject: $subject"
        echo "Content-Type: text/html; charset=UTF-8"
        echo ""
        echo "<!DOCTYPE html>"
        echo "<html>"
        echo "<head><meta charset='UTF-8'></head>"
        echo "<body>"
        echo "<h2>🔐 인증서 모니터링 알림</h2>"
        echo "<p><strong>인증서:</strong> $cert_name</p>"
        echo "<p><strong>상태:</strong> $status</p>"
        echo "<p><strong>만료까지:</strong> $days_until_expiry일</p>"
        echo "<p><strong>시간:</strong> $(date)</p>"
        echo "<hr>"
        echo "<p><em>이 알림은 자동으로 생성되었습니다.</em></p>"
        echo "</body>"
        echo "</html>"
    } | sendmail "$EMAIL_ADDRESS" 2>/dev/null || log_warning "이메일 전송 실패"
}

# Slack 알림 전송
send_slack_alert() {
    local cert_name="$1"
    local status="$2"
    local days_until_expiry="$3"
    
    if [ "$SLACK_ENABLED" != "true" ] || [ -z "$SLACK_WEBHOOK" ]; then
        return 0
    fi
    
    local color
    local emoji
    local message
    
    case $status in
        "EXPIRED")
            color="danger"
            emoji="🚨"
            message="인증서가 만료되었습니다: $cert_name"
            ;;
        "CRITICAL")
            color="danger"
            emoji="🔴"
            message="인증서가 곧 만료됩니다: $cert_name (만료까지 $days_until_expiry일)"
            ;;
        "WARNING")
            color="warning"
            emoji="🟡"
            message="인증서 갱신을 권장합니다: $cert_name (만료까지 $days_until_expiry일)"
            ;;
    esac
    
    local payload=$(cat << EOF
{
    "attachments": [
        {
            "color": "$color",
            "title": "$emoji 인증서 모니터링 알림",
            "text": "$message",
            "fields": [
                {
                    "title": "인증서",
                    "value": "$cert_name",
                    "short": true
                },
                {
                    "title": "상태",
                    "value": "$status",
                    "short": true
                },
                {
                    "title": "만료까지",
                    "value": "$days_until_expiry일",
                    "short": true
                },
                {
                    "title": "시간",
                    "value": "$(date)",
                    "short": false
                }
            ],
            "footer": "인증서 모니터링 시스템",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
    
    curl -X POST -H 'Content-type: application/json' \
        --data "$payload" \
        "$SLACK_WEBHOOK" 2>/dev/null || log_warning "Slack 알림 전송 실패"
}

# 알림 전송
send_alert() {
    local cert_name="$1"
    local status="$2"
    local days_until_expiry="$3"
    
    send_email_alert "$cert_name" "$status" "$days_until_expiry"
    send_slack_alert "$cert_name" "$status" "$days_until_expiry"
}

# 모든 인증서 상태 확인
check_all_certificates() {
    log_info "인증서 상태 확인 시작"
    
    local total_certs=0
    local expired_certs=0
    local critical_certs=0
    local warning_certs=0
    local ok_certs=0
    
    # CA 인증서 확인
    if [ -f "$CERT_DIR/ca/ca-cert.pem" ]; then
        check_certificate_status "$CERT_DIR/ca/ca-cert.pem" "Root CA"
        ((total_certs++))
    fi
    
    # 서버 인증서 확인
    for cert_file in "$CERT_DIR/server"/*-cert.pem; do
        if [ -f "$cert_file" ]; then
            local cert_name=$(basename "$cert_file" -cert.pem)
            local days_until_expiry=$(calculate_days_until_expiry "$cert_file")
            
            if [ "$days_until_expiry" != "ERROR" ]; then
                check_certificate_status "$cert_file" "Server: $cert_name"
                ((total_certs++))
                
                if [ $days_until_expiry -lt $EXPIRED_DAYS ]; then
                    ((expired_certs++))
                elif [ $days_until_expiry -le $CRITICAL_DAYS ]; then
                    ((critical_certs++))
                elif [ $days_until_expiry -le $ALERT_DAYS ]; then
                    ((warning_certs++))
                else
                    ((ok_certs++))
                fi
            fi
        fi
    done
    
    # 클라이언트 인증서 확인
    for cert_file in "$CERT_DIR/client"/*-cert.pem; do
        if [ -f "$cert_file" ]; then
            local cert_name=$(basename "$cert_file" -cert.pem)
            local days_until_expiry=$(calculate_days_until_expiry "$cert_file")
            
            if [ "$days_until_expiry" != "ERROR" ]; then
                check_certificate_status "$cert_file" "Client: $cert_name"
                ((total_certs++))
                
                if [ $days_until_expiry -lt $EXPIRED_DAYS ]; then
                    ((expired_certs++))
                elif [ $days_until_expiry -le $CRITICAL_DAYS ]; then
                    ((critical_certs++))
                elif [ $days_until_expiry -le $ALERT_DAYS ]; then
                    ((warning_certs++))
                else
                    ((ok_certs++))
                fi
            fi
        fi
    done
    
    # 요약 정보 출력
    echo ""
    echo "📊 인증서 상태 요약"
    echo "===================="
    echo "전체 인증서: $total_certs"
    echo "만료됨: $expired_certs"
    echo "임박함: $critical_certs"
    echo "경고: $warning_certs"
    echo "정상: $ok_certs"
    
    log_message "인증서 상태 확인 완료 - 전체: $total_certs, 만료: $expired_certs, 임박: $critical_certs, 경고: $warning_certs, 정상: $ok_certs"
    
    # 경고가 있는 경우 종료 코드 설정
    if [ $expired_certs -gt 0 ] || [ $critical_certs -gt 0 ]; then
        return 1
    fi
}

# 설정 파일 로드
load_config() {
    local config_file="./monitoring/config.conf"
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        log_info "설정 파일 로드: $config_file"
    else
        log_warning "설정 파일을 찾을 수 없습니다: $config_file"
        log_info "기본 설정을 사용합니다"
    fi
}

# 설정 파일 생성
create_config() {
    local config_file="./monitoring/config.conf"
    
    mkdir -p "$(dirname "$config_file")"
    
    cat > "$config_file" << EOF
# 인증서 모니터링 설정

# 알림 설정
ALERT_DAYS=30
CRITICAL_DAYS=7
EXPIRED_DAYS=0

# 이메일 설정
EMAIL_ENABLED=false
EMAIL_ADDRESS="admin@example.com"

# Slack 설정
SLACK_ENABLED=false
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"

# 로그 설정
LOG_FILE="./monitoring/cert-monitor.log"
LOG_LEVEL="INFO"
EOF
    
    log_success "설정 파일 생성: $config_file"
}

# HTML 리포트 생성
generate_html_report() {
    local report_file="./monitoring/cert-report.html"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>인증서 모니터링 리포트</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .card { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .status { padding: 4px 8px; border-radius: 4px; color: white; font-weight: bold; }
        .status.OK { background: #28a745; }
        .status.WARNING { background: #ffc107; color: #000; }
        .status.CRITICAL { background: #dc3545; }
        .status.EXPIRED { background: #6c757d; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f8f9fa; }
        .footer { margin-top: 20px; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔐 인증서 모니터링 리포트</h1>
            <p>생성 시간: $timestamp</p>
        </div>
        
        <div class="card">
            <h2>인증서 상태</h2>
            <div id="certificates-table">
                <p>데이터 로딩 중...</p>
            </div>
        </div>
    </div>
    
    <div class="footer">
        <p>이 리포트는 자동으로 생성되었습니다.</p>
        <p>생성 시간: $timestamp</p>
    </div>
</body>
</html>
EOF
    
    log_success "HTML 리포트 생성: $report_file"
}

# 사용법 출력
show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help              도움말 출력"
    echo "  -c, --create-config     설정 파일 생성"
    echo "  -r, --report            HTML 리포트 생성"
    echo "  -a, --alert-days DAYS   경고 알림 일수 (기본: 30)"
    echo "  -C, --critical-days DAYS 임박 알림 일수 (기본: 7)"
    echo "  -e, --email ADDRESS     이메일 주소 설정"
    echo "  -s, --slack WEBHOOK     Slack 웹훅 URL 설정"
    echo ""
    echo "예시:"
    echo "  $0"
    echo "  $0 --create-config"
    echo "  $0 --report"
    echo "  $0 --alert-days 15 --critical-days 3"
    echo "  $0 --email admin@example.com --slack https://hooks.slack.com/..."
}

# 메인 실행 함수
main() {
    local create_config_flag=false
    local generate_report=false
    
    # 명령행 인수 처리
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--create-config)
                create_config_flag=true
                shift
                ;;
            -r|--report)
                generate_report=true
                shift
                ;;
            -a|--alert-days)
                ALERT_DAYS="$2"
                shift 2
                ;;
            -C|--critical-days)
                CRITICAL_DAYS="$2"
                shift 2
                ;;
            -e|--email)
                EMAIL_ADDRESS="$2"
                EMAIL_ENABLED=true
                shift 2
                ;;
            -s|--slack)
                SLACK_WEBHOOK="$2"
                SLACK_ENABLED=true
                shift 2
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "🔍 인증서 모니터링 스크립트"
    echo "=========================="
    
    # 설정 파일 생성
    if [ "$create_config_flag" = true ]; then
        create_config
        exit 0
    fi
    
    # 설정 파일 로드
    load_config
    
    # HTML 리포트 생성
    if [ "$generate_report" = true ]; then
        generate_html_report
        exit 0
    fi
    
    # 인증서 상태 확인
    check_all_certificates
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "모든 인증서가 정상 상태입니다"
    else
        log_warning "일부 인증서에 문제가 있습니다"
    fi
    
    exit $exit_code
}

# 스크립트 실행
main "$@"
