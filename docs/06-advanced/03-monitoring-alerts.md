# 모니터링 및 알림

## 🎯 이 장에서 배울 내용

이 장에서는 고급 모니터링 시스템을 구축하는 방법을 학습합니다. 인증서 만료 모니터링부터 예측적 관리 시스템까지, 엔터프라이즈급 모니터링 인프라를 구축하는 모든 기술을 다룹니다.

## 📊 인증서 만료 모니터링

### 실시간 만료 모니터링

#### Prometheus 기반 모니터링
```python
#!/usr/bin/env python3
# certificate-monitor.py

import os
import json
import subprocess
import time
from datetime import datetime, timedelta
from prometheus_client import start_http_server, Gauge, Counter, Histogram

# 메트릭 정의
certificate_expiry_days = Gauge('certificate_expiry_days', 'Days until certificate expiry', ['domain', 'issuer'])
certificate_expiry_status = Gauge('certificate_expiry_status', 'Certificate expiry status', ['domain', 'status'])
certificate_renewal_attempts = Counter('certificate_renewal_attempts_total', 'Certificate renewal attempts', ['domain', 'result'])
certificate_check_duration = Histogram('certificate_check_duration_seconds', 'Time spent checking certificates')

class CertificateMonitor:
    def __init__(self):
        self.certificates = []
        self.load_certificate_list()
    
    def load_certificate_list(self):
        """모니터링할 인증서 목록 로드"""
        config_file = '/etc/cert-monitor/certificates.json'
        try:
            with open(config_file, 'r') as f:
                config = json.load(f)
                self.certificates = config.get('certificates', [])
        except FileNotFoundError:
            print(f"설정 파일을 찾을 수 없습니다: {config_file}")
            self.certificates = []
    
    @certificate_check_duration.time()
    def check_certificate_expiry(self, domain, port=443):
        """인증서 만료일 확인"""
        try:
            # SSL 연결을 통한 인증서 정보 조회
            result = subprocess.run([
                'openssl', 's_client', '-connect', f'{domain}:{port}',
                '-servername', domain, '-quiet'
            ], input=b'', capture_output=True, timeout=10)
            
            if result.returncode != 0:
                return None
            
            # 인증서 만료일 추출
            cert_info = subprocess.run([
                'openssl', 's_client', '-connect', f'{domain}:{port}',
                '-servername', domain, '-quiet'
            ], input=b'', capture_output=True, text=True, timeout=10)
            
            # 인증서 정보 파싱
            lines = cert_info.stdout.split('\n')
            for line in lines:
                if 'notAfter' in line:
                    expiry_str = line.split('=')[1].strip()
                    expiry_date = datetime.strptime(expiry_str, '%b %d %H:%M:%S %Y %Z')
                    days_until_expiry = (expiry_date - datetime.now()).days
                    return days_until_expiry
            
            return None
            
        except Exception as e:
            print(f"인증서 확인 오류 {domain}: {e}")
            return None
    
    def update_metrics(self):
        """메트릭 업데이트"""
        for cert in self.certificates:
            domain = cert['domain']
            port = cert.get('port', 443)
            
            days_until_expiry = self.check_certificate_expiry(domain, port)
            
            if days_until_expiry is not None:
                # 만료일 메트릭 업데이트
                certificate_expiry_days.labels(domain=domain, issuer=cert.get('issuer', 'unknown')).set(days_until_expiry)
                
                # 상태 메트릭 업데이트
                if days_until_expiry <= 0:
                    status = 'expired'
                elif days_until_expiry <= 7:
                    status = 'critical'
                elif days_until_expiry <= 30:
                    status = 'warning'
                else:
                    status = 'ok'
                
                certificate_expiry_status.labels(domain=domain, status=status).set(1)
            else:
                # 인증서 확인 실패
                certificate_expiry_status.labels(domain=domain, status='error').set(1)

def main():
    monitor = CertificateMonitor()
    
    # Prometheus 메트릭 서버 시작
    start_http_server(8000)
    print("인증서 모니터링 서버 시작: http://localhost:8000/metrics")
    
    # 주기적으로 메트릭 업데이트
    while True:
        monitor.update_metrics()
        time.sleep(300)  # 5분마다 확인

if __name__ == '__main__':
    main()
```

