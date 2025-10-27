# 5. 실제 프로젝트 적용

## 🎯 이 장에서 배울 내용

이 장에서는 앞서 배운 사설 인증서를 실제 프로젝트에 적용하는 방법을 학습합니다. 웹 서버, 애플리케이션 서버, 데이터베이스 연결, API 서버 등 다양한 환경에서 HTTPS를 설정하는 방법을 다룹니다.

## 🌐 웹 서버 설정

### Nginx를 사용한 HTTPS 설정

#### 1. Nginx 설치 (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install nginx
```

#### 2. 인증서 생성
```bash
# mkcert로 인증서 생성
mkcert localhost 127.0.0.1 ::1

# 인증서를 Nginx 디렉토리로 복사
sudo cp localhost.pem /etc/nginx/ssl/
sudo cp localhost-key.pem /etc/nginx/ssl/
sudo chmod 600 /etc/nginx/ssl/localhost-key.pem
```

#### 3. Nginx 설정 파일 생성
```nginx
# /etc/nginx/sites-available/ssl-site
server {
    listen 80;
    server_name localhost;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name localhost;
    
    # SSL 인증서 설정
    ssl_certificate /etc/nginx/ssl/localhost.pem;
    ssl_certificate_key /etc/nginx/ssl/localhost-key.pem;
    
    # SSL 보안 설정
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # 보안 헤더
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # 정적 파일 서빙
    root /var/www/html;
    index index.html index.htm;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # API 프록시 (예시)
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

#### 4. 사이트 활성화
```bash
# 사이트 활성화
sudo ln -s /etc/nginx/sites-available/ssl-site /etc/nginx/sites-enabled/

# 기본 사이트 비활성화
sudo rm /etc/nginx/sites-enabled/default

# Nginx 설정 테스트
sudo nginx -t

# Nginx 재시작
sudo systemctl restart nginx
```

### Apache를 사용한 HTTPS 설정

#### 1. Apache 설치
```bash
sudo apt install apache2
sudo a2enmod ssl
sudo a2enmod rewrite
```

#### 2. SSL 가상 호스트 설정
```apache
# /etc/apache2/sites-available/ssl-site.conf
<VirtualHost *:80>
    ServerName localhost
    Redirect permanent / https://localhost/
</VirtualHost>

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
```

#### 3. Apache 설정 활성화
```bash
# SSL 디렉토리 생성 및 인증서 복사
sudo mkdir -p /etc/apache2/ssl
sudo cp localhost.pem /etc/apache2/ssl/
sudo cp localhost-key.pem /etc/apache2/ssl/
sudo chmod 600 /etc/apache2/ssl/localhost-key.pem

# 사이트 활성화
sudo a2ensite ssl-site.conf
sudo systemctl restart apache2
```

## 🚀 애플리케이션 서버 설정

### Node.js Express 서버

#### 1. 프로젝트 초기화
```bash
mkdir my-https-app
cd my-https-app
npm init -y
npm install express
```

#### 2. Express 서버 코드
```javascript
// server.js
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
            <title>HTTPS Test</title>
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
    key: fs.readFileSync('localhost-key.pem'),
    cert: fs.readFileSync('localhost.pem')
};

const PORT = process.env.PORT || 443;
https.createServer(options, app).listen(PORT, () => {
    console.log(`🚀 HTTPS 서버가 https://localhost:${PORT}에서 실행 중입니다.`);
});
```

#### 3. package.json 스크립트 추가
```json
{
  "name": "my-https-app",
  "version": "1.0.0",
  "description": "HTTPS 테스트 애플리케이션",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "cert": "mkcert localhost 127.0.0.1 ::1"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

### Python Flask 서버

#### 1. 프로젝트 구조
```
flask-https-app/
├── app.py
├── requirements.txt
├── localhost.pem
├── localhost-key.pem
└── templates/
    └── index.html
```

#### 2. Flask 애플리케이션
```python
# app.py
from flask import Flask, render_template, jsonify, request
import ssl
import os

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
    context.load_cert_chain('localhost.pem', 'localhost-key.pem')
    
    # HTTPS 서버 시작
    app.run(
        host='0.0.0.0',
        port=443,
        ssl_context=context,
        debug=True
    )
```

#### 3. HTML 템플릿
```html
<!-- templates/index.html -->
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
```

#### 4. requirements.txt
```
Flask==2.3.3
Werkzeug==2.3.7
```

## 🗄️ 데이터베이스 연결

### PostgreSQL SSL 연결

#### 1. PostgreSQL SSL 설정
```bash
# PostgreSQL SSL 인증서 생성
mkcert postgres.localhost 127.0.0.1

# 인증서를 PostgreSQL 디렉토리로 복사
sudo cp postgres.localhost.pem /etc/postgresql/15/main/server.crt
sudo cp postgres.localhost-key.pem /etc/postgresql/15/main/server.key
sudo chown postgres:postgres /etc/postgresql/15/main/server.*
sudo chmod 600 /etc/postgresql/15/main/server.key
```

#### 2. PostgreSQL 설정 파일 수정
```bash
# /etc/postgresql/15/main/postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ciphers = 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256'
```

#### 3. Node.js에서 SSL 연결
```javascript
// database.js
const { Pool } = require('pg');
const fs = require('fs');

const pool = new Pool({
    host: 'localhost',
    port: 5432,
    database: 'myapp',
    user: 'myuser',
    password: 'mypassword',
    ssl: {
        rejectUnauthorized: true,
        ca: fs.readFileSync('localhost.pem').toString(),
        cert: fs.readFileSync('localhost.pem').toString(),
        key: fs.readFileSync('localhost-key.pem').toString()
    }
});

module.exports = pool;
```

### MySQL SSL 연결

#### 1. MySQL SSL 설정
```bash
# MySQL SSL 인증서 생성
mkcert mysql.localhost 127.0.0.1

# 인증서를 MySQL 디렉토리로 복사
sudo cp mysql.localhost.pem /etc/mysql/ssl/server-cert.pem
sudo cp mysql.localhost-key.pem /etc/mysql/ssl/server-key.pem
sudo chown mysql:mysql /etc/mysql/ssl/server-*
sudo chmod 600 /etc/mysql/ssl/server-key.pem
```

#### 2. MySQL 설정 파일 수정
```ini
# /etc/mysql/mysql.conf.d/mysqld.cnf
[mysqld]
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
require_secure_transport=ON
```

## 🔌 API 서버 설정

### RESTful API 서버

#### 1. Express API 서버
```javascript
// api-server.js
const express = require('express');
const https = require('https');
const fs = require('fs');
const cors = require('cors');

const app = express();

// 미들웨어 설정
app.use(cors({
    origin: ['https://localhost', 'https://127.0.0.1'],
    credentials: true
}));
app.use(express.json());

// 인증 미들웨어
const authenticate = (req, res, next) => {
    const token = req.headers.authorization;
    if (!token) {
        return res.status(401).json({ error: '인증 토큰이 필요합니다.' });
    }
    // 토큰 검증 로직
    next();
};

// API 라우트
app.get('/api/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        protocol: req.protocol
    });
});

app.get('/api/users', authenticate, (req, res) => {
    res.json([
        { id: 1, name: '홍길동', email: 'hong@example.com' },
        { id: 2, name: '김철수', email: 'kim@example.com' }
    ]);
});

app.post('/api/users', authenticate, (req, res) => {
    const { name, email } = req.body;
    res.json({
        id: Date.now(),
        name,
        email,
        createdAt: new Date().toISOString()
    });
});

// HTTPS 서버 시작
const options = {
    key: fs.readFileSync('localhost-key.pem'),
    cert: fs.readFileSync('localhost.pem')
};

https.createServer(options, app).listen(443, () => {
    console.log('🔌 API 서버가 https://localhost에서 실행 중입니다.');
});
```

### GraphQL API 서버

#### 1. GraphQL 서버 설정
```javascript
// graphql-server.js
const express = require('express');
const { ApolloServer } = require('apollo-server-express');
const https = require('https');
const fs = require('fs');

// GraphQL 스키마
const typeDefs = `
    type User {
        id: ID!
        name: String!
        email: String!
        createdAt: String!
    }
    
    type Query {
        users: [User]
        user(id: ID!): User
    }
    
    type Mutation {
        createUser(name: String!, email: String!): User
    }
`;

// 리졸버
const resolvers = {
    Query: {
        users: () => [
            { id: '1', name: '홍길동', email: 'hong@example.com', createdAt: '2023-01-01T00:00:00Z' },
            { id: '2', name: '김철수', email: 'kim@example.com', createdAt: '2023-01-02T00:00:00Z' }
        ],
        user: (_, { id }) => {
            // 사용자 조회 로직
            return { id, name: '홍길동', email: 'hong@example.com', createdAt: '2023-01-01T00:00:00Z' };
        }
    },
    Mutation: {
        createUser: (_, { name, email }) => {
            return {
                id: Date.now().toString(),
                name,
                email,
                createdAt: new Date().toISOString()
            };
        }
    }
};

async function startServer() {
    const app = express();
    
    const server = new ApolloServer({
        typeDefs,
        resolvers,
        context: ({ req }) => {
            // 인증 컨텍스트
            return { user: req.user };
        }
    });
    
    await server.start();
    server.applyMiddleware({ app, path: '/graphql' });
    
    // HTTPS 서버 시작
    const options = {
        key: fs.readFileSync('localhost-key.pem'),
        cert: fs.readFileSync('localhost.pem')
    };
    
    https.createServer(options, app).listen(443, () => {
        console.log(`🚀 GraphQL 서버가 https://localhost/graphql에서 실행 중입니다.`);
    });
}

