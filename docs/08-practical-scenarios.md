# 8. 실제 시나리오 기반 실습

## 🎯 이 장에서 배울 내용

이 장에서는 실제 개발 환경에서 자주 발생하는 시나리오를 바탕으로 사설 인증서를 활용하는 실습을 진행합니다. 각 시나리오는 단계별로 구성되어 있어 따라하기 쉽게 설계되었습니다.

## 🏢 시나리오 1: 마이크로서비스 아키텍처 개발

### 상황 설명
**회사**: 중견 IT 기업  
**팀**: 백엔드 개발팀 (5명)  
**프로젝트**: 전자상거래 플랫폼 마이크로서비스 개발  
**문제**: 각 서비스 간 HTTPS 통신이 필요하지만 개발 단계에서는 공인 인증서 사용이 비효율적

### 아키텍처 다이어그램

```mermaid
graph TB
    A[API Gateway] --> B[User Service]
    A --> C[Product Service]
    A --> D[Order Service]
    A --> E[Payment Service]
    A --> F[Notification Service]
    
    B --> G[User Database]
    C --> H[Product Database]
    D --> I[Order Database]
    E --> J[Payment Database]
    F --> K[Notification Database]
    
    L[Frontend] --> A
    M[Mobile App] --> A
    
    subgraph "개발 환경"
        A
        B
        C
        D
        E
        F
    end
    
    subgraph "데이터베이스"
        G
        H
        I
        J
        K
    end
```

### 실습 단계

#### 1단계: 프로젝트 구조 설정
```bash
# 프로젝트 디렉토리 생성
mkdir ecommerce-microservices
cd ecommerce-microservices

# 마이크로서비스 디렉토리 구조 생성
mkdir -p services/{api-gateway,user-service,product-service,order-service,payment-service,notification-service}
mkdir -p shared/{certificates,config,scripts}
mkdir -p docker/{nginx,postgres,redis}
```

#### 2단계: 공통 인증서 생성
```bash
# 공통 CA 생성
mkcert -install

# 각 서비스용 인증서 생성
mkcert api-gateway.localhost 127.0.0.1 ::1
mkcert user-service.localhost 127.0.0.1 ::1
mkcert product-service.localhost 127.0.0.1 ::1
mkcert order-service.localhost 127.0.0.1 ::1
mkcert payment-service.localhost 127.0.0.1 ::1
mkcert notification-service.localhost 127.0.0.1 ::1

# 인증서를 공통 디렉토리로 복사
cp *.pem shared/certificates/
cp *-key.pem shared/certificates/
```

#### 3단계: API Gateway 설정 (Nginx)
```nginx
# docker/nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream user-service {
        server user-service:3001;
    }
    
    upstream product-service {
        server product-service:3002;
    }
    
    upstream order-service {
        server order-service:3003;
    }
    
    upstream payment-service {
        server payment-service:3004;
    }
    
    upstream notification-service {
        server notification-service:3005;
    }
    
    # API Gateway HTTPS 설정
    server {
        listen 443 ssl http2;
        server_name api-gateway.localhost;
        
        ssl_certificate /etc/nginx/ssl/api-gateway.localhost.pem;
        ssl_certificate_key /etc/nginx/ssl/api-gateway.localhost-key.pem;
        
        # 보안 헤더
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        
        # 사용자 서비스 프록시
        location /api/users/ {
            proxy_pass https://user-service:3001/;
            proxy_ssl_certificate /etc/nginx/ssl/api-gateway.localhost.pem;
            proxy_ssl_certificate_key /etc/nginx/ssl/api-gateway.localhost-key.pem;
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # 상품 서비스 프록시
        location /api/products/ {
            proxy_pass https://product-service:3002/;
            proxy_ssl_certificate /etc/nginx/ssl/api-gateway.localhost.pem;
            proxy_ssl_certificate_key /etc/nginx/ssl/api-gateway.localhost-key.pem;
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # 주문 서비스 프록시
        location /api/orders/ {
            proxy_pass https://order-service:3003/;
            proxy_ssl_certificate /etc/nginx/ssl/api-gateway.localhost.pem;
            proxy_ssl_certificate_key /etc/nginx/ssl/api-gateway.localhost-key.pem;
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # 결제 서비스 프록시
        location /api/payments/ {
            proxy_pass https://payment-service:3004/;
            proxy_ssl_certificate /etc/nginx/ssl/api-gateway.localhost.pem;
            proxy_ssl_certificate_key /etc/nginx/ssl/api-gateway.localhost-key.pem;
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # 알림 서비스 프록시
        location /api/notifications/ {
            proxy_pass https://notification-service:3005/;
            proxy_ssl_certificate /etc/nginx/ssl/api-gateway.localhost.pem;
            proxy_ssl_certificate_key /etc/nginx/ssl/api-gateway.localhost-key.pem;
            proxy_ssl_verify off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

#### 4단계: 사용자 서비스 구현
```javascript
// services/user-service/server.js
const express = require('express');
const https = require('https');
const fs = require('fs');
const cors = require('cors');

const app = express();
const PORT = 3001;

// 미들웨어 설정
app.use(cors({
    origin: ['https://api-gateway.localhost', 'https://127.0.0.1'],
    credentials: true
}));
app.use(express.json());

// 보안 헤더 미들웨어
app.use((req, res, next) => {
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    next();
});

// 사용자 관련 라우트
app.get('/health', (req, res) => {
    res.json({
        service: 'user-service',
        status: 'healthy',
        timestamp: new Date().toISOString(),
        protocol: req.protocol
    });
});

app.get('/users', (req, res) => {
    res.json([
        { id: 1, name: '홍길동', email: 'hong@example.com', role: 'customer' },
        { id: 2, name: '김철수', email: 'kim@example.com', role: 'admin' }
    ]);
});

app.get('/users/:id', (req, res) => {
    const { id } = req.params;
    res.json({
        id: parseInt(id),
        name: '홍길동',
        email: 'hong@example.com',
        role: 'customer',
        createdAt: '2023-01-01T00:00:00Z'
    });
});

app.post('/users', (req, res) => {
    const { name, email, role } = req.body;
    res.json({
        id: Date.now(),
        name,
        email,
        role: role || 'customer',
        createdAt: new Date().toISOString()
    });
});