#### 설정 파일 예시
```json
{
  "certificates": [
    {
      "domain": "example.com",
      "port": 443,
      "issuer": "Let's Encrypt",
      "renewal_threshold": 30,
      "critical_threshold": 7
    },
    {
      "domain": "api.example.com",
      "port": 443,
      "issuer": "Let's Encrypt",
      "renewal_threshold": 30,
      "critical_threshold": 7
    },
    {
      "domain": "internal.example.com",
      "port": 443,
      "issuer": "Internal CA",
      "renewal_threshold": 60,
      "critical_threshold": 14
    }
  ],
  "alerting": {
    "slack_webhook": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "email": {
      "smtp_server": "smtp.example.com",
      "smtp_port": 587,
      "username": "alerts@example.com",
      "password": "password"
    }
  }
}
```

## 🚨 자동 알림 시스템

### 다중 채널 알림 시스템

#### 통합 알림 서비스
```python
#!/usr/bin/env python3
# alert-manager.py

import json
import smtplib
import requests
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

class AlertManager:
    def __init__(self, config_file='/etc/cert-monitor/alerts.json'):
        with open(config_file, 'r') as f:
            self.config = json.load(f)
    
    def send_slack_alert(self, message, severity='warning'):
        """Slack 알림 전송"""
        webhook_url = self.config['slack_webhook']
        
        # 심각도별 색상 설정
        color_map = {
            'critical': '#FF0000',
            'warning': '#FFA500',
            'info': '#00FF00'
        }
        
        payload = {
            'attachments': [{
                'color': color_map.get(severity, '#FFA500'),
                'title': f'인증서 알림 - {severity.upper()}',
                'text': message,
                'timestamp': int(datetime.now().timestamp())
            }]
        }
        
        try:
            response = requests.post(webhook_url, json=payload)
            response.raise_for_status()
            print(f"Slack 알림 전송 완료: {message}")
        except Exception as e:
            print(f"Slack 알림 전송 실패: {e}")
    
    def send_email_alert(self, subject, message, recipients):
        """이메일 알림 전송"""
        email_config = self.config['email']
        
        msg = MIMEMultipart()
        msg['From'] = email_config['username']
        msg['To'] = ', '.join(recipients)
        msg['Subject'] = subject
        
        msg.attach(MIMEText(message, 'plain', 'utf-8'))
        
        try:
            server = smtplib.SMTP(email_config['smtp_server'], email_config['smtp_port'])
            server.starttls()
            server.login(email_config['username'], email_config['password'])
            
            text = msg.as_string()
            server.sendmail(email_config['username'], recipients, text)
            server.quit()
            
            print(f"이메일 알림 전송 완료: {subject}")
        except Exception as e:
            print(f"이메일 알림 전송 실패: {e}")
    
    def send_webhook_alert(self, message, severity='warning'):
        """웹훅 알림 전송"""
        webhook_url = self.config.get('webhook_url')
        if not webhook_url:
            return
        
        payload = {
            'timestamp': datetime.now().isoformat(),
            'severity': severity,
            'message': message,
            'source': 'certificate-monitor'
        }
        
        try:
            response = requests.post(webhook_url, json=payload)
            response.raise_for_status()
            print(f"웹훅 알림 전송 완료: {message}")
        except Exception as e:
            print(f"웹훅 알림 전송 실패: {e}")
    
    def send_alert(self, message, severity='warning', channels=['slack', 'email']):
        """통합 알림 전송"""
        subject = f"인증서 알림 - {severity.upper()}"
        
        if 'slack' in channels:
            self.send_slack_alert(message, severity)
        
        if 'email' in channels:
            recipients = self.config['email']['recipients']
            self.send_email_alert(subject, message, recipients)
        
        if 'webhook' in channels:
            self.send_webhook_alert(message, severity)

# 알림 규칙 정의
class AlertRules:
    def __init__(self, alert_manager):
        self.alert_manager = alert_manager
    
    def check_expiry_threshold(self, domain, days_until_expiry, threshold):
        """만료 임계값 확인"""
        if days_until_expiry <= threshold:
            if days_until_expiry <= 0:
                severity = 'critical'
                message = f"🚨 긴급: {domain} 인증서가 만료되었습니다!"
            elif days_until_expiry <= 7:
                severity = 'critical'
                message = f"⚠️ 긴급: {domain} 인증서가 {days_until_expiry}일 후 만료됩니다!"
            else:
                severity = 'warning'
                message = f"⚠️ 경고: {domain} 인증서가 {days_until_expiry}일 후 만료됩니다!"
            
            self.alert_manager.send_alert(message, severity)
            return True
        
        return False
    
    def check_renewal_failure(self, domain, error_message):
        """갱신 실패 확인"""
        severity = 'critical'
        message = f"❌ 인증서 갱신 실패: {domain}\n오류: {error_message}"
        
        self.alert_manager.send_alert(message, severity, ['slack', 'email'])
    
    def check_certificate_chain(self, domain, chain_status):
        """인증서 체인 확인"""
        if chain_status != 'valid':
            severity = 'warning'
            message = f"🔗 인증서 체인 문제: {domain}\n상태: {chain_status}"
            
            self.alert_manager.send_alert(message, severity)
```