startServer();
```

## 🐳 Docker 환경에서 HTTPS

### Docker Compose 설정

#### 1. docker-compose.yml
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./localhost.pem:/etc/nginx/ssl/localhost.pem
      - ./localhost-key.pem:/etc/nginx/ssl/localhost-key.pem
    depends_on:
      - app

  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./localhost.pem:/etc/ssl/certs/server.crt
      - ./localhost-key.pem:/etc/ssl/private/server.key

volumes:
  postgres_data:
```

#### 2. Nginx 설정 (Docker)
```nginx
# nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream app {
        server app:3000;
    }
    
    server {
        listen 443 ssl;
        server_name localhost;
        
        ssl_certificate /etc/nginx/ssl/localhost.pem;
        ssl_certificate_key /etc/nginx/ssl/localhost-key.pem;
        
        location / {
            proxy_pass http://app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

#### 3. Dockerfile
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# mkcert 설치 및 인증서 생성
RUN apk add --no-cache openssl
RUN wget -O mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64
RUN chmod +x mkcert && mv mkcert /usr/local/bin/

EXPOSE 3000

CMD ["npm", "start"]
```

## 🧪 테스트 및 검증

### 자동화된 테스트 스크립트

#### 1. HTTPS 연결 테스트
```bash
#!/bin/bash
# test-https.sh

echo "🔍 HTTPS 연결 테스트 시작..."

# 기본 연결 테스트
echo "1. 기본 HTTPS 연결 테스트"
curl -k https://localhost/api/health

# SSL 인증서 정보 확인
echo "2. SSL 인증서 정보 확인"
openssl s_client -connect localhost:443 -servername localhost < /dev/null 2>/dev/null | openssl x509 -text -noout

# 보안 헤더 확인
echo "3. 보안 헤더 확인"
curl -I https://localhost

# 성능 테스트
echo "4. 성능 테스트"
ab -n 100 -c 10 https://localhost/

echo "✅ HTTPS 테스트 완료"
```