// HTTPS 서버 설정
const options = {
    key: fs.readFileSync('../shared/certificates/user-service.localhost-key.pem'),
    cert: fs.readFileSync('../shared/certificates/user-service.localhost.pem')
};

https.createServer(options, app).listen(PORT, () => {
    console.log(`👤 사용자 서비스가 https://user-service.localhost:${PORT}에서 실행 중입니다.`);
});
```

#### 5단계: Docker Compose 설정
```yaml
# docker-compose.yml
version: '3.8'

services:
  # API Gateway
  api-gateway:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./docker/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./shared/certificates:/etc/nginx/ssl
    depends_on:
      - user-service
      - product-service
      - order-service
      - payment-service
      - notification-service

  # 사용자 서비스
  user-service:
    build: ./services/user-service
    ports:
      - "3001:3001"
    volumes:
      - ./shared/certificates:/app/certificates
    environment:
      - NODE_ENV=development
      - PORT=3001
      - DATABASE_URL=postgresql://user:pass@postgres:5432/userdb

  # 상품 서비스
  product-service:
    build: ./services/product-service
    ports:
      - "3002:3002"
    volumes:
      - ./shared/certificates:/app/certificates
    environment:
      - NODE_ENV=development
      - PORT=3002
      - DATABASE_URL=postgresql://user:pass@postgres:5432/productdb

  # 주문 서비스
  order-service:
    build: ./services/order-service
    ports:
      - "3003:3003"
    volumes:
      - ./shared/certificates:/app/certificates
    environment:
      - NODE_ENV=development
      - PORT=3003
      - DATABASE_URL=postgresql://user:pass@postgres:5432/orderdb

  # 결제 서비스
  payment-service:
    build: ./services/payment-service
    ports:
      - "3004:3004"
    volumes:
      - ./shared/certificates:/app/certificates
    environment:
      - NODE_ENV=development
      - PORT=3004
      - DATABASE_URL=postgresql://user:pass@postgres:5432/paymentdb

  # 알림 서비스
  notification-service:
    build: ./services/notification-service
    ports:
      - "3005:3005"
    volumes:
      - ./shared/certificates:/app/certificates
    environment:
      - NODE_ENV=development
      - PORT=3005
      - DATABASE_URL=postgresql://user:pass@postgres:5432/notificationdb

  # 데이터베이스
  postgres:
    image: postgres:15
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=userdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./shared/certificates:/etc/ssl/certs
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

#### 6단계: 테스트 및 검증
```bash
# 서비스 시작
docker-compose up -d

# API Gateway 테스트
curl -k https://api-gateway.localhost/api/users/health

# 개별 서비스 테스트
curl -k https://user-service.localhost:3001/health
curl -k https://product-service.localhost:3002/health
curl -k https://order-service.localhost:3003/health
```

## 🏭 시나리오 2: IoT 디바이스 시뮬레이션

### 상황 설명
**회사**: 스마트홈 제품 개발사  
**팀**: IoT 개발팀 (3명)  
**프로젝트**: 스마트홈 디바이스 관리 시스템  
**문제**: 다양한 IoT 디바이스와의 안전한 통신을 위한 인증서 관리

### IoT 아키텍처 다이어그램

```mermaid
graph TB
    A[IoT Hub] --> B[Smart Thermostat]
    A --> C[Smart Light]
    A --> D[Smart Door Lock]
    A --> E[Security Camera]
    A --> F[Smart Speaker]
    
    G[Mobile App] --> A
    H[Web Dashboard] --> A
    
    A --> I[Cloud API]
    I --> J[Database]
    I --> K[Analytics Service]
    
    subgraph "스마트홈 디바이스"
        B
        C
        D
        E
        F
    end
    
    subgraph "관리 시스템"
        A
        I
        J
        K
    end
    
    subgraph "사용자 인터페이스"
        G
        H
    end
```

### 실습 단계