## 📈 대시보드 구축

### Grafana 대시보드 설정

#### 대시보드 JSON 설정
```json
{
  "dashboard": {
    "title": "Certificate Monitoring Dashboard",
    "panels": [
      {
        "title": "Certificate Expiry Overview",
        "type": "stat",
        "targets": [
          {
            "expr": "certificate_expiry_status{status=\"critical\"}",
            "legendFormat": "Critical"
          },
          {
            "expr": "certificate_expiry_status{status=\"warning\"}",
            "legendFormat": "Warning"
          },
          {
            "expr": "certificate_expiry_status{status=\"ok\"}",
            "legendFormat": "OK"
          }
        ]
      },
      {
        "title": "Days Until Expiry",
        "type": "graph",
        "targets": [
          {
            "expr": "certificate_expiry_days",
            "legendFormat": "{{domain}}"
          }
        ],
        "yAxes": [
          {
            "label": "Days",
            "min": 0,
            "max": 365
          }
        ],
        "thresholds": [
          {
            "value": 30,
            "colorMode": "critical",
            "op": "lt"
          },
          {
            "value": 60,
            "colorMode": "warning",
            "op": "lt"
          }
        ]
      },
      {
        "title": "Certificate Renewal Attempts",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(certificate_renewal_attempts_total[5m])",
            "legendFormat": "{{domain}} - {{result}}"
          }
        ]
      },
      {
        "title": "Certificate Check Duration",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(certificate_check_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(certificate_check_duration_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

### 커스텀 대시보드

#### 웹 기반 대시보드
```python
#!/usr/bin/env python3
# dashboard.py

from flask import Flask, render_template, jsonify
import json
import subprocess
from datetime import datetime, timedelta

app = Flask(__name__)

class CertificateDashboard:
    def __init__(self):
        self.certificates = self.load_certificates()
    
    def load_certificates(self):
        """인증서 목록 로드"""
        try:
            with open('/etc/cert-monitor/certificates.json', 'r') as f:
                config = json.load(f)
                return config.get('certificates', [])
        except FileNotFoundError:
            return []
    
    def get_certificate_status(self):
        """인증서 상태 조회"""
        status_list = []
        
        for cert in self.certificates:
            domain = cert['domain']
            port = cert.get('port', 443)
            
            try:
                # 인증서 정보 조회
                result = subprocess.run([
                    'openssl', 's_client', '-connect', f'{domain}:{port}',
                    '-servername', domain, '-quiet'
                ], input=b'', capture_output=True, timeout=10)
                
                if result.returncode == 0:
                    # 만료일 추출
                    cert_info = subprocess.run([
                        'openssl', 's_client', '-connect', f'{domain}:{port}',
                        '-servername', domain, '-quiet'
                    ], input=b'', capture_output=True, text=True, timeout=10)
                    
                    lines = cert_info.stdout.split('\n')
                    expiry_date = None
                    
                    for line in lines:
                        if 'notAfter' in line:
                            expiry_str = line.split('=')[1].strip()
                            expiry_date = datetime.strptime(expiry_str, '%b %d %H:%M:%S %Y %Z')
                            break
                    
                    if expiry_date:
                        days_until_expiry = (expiry_date - datetime.now()).days
                        
                        if days_until_expiry <= 0:
                            status = 'expired'
                            color = 'red'
                        elif days_until_expiry <= 7:
                            status = 'critical'
                            color = 'red'
                        elif days_until_expiry <= 30:
                            status = 'warning'
                            color = 'orange'
                        else:
                            status = 'ok'
                            color = 'green'
                        
                        status_list.append({
                            'domain': domain,
                            'port': port,
                            'issuer': cert.get('issuer', 'Unknown'),
                            'expiry_date': expiry_date.strftime('%Y-%m-%d'),
                            'days_until_expiry': days_until_expiry,
                            'status': status,
                            'color': color
                        })
                    else:
                        status_list.append({
                            'domain': domain,
                            'port': port,
                            'issuer': cert.get('issuer', 'Unknown'),
                            'expiry_date': 'Unknown',
                            'days_until_expiry': 'Unknown',
                            'status': 'error',
                            'color': 'gray'
                        })
                else:
                    status_list.append({
                        'domain': domain,
                        'port': port,
                        'issuer': cert.get('issuer', 'Unknown'),
                        'expiry_date': 'Connection Failed',
                        'days_until_expiry': 'N/A',
                        'status': 'error',
                        'color': 'gray'
                    })
                    
            except Exception as e:
                status_list.append({
                    'domain': domain,
                    'port': port,
                    'issuer': cert.get('issuer', 'Unknown'),
                    'expiry_date': f'Error: {str(e)}',
                    'days_until_expiry': 'N/A',
                    'status': 'error',
                    'color': 'gray'
                })
        
        return status_list