#### 2. API 엔드포인트 테스트
```javascript
// test-api.js
const https = require('https');
const fs = require('fs');

const options = {
    hostname: 'localhost',
    port: 443,
    path: '/api/health',
    method: 'GET',
    rejectUnauthorized: false // 개발 환경에서만 사용
};

const req = https.request(options, (res) => {
    console.log(`상태 코드: ${res.statusCode}`);
    console.log(`헤더:`, res.headers);
    
    res.on('data', (data) => {
        console.log('응답 데이터:', data.toString());
    });
});

req.on('error', (error) => {
    console.error('요청 오류:', error);
});

req.end();
```

## 📚 다음 단계

이제 실제 프로젝트에 HTTPS를 적용하는 방법을 배웠습니다. 다음 장에서는 인증서 관리 및 모니터링에 대해 알아보겠습니다.

**다음: [6. 인증서 관리 및 모니터링](./06-certificate-management.md)**

---

## 💡 핵심 정리

- **웹 서버 설정**: Nginx, Apache에서 SSL 인증서 적용
- **애플리케이션 서버**: Node.js, Python에서 HTTPS 구현
- **데이터베이스 연결**: PostgreSQL, MySQL SSL 연결
- **API 서버**: RESTful API, GraphQL에서 HTTPS 적용
- **Docker 환경**: 컨테이너 환경에서 HTTPS 설정
- **테스트 및 검증**: 자동화된 테스트 스크립트 작성