#### 1단계: IoT Hub 서버 구현
```javascript
// iot-hub/server.js
const express = require('express');
const https = require('https');
const fs = require('fs');
const WebSocket = require('ws');
const cors = require('cors');

const app = express();
const PORT = 8443;

// 미들웨어 설정
app.use(cors({
    origin: ['https://localhost', 'https://127.0.0.1'],
    credentials: true
}));
app.use(express.json());

// 디바이스 등록 및 상태 관리
const devices = new Map();
const deviceTypes = {
    'thermostat': { name: '스마트 온도조절기', status: 'online' },
    'light': { name: '스마트 조명', status: 'online' },
    'doorlock': { name: '스마트 도어락', status: 'online' },
    'camera': { name: '보안 카메라', status: 'online' },
    'speaker': { name: '스마트 스피커', status: 'online' }
};

// 디바이스 등록 API
app.post('/api/devices/register', (req, res) => {
    const { deviceId, deviceType, location, capabilities } = req.body;
    
    if (!deviceTypes[deviceType]) {
        return res.status(400).json({ error: '지원되지 않는 디바이스 타입입니다.' });
    }
    
    const device = {
        id: deviceId,
        type: deviceType,
        name: deviceTypes[deviceType].name,
        location,
        capabilities,
        status: 'online',
        lastSeen: new Date().toISOString(),
        registeredAt: new Date().toISOString()
    };
    
    devices.set(deviceId, device);
    
    console.log(`📱 디바이스 등록: ${device.name} (${deviceId})`);
    
    res.json({
        success: true,
        device,
        message: '디바이스가 성공적으로 등록되었습니다.'
    });
});

// 디바이스 상태 업데이트
app.put('/api/devices/:deviceId/status', (req, res) => {
    const { deviceId } = req.params;
    const { status, data } = req.body;
    
    if (!devices.has(deviceId)) {
        return res.status(404).json({ error: '디바이스를 찾을 수 없습니다.' });
    }
    
    const device = devices.get(deviceId);
    device.status = status;
    device.lastSeen = new Date().toISOString();
    device.data = data;
    
    devices.set(deviceId, device);
    
    console.log(`📊 디바이스 상태 업데이트: ${device.name} - ${status}`);
    
    res.json({ success: true, device });
});

// 디바이스 제어
app.post('/api/devices/:deviceId/control', (req, res) => {
    const { deviceId } = req.params;
    const { action, parameters } = req.body;
    
    if (!devices.has(deviceId)) {
        return res.status(404).json({ error: '디바이스를 찾을 수 없습니다.' });
    }
    
    const device = devices.get(deviceId);
    
    console.log(`🎮 디바이스 제어: ${device.name} - ${action}`, parameters);
    
    // 실제 디바이스 제어 로직 (시뮬레이션)
    const result = {
        success: true,
        deviceId,
        action,
        parameters,
        timestamp: new Date().toISOString(),
        response: `디바이스 ${device.name}에서 ${action} 명령이 실행되었습니다.`
    };
    
    res.json(result);
});

// 디바이스 목록 조회
app.get('/api/devices', (req, res) => {
    const deviceList = Array.from(devices.values());
    res.json({
        devices: deviceList,
        total: deviceList.length,
        online: deviceList.filter(d => d.status === 'online').length
    });
});

// 디바이스 상세 정보
app.get('/api/devices/:deviceId', (req, res) => {
    const { deviceId } = req.params;
    
    if (!devices.has(deviceId)) {
        return res.status(404).json({ error: '디바이스를 찾을 수 없습니다.' });
    }
    
    res.json(devices.get(deviceId));
});

// HTTPS 서버 설정
const options = {
    key: fs.readFileSync('iot-hub.localhost-key.pem'),
    cert: fs.readFileSync('iot-hub.localhost.pem')
};

const server = https.createServer(options, app);

// WebSocket 서버 설정 (실시간 통신)
const wss = new WebSocket.Server({ server });

wss.on('connection', (ws) => {
    console.log('🔌 WebSocket 연결됨');
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            console.log('📨 WebSocket 메시지 수신:', data);
            
            // 디바이스 데이터 브로드캐스트
            wss.clients.forEach((client) => {
                if (client.readyState === WebSocket.OPEN) {
                    client.send(JSON.stringify({
                        type: 'device_update',
                        data,
                        timestamp: new Date().toISOString()
                    }));
                }
            });
        } catch (error) {
            console.error('WebSocket 메시지 파싱 오류:', error);
        }
    });
    
    ws.on('close', () => {
        console.log('🔌 WebSocket 연결 종료');
    });
});

server.listen(PORT, () => {
    console.log(`🏠 IoT Hub가 https://iot-hub.localhost:${PORT}에서 실행 중입니다.`);
});
```

#### 2단계: 스마트 디바이스 시뮬레이터
```javascript
// device-simulator/thermostat.js
const https = require('https');
const fs = require('fs');

class SmartThermostat {
    constructor(deviceId, hubUrl) {
        this.deviceId = deviceId;
        this.hubUrl = hubUrl;
        this.temperature = 22;
        this.targetTemperature = 22;
        this.mode = 'auto'; // auto, heat, cool, off
        this.status = 'online';
    }
    
    // IoT Hub에 디바이스 등록
    async register() {
        const deviceData = {
            deviceId: this.deviceId,
            deviceType: 'thermostat',
            location: '거실',
            capabilities: ['temperature_control', 'mode_control', 'schedule']
        };
        
        try {
            const response = await this.makeRequest('POST', '/api/devices/register', deviceData);
            console.log('✅ 온도조절기 등록 완료:', response.device.name);
            return response;
        } catch (error) {
            console.error('❌ 디바이스 등록 실패:', error.message);
        }
    }
    
    // 상태 업데이트
    async updateStatus() {
        const statusData = {
            status: this.status,
            data: {
                temperature: this.temperature,
                targetTemperature: this.targetTemperature,
                mode: this.mode,
                humidity: 45 + Math.random() * 10
            }
        };
        
        try {
            await this.makeRequest('PUT', `/api/devices/${this.deviceId}/status`, statusData);
            console.log(`🌡️ 온도조절기 상태 업데이트: ${this.temperature}°C (목표: ${this.targetTemperature}°C)`);
        } catch (error) {
            console.error('❌ 상태 업데이트 실패:', error.message);
        }
    }
    
    // 온도 조절
    setTemperature(targetTemp) {
        this.targetTemperature = targetTemp;
        console.log(`🎯 목표 온도 설정: ${targetTemp}°C`);
        this.updateStatus();
    }
    
    // 모드 변경
    setMode(mode) {
        this.mode = mode;
        console.log(`🔄 모드 변경: ${mode}`);
        this.updateStatus();
    }
    
    // HTTP 요청 헬퍼
    makeRequest(method, path, data = null) {
        return new Promise((resolve, reject) => {
            const options = {
                hostname: 'iot-hub.localhost',
                port: 8443,
                path: path,
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                rejectUnauthorized: false // 개발 환경에서만 사용
            };
            
            const req = https.request(options, (res) => {
                let responseData = '';
                
                res.on('data', (chunk) => {
                    responseData += chunk;
                });
                
                res.on('end', () => {
                    try {
                        const result = JSON.parse(responseData);
                        resolve(result);
                    } catch (error) {
                        reject(new Error('응답 파싱 실패'));
                    }
                });
            });
            
            req.on('error', (error) => {
                reject(error);
            });
            
            if (data) {
                req.write(JSON.stringify(data));
            }
            
            req.end();
        });
    }
    
    // 시뮬레이션 시작
    startSimulation() {
        console.log('🏠 스마트 온도조절기 시뮬레이션 시작');
        
        // 초기 등록
        this.register();
        
        // 주기적 상태 업데이트 (30초마다)
        setInterval(() => {
            // 온도 변화 시뮬레이션
            const change = (Math.random() - 0.5) * 0.5;
            this.temperature += change;
            
            // 목표 온도에 따라 자동 조절
            if (this.mode === 'auto') {
                if (this.temperature < this.targetTemperature - 1) {
                    console.log('🔥 난방 가동');
                } else if (this.temperature > this.targetTemperature + 1) {
                    console.log('❄️ 냉방 가동');
                }
            }
            
            this.updateStatus();
        }, 30000);
        
        // 사용자 명령 시뮬레이션 (1분마다)
        setInterval(() => {
            const commands = [
                () => this.setTemperature(20 + Math.floor(Math.random() * 10)),
                () => this.setMode(['auto', 'heat', 'cool', 'off'][Math.floor(Math.random() * 4)])
            ];
            
            const randomCommand = commands[Math.floor(Math.random() * commands.length)];
            randomCommand();
        }, 60000);
    }
}