dashboard = CertificateDashboard()

@app.route('/')
def index():
    return render_template('dashboard.html')

@app.route('/api/status')
def api_status():
    return jsonify(dashboard.get_certificate_status())

@app.route('/api/summary')
def api_summary():
    status_list = dashboard.get_certificate_status()
    
    summary = {
        'total': len(status_list),
        'expired': len([s for s in status_list if s['status'] == 'expired']),
        'critical': len([s for s in status_list if s['status'] == 'critical']),
        'warning': len([s for s in status_list if s['status'] == 'warning']),
        'ok': len([s for s in status_list if s['status'] == 'ok']),
        'error': len([s for s in status_list if s['status'] == 'error'])
    }
    
    return jsonify(summary)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

## 🔮 예측적 관리 시스템

### 머신러닝 기반 예측

#### 인증서 사용 패턴 분석
```python
#!/usr/bin/env python3
# predictive-analytics.py

import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error
import joblib
from datetime import datetime, timedelta

class CertificatePredictor:
    def __init__(self):
        self.model = None
        self.feature_columns = [
            'days_until_expiry',
            'certificate_age',
            'renewal_frequency',
            'domain_length',
            'subdomain_count',
            'issuer_type'
        ]
    
    def load_historical_data(self, data_file='/var/log/cert-monitor/history.csv'):
        """과거 데이터 로드"""
        try:
            df = pd.read_csv(data_file)
            return df
        except FileNotFoundError:
            print(f"과거 데이터 파일을 찾을 수 없습니다: {data_file}")
            return pd.DataFrame()
    
    def extract_features(self, row):
        """특성 추출"""
        features = {}
        
        # 기본 특성
        features['days_until_expiry'] = row['days_until_expiry']
        features['certificate_age'] = row['certificate_age']
        features['renewal_frequency'] = row['renewal_frequency']
        
        # 도메인 특성
        domain = row['domain']
        features['domain_length'] = len(domain)
        features['subdomain_count'] = domain.count('.')
        
        # 발급자 특성
        issuer = row['issuer']
        if 'Let\'s Encrypt' in issuer:
            features['issuer_type'] = 0  # 무료 CA
        elif 'Internal' in issuer:
            features['issuer_type'] = 1  # 내부 CA
        else:
            features['issuer_type'] = 2  # 상용 CA
        
        return features
    
    def train_model(self, df):
        """모델 훈련"""
        if df.empty:
            print("훈련 데이터가 없습니다.")
            return
        
        # 특성 추출
        features = []
        targets = []
        
        for _, row in df.iterrows():
            feature_dict = self.extract_features(row)
            features.append([feature_dict[col] for col in self.feature_columns])
            targets.append(row['days_until_expiry'])
        
        X = np.array(features)
        y = np.array(targets)
        
        # 훈련/테스트 분할
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # 모델 훈련
        self.model = RandomForestRegressor(n_estimators=100, random_state=42)
        self.model.fit(X_train, y_train)
        
        # 모델 평가
        y_pred = self.model.predict(X_test)
        mae = mean_absolute_error(y_test, y_pred)
        print(f"모델 MAE: {mae:.2f}일")
        
        # 모델 저장
        joblib.dump(self.model, '/opt/cert-monitor/model.pkl')
        print("모델 저장 완료")
    
    def predict_expiry_risk(self, certificate_info):
        """만료 위험도 예측"""
        if self.model is None:
            try:
                self.model = joblib.load('/opt/cert-monitor/model.pkl')
            except FileNotFoundError:
                print("훈련된 모델을 찾을 수 없습니다.")
                return None
        
        # 특성 추출
        feature_dict = self.extract_features(certificate_info)
        features = np.array([[feature_dict[col] for col in self.feature_columns]])
        
        # 예측
        predicted_days = self.model.predict(features)[0]
        
        # 위험도 계산
        if predicted_days <= 0:
            risk_level = 'critical'
        elif predicted_days <= 7:
            risk_level = 'high'
        elif predicted_days <= 30:
            risk_level = 'medium'
        else:
            risk_level = 'low'
        
        return {
            'predicted_days': predicted_days,
            'risk_level': risk_level,
            'confidence': 0.85  # 실제로는 모델의 신뢰도 계산
        }
    
    def generate_renewal_recommendations(self, certificates):
        """갱신 권장사항 생성"""
        recommendations = []
        
        for cert in certificates:
            prediction = self.predict_expiry_risk(cert)
            
            if prediction and prediction['risk_level'] in ['high', 'critical']:
                recommendations.append({
                    'domain': cert['domain'],
                    'current_days': cert['days_until_expiry'],
                    'predicted_days': prediction['predicted_days'],
                    'risk_level': prediction['risk_level'],
                    'recommended_action': 'immediate_renewal',
                    'priority': 'high' if prediction['risk_level'] == 'critical' else 'medium'
                })
            elif prediction and prediction['risk_level'] == 'medium':
                recommendations.append({
                    'domain': cert['domain'],
                    'current_days': cert['days_until_expiry'],
                    'predicted_days': prediction['predicted_days'],
                    'risk_level': prediction['risk_level'],
                    'recommended_action': 'schedule_renewal',
                    'priority': 'low'
                })
        
        return recommendations

# 사용 예시
def main():
    predictor = CertificatePredictor()
    
    # 과거 데이터로 모델 훈련
    historical_data = predictor.load_historical_data()
    if not historical_data.empty:
        predictor.train_model(historical_data)
    
    # 현재 인증서에 대한 예측
    current_certificates = [
        {
            'domain': 'example.com',
            'days_until_expiry': 25,
            'certificate_age': 300,
            'renewal_frequency': 2,
            'issuer': "Let's Encrypt"
        }
    ]
    
    recommendations = predictor.generate_renewal_recommendations(current_certificates)
    
    for rec in recommendations:
        print(f"도메인: {rec['domain']}")
        print(f"현재 만료일: {rec['current_days']}일")
        print(f"예측 만료일: {rec['predicted_days']:.1f}일")
        print(f"위험도: {rec['risk_level']}")
        print(f"권장 조치: {rec['recommended_action']}")
        print("---")

if __name__ == '__main__':
    main()
```

## 📚 다음 단계

모니터링 및 알림을 완료했다면 다음 단계로 진행하세요:

- **[실제 시나리오](../scenarios/README.md)** - 복잡한 아키텍처 적용
- **[문제 해결](../troubleshooting/README.md)** - 운영 중 발생하는 문제들
- **[개발 환경](../development/README.md)** - 개발 환경 보안 강화

## 💡 핵심 정리

- **실시간 모니터링**: Prometheus 기반 지속적 인증서 상태 추적
- **다중 채널 알림**: Slack, 이메일, 웹훅을 통한 즉시 알림
- **대시보드**: Grafana와 커스텀 대시보드로 시각화
- **예측적 관리**: 머신러닝을 통한 만료 위험도 예측
- **자동화**: 알림 규칙과 권장사항 자동 생성

---

**다음: [실제 시나리오](../scenarios/README.md)**