// 시뮬레이터 실행
const thermostat = new SmartThermostat('thermostat-001', 'https://iot-hub.localhost:8443');
thermostat.startSimulation();
```

#### 3단계: 웹 대시보드 구현
```html
<!-- dashboard/index.html -->
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>스마트홈 대시보드</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .device-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .device-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .device-status { padding: 4px 8px; border-radius: 4px; color: white; font-weight: bold; }
        .status-online { background: #28a745; }
        .status-offline { background: #dc3545; }
        .control-panel { margin-top: 15px; }
        .control-button { background: #007bff; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; margin: 5px; }
        .control-button:hover { background: #0056b3; }
        .temperature-display { font-size: 24px; font-weight: bold; color: #007bff; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏠 스마트홈 대시보드</h1>
            <p>실시간 디바이스 모니터링 및 제어</p>
        </div>
        
        <div class="device-grid" id="deviceGrid">
            <!-- 디바이스 카드들이 여기에 동적으로 추가됩니다 -->
        </div>
    </div>
    
    <script>
        class SmartHomeDashboard {
            constructor() {
                this.devices = [];
                this.ws = null;
                this.init();
            }
            
            async init() {
                await this.loadDevices();
                this.connectWebSocket();
                this.startAutoRefresh();
            }
            
            async loadDevices() {
                try {
                    const response = await fetch('https://iot-hub.localhost:8443/api/devices', {
                        method: 'GET',
                        mode: 'cors'
                    });
                    const data = await response.json();
                    this.devices = data.devices;
                    this.renderDevices();
                } catch (error) {
                    console.error('디바이스 로드 실패:', error);
                }
            }
            
            renderDevices() {
                const grid = document.getElementById('deviceGrid');
                grid.innerHTML = '';
                
                this.devices.forEach(device => {
                    const card = this.createDeviceCard(device);
                    grid.appendChild(card);
                });
            }
            
            createDeviceCard(device) {
                const card = document.createElement('div');
                card.className = 'device-card';
                card.innerHTML = `
                    <h3>${device.name}</h3>
                    <p><strong>위치:</strong> ${device.location}</p>
                    <p><strong>상태:</strong> <span class="device-status status-${device.status}">${device.status}</span></p>
                    <p><strong>마지막 연결:</strong> ${new Date(device.lastSeen).toLocaleString()}</p>
                    ${this.createDeviceControls(device)}
                `;
                return card;
            }
            
            createDeviceControls(device) {
                if (device.type === 'thermostat') {
                    return `
                        <div class="control-panel">
                            <div class="temperature-display">${device.data?.temperature || 'N/A'}°C</div>
                            <p>목표 온도: ${device.data?.targetTemperature || 'N/A'}°C</p>
                            <button class="control-button" onclick="dashboard.setTemperature('${device.id}', 20)">20°C</button>
                            <button class="control-button" onclick="dashboard.setTemperature('${device.id}', 22)">22°C</button>
                            <button class="control-button" onclick="dashboard.setTemperature('${device.id}', 24)">24°C</button>
                        </div>
                    `;
                } else if (device.type === 'light') {
                    return `
                        <div class="control-panel">
                            <button class="control-button" onclick="dashboard.controlDevice('${device.id}', 'turn_on')">켜기</button>
                            <button class="control-button" onclick="dashboard.controlDevice('${device.id}', 'turn_off')">끄기</button>
                        </div>
                    `;
                }
                return '';
            }
            
            async setTemperature(deviceId, temperature) {
                try {
                    const response = await fetch(`https://iot-hub.localhost:8443/api/devices/${deviceId}/control`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            action: 'set_temperature',
                            parameters: { temperature: parseInt(temperature) }
                        }),
                        mode: 'cors'
                    });
                    const result = await response.json();
                    console.log('온도 설정 결과:', result);
                    this.loadDevices(); // 디바이스 목록 새로고침
                } catch (error) {
                    console.error('온도 설정 실패:', error);
                }
            }
            
            async controlDevice(deviceId, action) {
                try {
                    const response = await fetch(`https://iot-hub.localhost:8443/api/devices/${deviceId}/control`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ action, parameters: {} }),
                        mode: 'cors'
                    });
                    const result = await response.json();
                    console.log('디바이스 제어 결과:', result);
                    this.loadDevices(); // 디바이스 목록 새로고침
                } catch (error) {
                    console.error('디바이스 제어 실패:', error);
                }
            }
            
            connectWebSocket() {
                try {
                    this.ws = new WebSocket('wss://iot-hub.localhost:8443');
                    
                    this.ws.onopen = () => {
                        console.log('WebSocket 연결됨');
                    };
                    
                    this.ws.onmessage = (event) => {
                        const data = JSON.parse(event.data);
                        if (data.type === 'device_update') {
                            console.log('디바이스 업데이트:', data);
                            this.loadDevices(); // 디바이스 목록 새로고침
                        }
                    };
                    
                    this.ws.onclose = () => {
                        console.log('WebSocket 연결 종료');
                        // 5초 후 재연결 시도
                        setTimeout(() => this.connectWebSocket(), 5000);
                    };
                } catch (error) {
                    console.error('WebSocket 연결 실패:', error);
                }
            }
            
            startAutoRefresh() {
                // 30초마다 디바이스 목록 새로고침
                setInterval(() => {
                    this.loadDevices();
                }, 30000);
            }
        }
        
        // 대시보드 초기화
        const dashboard = new SmartHomeDashboard();
    </script>
</body>
</html>
```

## 🏥 시나리오 3: 의료기기 통신 시스템

### 상황 설명
**회사**: 의료기기 제조사  
**팀**: 의료기기 개발팀 (4명)  
**프로젝트**: 병원 내 의료기기 통합 관리 시스템  
**문제**: 환자 데이터 보호를 위한 강력한 암호화 통신 필요

### 의료기기 아키텍처 다이어그램

```mermaid
graph TB
    A[의료기기 게이트웨이] --> B[심전도 모니터]
    A --> C[혈압계]
    A --> D[산소포화도 측정기]
    A --> E[인슐린 펌프]
    A --> F[체온계]
    
    G[의료진 태블릿] --> A
    H[간호사 스테이션] --> A
    
    A --> I[병원 정보 시스템]
    I --> J[환자 데이터베이스]
    I --> K[의료진 포털]
    
    subgraph "의료기기"
        B
        C
        D
        E
        F
    end
    
    subgraph "관리 시스템"
        A
        I
        J
        K
    end
    
    subgraph "사용자 인터페이스"
        G
        H
    end
```

### 실습 단계

#### 1단계: 의료기기 게이트웨이 구현
```javascript
// medical-gateway/server.js
const express = require('express');
const https = require('https');
const fs = require('fs');
const crypto = require('crypto');
const cors = require('cors');

const app = express();
const PORT = 8443;

// 미들웨어 설정
app.use(cors({
    origin: ['https://localhost', 'https://127.0.0.1'],
    credentials: true
}));
app.use(express.json());

// 의료기기 등록 및 데이터 관리
const medicalDevices = new Map();
const patientData = new Map();

// 의료기기 등록
app.post('/api/devices/register', (req, res) => {
    const { deviceId, deviceType, patientId, location, capabilities } = req.body;
    
    const device = {
        id: deviceId,
        type: deviceType,
        patientId,
        location,
        capabilities,
        status: 'online',
        lastSeen: new Date().toISOString(),
        registeredAt: new Date().toISOString(),
        encryptionKey: crypto.randomBytes(32).toString('hex') // 디바이스별 암호화 키
    };
    
    medicalDevices.set(deviceId, device);
    
    console.log(`🏥 의료기기 등록: ${deviceType} (환자: ${patientId})`);
    
    res.json({
        success: true,
        device,
        encryptionKey: device.encryptionKey
    });
});

// 의료 데이터 수신 (암호화된 데이터)
app.post('/api/devices/:deviceId/data', (req, res) => {
    const { deviceId } = req.params;
    const { encryptedData, timestamp } = req.body;
    
    if (!medicalDevices.has(deviceId)) {
        return res.status(404).json({ error: '의료기기를 찾을 수 없습니다.' });
    }
    
    const device = medicalDevices.get(deviceId);
    
    try {
        // 데이터 복호화 (실제로는 더 강력한 암호화 사용)
        const decryptedData = this.decryptData(encryptedData, device.encryptionKey);
        
        // 환자 데이터 저장
        if (!patientData.has(device.patientId)) {
            patientData.set(device.patientId, []);
        }
        
        const patientRecord = {
            deviceId,
            deviceType: device.type,
            data: decryptedData,
            timestamp: timestamp || new Date().toISOString(),
            receivedAt: new Date().toISOString()
        };
        
        patientData.get(device.patientId).push(patientRecord);
        
        console.log(`📊 의료 데이터 수신: ${device.type} - 환자 ${device.patientId}`);
        
        res.json({
            success: true,
            message: '의료 데이터가 성공적으로 저장되었습니다.'
        });
        
    } catch (error) {
        console.error('데이터 복호화 실패:', error);
        res.status(400).json({ error: '데이터 복호화에 실패했습니다.' });
    }
});

// 환자 데이터 조회 (의료진만 접근 가능)
app.get('/api/patients/:patientId/data', (req, res) => {
    const { patientId } = req.params;
    const { deviceType, startDate, endDate } = req.query;
    
    if (!patientData.has(patientId)) {
        return res.status(404).json({ error: '환자 데이터를 찾을 수 없습니다.' });
    }
    
    let data = patientData.get(patientId);
    
    // 필터링
    if (deviceType) {
        data = data.filter(record => record.deviceType === deviceType);
    }
    
    if (startDate) {
        data = data.filter(record => new Date(record.timestamp) >= new Date(startDate));
    }
    
    if (endDate) {
        data = data.filter(record => new Date(record.timestamp) <= new Date(endDate));
    }
    
    // 최신 데이터부터 정렬
    data.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    res.json({
        patientId,
        data,
        total: data.length,
        retrievedAt: new Date().toISOString()
    });
});

// 의료기기 상태 모니터링
app.get('/api/devices/status', (req, res) => {
    const deviceList = Array.from(medicalDevices.values());
    const onlineDevices = deviceList.filter(d => d.status === 'online');
    const offlineDevices = deviceList.filter(d => d.status === 'offline');
    
    res.json({
        total: deviceList.length,
        online: onlineDevices.length,
        offline: offlineDevices.length,
        devices: deviceList
    });
});

// 데이터 암호화 함수
encryptData(data, key) {
    const cipher = crypto.createCipher('aes-256-cbc', key);
    let encrypted = cipher.update(JSON.stringify(data), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return encrypted;
}

// 데이터 복호화 함수
decryptData(encryptedData, key) {
    const decipher = crypto.createDecipher('aes-256-cbc', key);
    let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return JSON.parse(decrypted);
}

// HTTPS 서버 설정
const options = {
    key: fs.readFileSync('medical-gateway.localhost-key.pem'),
    cert: fs.readFileSync('medical-gateway.localhost.pem')
};

https.createServer(options, app).listen(PORT, () => {
    console.log(`🏥 의료기기 게이트웨이가 https://medical-gateway.localhost:${PORT}에서 실행 중입니다.`);
});
```

#### 2단계: 심전도 모니터 시뮬레이터
```javascript
// device-simulator/ecg-monitor.js
const https = require('https');
const crypto = require('crypto');

class ECGMonitor {
    constructor(deviceId, patientId, gatewayUrl) {
        this.deviceId = deviceId;
        this.patientId = patientId;
        this.gatewayUrl = gatewayUrl;
        this.encryptionKey = null;
        this.isRunning = false;
        this.heartRate = 72; // 기본 심박수
    }
    
    // 의료기기 등록
    async register() {
        const deviceData = {
            deviceId: this.deviceId,
            deviceType: 'ecg_monitor',
            patientId: this.patientId,
            location: '병실 101',
            capabilities: ['heart_rate_monitoring', 'ecg_recording', 'alarm_system']
        };
        
        try {
            const response = await this.makeRequest('POST', '/api/devices/register', deviceData);
            this.encryptionKey = response.encryptionKey;
            console.log('✅ 심전도 모니터 등록 완료');
            return response;
        } catch (error) {
            console.error('❌ 의료기기 등록 실패:', error.message);
        }
    }
    
    // 심전도 데이터 생성 (시뮬레이션)
    generateECGData() {
        const timestamp = new Date().toISOString();
        const baseRate = this.heartRate;
        const variation = (Math.random() - 0.5) * 10; // ±5 BPM 변동
        const currentRate = Math.max(40, Math.min(200, baseRate + variation));
        
        // 심전도 파형 데이터 생성 (간단한 시뮬레이션)
        const ecgWaveform = [];
        for (let i = 0; i < 100; i++) {
            const time = i * 0.01; // 10ms 간격
            const wave = Math.sin(2 * Math.PI * currentRate / 60 * time) * 0.5 + 
                        Math.sin(2 * Math.PI * currentRate / 30 * time) * 0.3 +
                        (Math.random() - 0.5) * 0.1; // 노이즈
            ecgWaveform.push(wave);
        }
        
        return {
            heartRate: Math.round(currentRate),
            ecgWaveform,
            timestamp,
            quality: Math.random() > 0.1 ? 'good' : 'poor', // 90% 양질
            alarm: currentRate > 120 || currentRate < 50 ? 'high' : 'normal'
        };
    }
    
    // 데이터 전송
    async sendData() {
        if (!this.encryptionKey) {
            console.error('암호화 키가 없습니다.');
            return;
        }
        
        const data = this.generateECGData();
        const encryptedData = this.encryptData(data, this.encryptionKey);
        
        try {
            await this.makeRequest('POST', `/api/devices/${this.deviceId}/data`, {
                encryptedData,
                timestamp: data.timestamp
            });
            
            console.log(`💓 심전도 데이터 전송: 심박수 ${data.heartRate} BPM (알람: ${data.alarm})`);
            
            // 알람 상태 확인
            if (data.alarm === 'high') {
                console.log('🚨 심박수 이상 감지! 의료진에게 알림 필요');
            }
            
        } catch (error) {
            console.error('❌ 데이터 전송 실패:', error.message);
        }
    }
    
    // 데이터 암호화
    encryptData(data, key) {
        const cipher = crypto.createCipher('aes-256-cbc', key);
        let encrypted = cipher.update(JSON.stringify(data), 'utf8', 'hex');
        encrypted += cipher.final('hex');
        return encrypted;
    }
    
    // HTTP 요청 헬퍼
    makeRequest(method, path, data = null) {
        return new Promise((resolve, reject) => {
            const options = {
                hostname: 'medical-gateway.localhost',
                port: 8443,
                path: path,
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                rejectUnauthorized: false
            };
            
            const req = https.request(options, (res) => {
                let responseData = '';
                
                res.on('data', (chunk) => {
                    responseData += chunk;
                });
                
                res.on('end', () => {
                    try {
                        const result = JSON.parse(responseData);
                        resolve(result);
                    } catch (error) {
                        reject(new Error('응답 파싱 실패'));
                    }
                });
            });
            
            req.on('error', (error) => {
                reject(error);
            });
            
            if (data) {
                req.write(JSON.stringify(data));
            }
            
            req.end();
        });
    }
    
    // 모니터링 시작
    startMonitoring() {
        console.log('🏥 심전도 모니터 시뮬레이션 시작');
        
        // 초기 등록
        this.register();
        
        // 5초마다 데이터 전송
        setInterval(() => {
            this.sendData();
        }, 5000);
        
        // 심박수 변화 시뮬레이션 (30초마다)
        setInterval(() => {
            const change = (Math.random() - 0.5) * 20;
            this.heartRate = Math.max(40, Math.min(200, this.heartRate + change));
            console.log(`💓 심박수 변화: ${this.heartRate} BPM`);
        }, 30000);
    }
}

// 시뮬레이터 실행
const ecgMonitor = new ECGMonitor('ecg-001', 'patient-001', 'https://medical-gateway.localhost:8443');
ecgMonitor.startMonitoring();
```

#### 3단계: 의료진 대시보드
```html
<!-- medical-dashboard/index.html -->
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>의료진 대시보드</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f8f9fa; }
        .container { max-width: 1400px; margin: 0 auto; }
        .header { background: #dc3545; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .patient-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; }
        .patient-card { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border-left: 4px solid #dc3545; }
        .vital-signs { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; margin-top: 15px; }
        .vital-item { text-align: center; padding: 10px; background: #f8f9fa; border-radius: 4px; }
        .vital-value { font-size: 24px; font-weight: bold; color: #dc3545; }
        .vital-label { font-size: 12px; color: #666; }
        .alarm { background: #fff3cd; border: 1px solid #ffeaa7; padding: 10px; border-radius: 4px; margin-top: 10px; }
        .alarm-high { background: #f8d7da; border-color: #f5c6cb; }
        .status-indicator { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 5px; }
        .status-online { background: #28a745; }
        .status-offline { background: #dc3545; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏥 의료진 대시보드</h1>
            <p>실시간 환자 모니터링 및 의료기기 관리</p>
        </div>
        
        <div class="patient-grid" id="patientGrid">
            <!-- 환자 카드들이 여기에 동적으로 추가됩니다 -->
        </div>
    </div>
    
    <script>
        class MedicalDashboard {
            constructor() {
                this.patients = new Map();
                this.devices = new Map();
                this.init();
            }
            
            async init() {
                await this.loadDevices();
                await this.loadPatientData();
                this.startAutoRefresh();
            }
            
            async loadDevices() {
                try {
                    const response = await fetch('https://medical-gateway.localhost:8443/api/devices/status', {
                        method: 'GET',
                        mode: 'cors'
                    });
                    const data = await response.json();
                    
                    data.devices.forEach(device => {
                        this.devices.set(device.id, device);
                    });
                    
                    console.log('의료기기 상태 로드 완료:', data);
                } catch (error) {
                    console.error('의료기기 상태 로드 실패:', error);
                }
            }
            
            async loadPatientData() {
                // 실제로는 환자 목록을 먼저 가져와야 하지만, 시뮬레이션을 위해 하드코딩
                const patientIds = ['patient-001'];
                
                for (const patientId of patientIds) {
                    try {
                        const response = await fetch(`https://medical-gateway.localhost:8443/api/patients/${patientId}/data`, {
                            method: 'GET',
                            mode: 'cors'
                        });
                        const data = await response.json();
                        
                        this.patients.set(patientId, {
                            id: patientId,
                            name: '홍길동',
                            room: '101',
                            data: data.data.slice(0, 10) // 최근 10개 데이터만
                        });
                        
                    } catch (error) {
                        console.error(`환자 ${patientId} 데이터 로드 실패:`, error);
                    }
                }
                
                this.renderPatients();
            }
            
            renderPatients() {
                const grid = document.getElementById('patientGrid');
                grid.innerHTML = '';
                
                this.patients.forEach(patient => {
                    const card = this.createPatientCard(patient);
                    grid.appendChild(card);
                });
            }
            
            createPatientCard(patient) {
                const latestData = patient.data[0];
                const device = Array.from(this.devices.values()).find(d => d.patientId === patient.id);
                
                const card = document.createElement('div');
                card.className = 'patient-card';
                card.innerHTML = `
                    <h3>👤 ${patient.name} (${patient.room}호)</h3>
                    <p><strong>의료기기:</strong> 
                        <span class="status-indicator status-${device?.status || 'offline'}"></span>
                        ${device?.type || 'N/A'}
                    </p>
                    <p><strong>마지막 업데이트:</strong> ${latestData ? new Date(latestData.timestamp).toLocaleString() : 'N/A'}</p>
                    
                    ${latestData ? this.createVitalSignsDisplay(latestData.data) : '<p>데이터 없음</p>'}
                    
                    ${latestData?.data?.alarm === 'high' ? '<div class="alarm alarm-high">🚨 심박수 이상 감지!</div>' : ''}
                `;
                return card;
            }
            
            createVitalSignsDisplay(data) {
                return `
                    <div class="vital-signs">
                        <div class="vital-item">
                            <div class="vital-value">${data.heartRate || 'N/A'}</div>
                            <div class="vital-label">심박수 (BPM)</div>
                        </div>
                        <div class="vital-item">
                            <div class="vital-value">${data.quality || 'N/A'}</div>
                            <div class="vital-label">신호 품질</div>
                        </div>
                        <div class="vital-item">
                            <div class="vital-value">${data.alarm || 'N/A'}</div>
                            <div class="vital-label">알람 상태</div>
                        </div>
                    </div>
                `;
            }
            
            startAutoRefresh() {
                // 10초마다 데이터 새로고침
                setInterval(() => {
                    this.loadDevices();
                    this.loadPatientData();
                }, 10000);
            }
        }
        
        // 대시보드 초기화
        const dashboard = new MedicalDashboard();
    </script>
</body>
</html>
```

## 🧪 시나리오 4: 실험실 장비 통합 시스템

### 상황 설명
**회사**: 바이오테크 연구소  
**팀**: 연구개발팀 (6명)  
**프로젝트**: 실험실 장비 데이터 수집 및 분석 시스템  
**문제**: 다양한 실험 장비의 데이터를 안전하게 수집하고 분석

### 실험실 아키텍처 다이어그램

```mermaid
graph TB
    A[실험실 데이터 허브] --> B[현미경]
    A --> C[분석기]
    A --> D[온도조절기]
    A --> E[pH 측정기]
    A --> F[분광계]
    
    G[연구원 워크스테이션] --> A
    H[데이터 분석 서버] --> A
    
    A --> I[클라우드 스토리지]
    I --> J[데이터베이스]
    I --> K[AI 분석 엔진]
    
    subgraph "실험 장비"
        B
        C
        D
        E
        F
    end
    
    subgraph "데이터 처리"
        A
        H
        I
        J
        K
    end
    
    subgraph "연구 환경"
        G
    end
```

### 실습 단계

#### 1단계: 실험실 데이터 허브 구현
```javascript
// lab-hub/server.js
const express = require('express');
const https = require('https');
const fs = require('fs');
const multer = require('multer');
const path = require('path');

const app = express();
const PORT = 8443;

// 미들웨어 설정
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// 파일 업로드 설정
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// 실험 데이터 저장소
const experiments = new Map();
const equipmentData = new Map();

// 실험 등록
app.post('/api/experiments', (req, res) => {
    const { experimentId, name, researcher, description, equipment } = req.body;
    
    const experiment = {
        id: experimentId,
        name,
        researcher,
        description,
        equipment,
        status: 'active',
        createdAt: new Date().toISOString(),
        dataPoints: []
    };
    
    experiments.set(experimentId, experiment);
    
    console.log(`🧪 실험 등록: ${name} (연구원: ${researcher})`);
    
    res.json({
        success: true,
        experiment,
        message: '실험이 성공적으로 등록되었습니다.'
    });
});

// 장비 데이터 수신
app.post('/api/equipment/:equipmentId/data', (req, res) => {
    const { equipmentId } = req.params;
    const { experimentId, dataType, data, timestamp, metadata } = req.body;
    
    if (!experiments.has(experimentId)) {
        return res.status(404).json({ error: '실험을 찾을 수 없습니다.' });
    }
    
    const dataPoint = {
        equipmentId,
        experimentId,
        dataType,
        data,
        timestamp: timestamp || new Date().toISOString(),
        metadata: metadata || {},
        receivedAt: new Date().toISOString()
    };
    
    // 실험에 데이터 포인트 추가
    const experiment = experiments.get(experimentId);
    experiment.dataPoints.push(dataPoint);
    experiments.set(experimentId, experiment);
    
    // 장비별 데이터 저장
    if (!equipmentData.has(equipmentId)) {
        equipmentData.set(equipmentId, []);
    }
    equipmentData.get(equipmentId).push(dataPoint);
    
    console.log(`📊 장비 데이터 수신: ${equipmentId} - ${dataType}`);
    
    res.json({
        success: true,
        message: '데이터가 성공적으로 저장되었습니다.',
        dataPoint
    });
});

// 이미지 데이터 업로드
app.post('/api/equipment/:equipmentId/image', upload.single('image'), (req, res) => {
    const { equipmentId } = req.params;
    const { experimentId, description } = req.body;
    
    if (!req.file) {
        return res.status(400).json({ error: '이미지 파일이 없습니다.' });
    }
    
    const imageData = {
        equipmentId,
        experimentId,
        filename: req.file.filename,
        originalName: req.file.originalname,
        path: req.file.path,
        size: req.file.size,
        description,
        uploadedAt: new Date().toISOString()
    };
    
    console.log(`📸 이미지 업로드: ${req.file.originalname} (${req.file.size} bytes)`);
    
    res.json({
        success: true,
        image: imageData,
        message: '이미지가 성공적으로 업로드되었습니다.'
    });
});

// 실험 데이터 조회
app.get('/api/experiments/:experimentId/data', (req, res) => {
    const { experimentId } = req.params;
    const { dataType, startDate, endDate, limit } = req.query;
    
    if (!experiments.has(experimentId)) {
        return res.status(404).json({ error: '실험을 찾을 수 없습니다.' });
    }
    
    let data = experiments.get(experimentId).dataPoints;
    
    // 필터링
    if (dataType) {
        data = data.filter(point => point.dataType === dataType);
    }
    
    if (startDate) {
        data = data.filter(point => new Date(point.timestamp) >= new Date(startDate));
    }
    
    if (endDate) {
        data = data.filter(point => new Date(point.timestamp) <= new Date(endDate));
    }
    
    // 최신 데이터부터 정렬
    data.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    
    // 제한 적용
    if (limit) {
        data = data.slice(0, parseInt(limit));
    }
    
    res.json({
        experimentId,
        data,
        total: data.length,
        retrievedAt: new Date().toISOString()
    });
});

// 실험 목록 조회
app.get('/api/experiments', (req, res) => {
    const experimentList = Array.from(experiments.values());
    
    res.json({
        experiments: experimentList,
        total: experimentList.length,
        active: experimentList.filter(e => e.status === 'active').length
    });
});

// 데이터 분석 요청
app.post('/api/experiments/:experimentId/analyze', (req, res) => {
    const { experimentId } = req.params;
    const { analysisType, parameters } = req.body;
    
    if (!experiments.has(experimentId)) {
        return res.status(404).json({ error: '실험을 찾을 수 없습니다.' });
    }
    
    const experiment = experiments.get(experimentId);
    const data = experiment.dataPoints;
    
    // 간단한 데이터 분석 (실제로는 더 복잡한 분석 수행)
    const analysis = this.performAnalysis(data, analysisType, parameters);
    
    console.log(`🔬 데이터 분석 요청: ${analysisType} (실험: ${experiment.name})`);
    
    res.json({
        success: true,
        analysis,
        experimentId,
        analysisType,
        timestamp: new Date().toISOString()
    });
});

// 데이터 분석 함수
performAnalysis(data, analysisType, parameters) {
    switch (analysisType) {
        case 'statistical':
            return this.statisticalAnalysis(data);
        case 'trend':
            return this.trendAnalysis(data);
        case 'correlation':
            return this.correlationAnalysis(data);
        default:
            return { error: '지원되지 않는 분석 타입입니다.' };
    }
}

statisticalAnalysis(data) {
    if (data.length === 0) return { error: '분석할 데이터가 없습니다.' };
    
    const values = data.map(d => d.data.value || 0).filter(v => !isNaN(v));
    const sum = values.reduce((a, b) => a + b, 0);
    const mean = sum / values.length;
    const variance = values.reduce((a, b) => a + Math.pow(b - mean, 2), 0) / values.length;
    const stdDev = Math.sqrt(variance);
    
    return {
        count: values.length,
        mean: mean.toFixed(2),
        standardDeviation: stdDev.toFixed(2),
        min: Math.min(...values).toFixed(2),
        max: Math.max(...values).toFixed(2)
    };
}

trendAnalysis(data) {
    if (data.length < 2) return { error: '트렌드 분석을 위한 데이터가 부족합니다.' };
    
    const sortedData = data.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
    const values = sortedData.map(d => d.data.value || 0).filter(v => !isNaN(v));
    
    // 간단한 선형 회귀
    const n = values.length;
    const x = Array.from({length: n}, (_, i) => i);
    const sumX = x.reduce((a, b) => a + b, 0);
    const sumY = values.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((sum, xi, i) => sum + xi * values[i], 0);
    const sumXX = x.reduce((sum, xi) => sum + xi * xi, 0);
    
    const slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    const intercept = (sumY - slope * sumX) / n;
    
    return {
        slope: slope.toFixed(4),
        intercept: intercept.toFixed(4),
        trend: slope > 0 ? 'increasing' : slope < 0 ? 'decreasing' : 'stable',
        correlation: this.calculateCorrelation(x, values).toFixed(4)
    };
}

calculateCorrelation(x, y) {
    const n = x.length;
    const sumX = x.reduce((a, b) => a + b, 0);
    const sumY = y.reduce((a, b) => a + b, 0);
    const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
    const sumXX = x.reduce((sum, xi) => sum + xi * xi, 0);
    const sumYY = y.reduce((sum, yi) => sum + yi * yi, 0);
    
    return (n * sumXY - sumX * sumY) / Math.sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY));
}

// HTTPS 서버 설정
const options = {
    key: fs.readFileSync('lab-hub.localhost-key.pem'),
    cert: fs.readFileSync('lab-hub.localhost.pem')
};

https.createServer(options, app).listen(PORT, () => {
    console.log(`🧪 실험실 데이터 허브가 https://lab-hub.localhost:${PORT}에서 실행 중입니다.`);
});
```

## 📚 다음 단계

이제 실제 시나리오 기반 실습을 통해 사설 인증서의 활용 방법을 배웠습니다. 각 시나리오는 실제 개발 환경에서 자주 발생하는 상황을 바탕으로 구성되어 있어, 실무에 바로 적용할 수 있습니다.

**다음: [9. 고급 활용 및 최적화](./09-advanced-usage.md)**

---

## 💡 핵심 정리

- **마이크로서비스**: API Gateway를 통한 서비스 간 HTTPS 통신
- **IoT 시스템**: 실시간 디바이스 통신 및 웹 대시보드
- **의료기기**: 환자 데이터 보호를 위한 강력한 암호화
- **실험실 장비**: 연구 데이터 수집 및 분석 시스템
- **실무 적용**: 각 시나리오는 실제 개발 환경에서 바로 활용 가능
