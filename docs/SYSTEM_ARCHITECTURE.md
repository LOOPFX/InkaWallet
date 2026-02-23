# InkaWallet System Architecture & Deployment Diagrams

## System Architecture Diagram

```mermaid
graph TB
    subgraph "Client Layer"
        A[Flutter Mobile App<br/>iOS & Android]
        A1[Home Screen]
        A2[Send Money Screen]
        A3[KYC Screens]
        A4[Voice Control]

        A --> A1
        A --> A2
        A --> A3
        A --> A4
    end

    subgraph "API Gateway Layer"
        B[Backend API Server<br/>Node.js + Express]
        B1[Auth Routes]
        B2[Transaction Routes]
        B3[KYC Routes]
        B4[Voice Routes]
        B5[WebSocket Server<br/>Voice Streaming]

        B --> B1
        B --> B2
        B --> B3
        B --> B4
        B --> B5
    end

    subgraph "Service Layer"
        C1[KYC Verification Service]
        C2[Transaction Monitoring Service]
        C3[Credit Scoring Service]
        C4[Speechmatics Proxy Service]
        C5[Notification Service]
    end

    subgraph "Data Layer"
        D[MySQL Database]
        D1[users]
        D2[wallets]
        D3[transactions]
        D4[kyc_profiles]
        D5[kyc_documents]

        D --> D1
        D --> D2
        D --> D3
        D --> D4
        D --> D5
    end

    subgraph "File Storage"
        E[File System<br/>/uploads/kyc-documents/]
    end

    subgraph "External Services"
        F1[Speechmatics API<br/>Voice Recognition]
        F2[Google OAuth<br/>Authentication]
        F3[SMS Provider<br/>2FA Codes]
        F4[Mobile Money APIs<br/>Mpamba, Airtel Money]
        F5[Reserve Bank of Malawi<br/>Compliance Reporting]
    end

    A -->|HTTPS/REST| B
    A -->|WebSocket| B5

    B --> C1
    B --> C2
    B --> C3
    B --> C4
    B --> C5

    C1 --> D
    C2 --> D
    C3 --> D

    C1 --> E

    B4 --> F1
    B1 --> F2
    B1 --> F3
    B2 --> F4
    C1 --> F5

    style A fill:#4CAF50
    style B fill:#2196F3
    style D fill:#FF9800
    style E fill:#FFC107
    style F1 fill:#9C27B0
    style F2 fill:#9C27B0
    style F3 fill:#9C27B0
    style F4 fill:#9C27B0
    style F5 fill:#9C27B0
```

## Deployment Architecture

```mermaid
graph TB
    subgraph "User Devices"
        U1[Android Phone<br/>SDK 21+]
        U2[iOS Device<br/>iOS 11+]
        U3[Tablet<br/>Android/iOS]
    end

    subgraph "Load Balancer"
        LB[Nginx Load Balancer<br/>SSL Termination]
    end

    subgraph "Application Servers - Port 3000"
        AS1[App Server 1<br/>Node.js]
        AS2[App Server 2<br/>Node.js]
        AS3[App Server 3<br/>Node.js]
    end

    subgraph "Database Cluster"
        DB1[MySQL Primary<br/>Read/Write]
        DB2[MySQL Replica 1<br/>Read Only]
        DB3[MySQL Replica 2<br/>Read Only]
    end

    subgraph "Cache Layer"
        R1[Redis Cluster<br/>Session Storage]
        R2[Redis Cache<br/>Application Cache]
    end

    subgraph "File Storage"
        FS[NFS/S3<br/>Document Storage]
    end

    subgraph "Monitoring & Logging"
        M1[Prometheus<br/>Metrics]
        M2[Grafana<br/>Dashboards]
        M3[ELK Stack<br/>Logs]
    end

    subgraph "Backup System"
        BK1[Daily Backups]
        BK2[S3 Backup Storage]
    end

    U1 -->|HTTPS| LB
    U2 -->|HTTPS| LB
    U3 -->|HTTPS| LB

    LB --> AS1
    LB --> AS2
    LB --> AS3

    AS1 --> DB1
    AS2 --> DB1
    AS3 --> DB1

    AS1 --> DB2
    AS2 --> DB3
    AS3 --> DB3

    AS1 --> R1
    AS2 --> R1
    AS3 --> R1

    AS1 --> R2
    AS2 --> R2
    AS3 --> R2

    AS1 --> FS
    AS2 --> FS
    AS3 --> FS

    DB1 -.->|Replication| DB2
    DB1 -.->|Replication| DB3

    AS1 --> M1
    AS2 --> M1
    AS3 --> M1

    M1 --> M2

    AS1 --> M3
    AS2 --> M3
    AS3 --> M3

    DB1 --> BK1
    BK1 --> BK2

    style U1 fill:#4CAF50
    style U2 fill:#4CAF50
    style U3 fill:#4CAF50
    style LB fill:#2196F3
    style DB1 fill:#FF9800
    style FS fill:#FFC107
    style R1 fill:#E91E63
    style M2 fill:#00BCD4
```

## Infrastructure Diagram

```plantuml
@startuml Infrastructure

!define DEVICONS https://raw.githubusercontent.com/tupadr3/plantuml-icon-font-sprites/master/devicons
!define FONTAWESOME https://raw.githubusercontent.com/tupadr3/plantuml-icon-font-sprites/master/font-awesome-5

!include DEVICONS/android.puml
!include DEVICONS/apple.puml
!include DEVICONS/nginx.puml
!include DEVICONS/nodejs.puml
!include DEVICONS/mysql.puml
!include DEVICONS/redis.puml

package "Mobile Clients" {
    DEV_ANDROID(android, "Android App", component)
    DEV_APPLE(ios, "iOS App", component)
}

package "Edge Layer" {
    DEV_NGINX(nginx, "Nginx LB\nSSL/TLS", component)
}

package "Application Layer" {
    DEV_NODEJS(node1, "Node.js\nServer 1", component)
    DEV_NODEJS(node2, "Node.js\nServer 2", component)
    DEV_NODEJS(node3, "Node.js\nServer 3", component)
}

package "Data Layer" {
    DEV_MYSQL(mysql_primary, "MySQL\nPrimary", database)
    DEV_MYSQL(mysql_replica1, "MySQL\nReplica 1", database)
    DEV_MYSQL(mysql_replica2, "MySQL\nReplica 2", database)
}

package "Cache Layer" {
    DEV_REDIS(redis_session, "Redis\nSessions", component)
    DEV_REDIS(redis_cache, "Redis\nCache", component)
}

cloud "External Services" {
    [Speechmatics API]
    [Google OAuth]
    [SMS Gateway]
    [Mobile Money APIs]
}

storage "File Storage" {
    [S3/NFS\nKYC Documents]
}

android -down-> nginx : HTTPS
ios -down-> nginx : HTTPS

nginx -down-> node1 : HTTP
nginx -down-> node2 : HTTP
nginx -down-> node3 : HTTP

node1 -down-> mysql_primary : Write
node2 -down-> mysql_primary : Write
node3 -down-> mysql_primary : Write

node1 -down-> mysql_replica1 : Read
node2 -down-> mysql_replica2 : Read
node3 -down-> mysql_replica1 : Read

mysql_primary .down.> mysql_replica1 : Replicate
mysql_primary .down.> mysql_replica2 : Replicate

node1 -right-> redis_session
node2 -right-> redis_session
node3 -right-> redis_session

node1 -right-> redis_cache
node2 -right-> redis_cache
node3 -right-> redis_cache

node1 --> [Speechmatics API]
node2 --> [Google OAuth]
node3 --> [SMS Gateway]
node1 --> [Mobile Money APIs]

node1 --> [S3/NFS\nKYC Documents]
node2 --> [S3/NFS\nKYC Documents]
node3 --> [S3/NFS\nKYC Documents]

@enduml
```

## Network Architecture

```mermaid
graph TB
    subgraph "Internet"
        INT[Internet Users]
    end

    subgraph "DMZ - Demilitarized Zone"
        FW1[Firewall<br/>Port 443, 80]
        LB[Load Balancer<br/>Nginx]
        WAF[Web Application Firewall<br/>ModSecurity]
    end

    subgraph "Application Zone - Private Network"
        AS1[App Server 1<br/>10.0.1.10]
        AS2[App Server 2<br/>10.0.1.11]
        AS3[App Server 3<br/>10.0.1.12]
    end

    subgraph "Database Zone - Private Network"
        DB1[MySQL Primary<br/>10.0.2.10]
        DB2[MySQL Replica<br/>10.0.2.11]
    end

    subgraph "Cache Zone - Private Network"
        RD1[Redis Master<br/>10.0.3.10]
        RD2[Redis Slave<br/>10.0.3.11]
    end

    subgraph "Storage Zone"
        FS[File Storage<br/>10.0.4.10]
    end

    INT -->|HTTPS :443| FW1
    FW1 --> WAF
    WAF --> LB

    LB -->|HTTP :3000| AS1
    LB -->|HTTP :3000| AS2
    LB -->|HTTP :3000| AS3

    AS1 -->|MySQL :3306| DB1
    AS2 -->|MySQL :3306| DB1
    AS3 -->|MySQL :3306| DB1

    AS1 -->|MySQL :3306| DB2
    AS2 -->|MySQL :3306| DB2
    AS3 -->|MySQL :3306| DB2

    AS1 -->|Redis :6379| RD1
    AS2 -->|Redis :6379| RD1
    AS3 -->|Redis :6379| RD1

    AS1 -->|NFS/S3| FS
    AS2 -->|NFS/S3| FS
    AS3 -->|NFS/S3| FS

    DB1 -.->|Replication| DB2
    RD1 -.->|Replication| RD2

    style INT fill:#4CAF50
    style FW1 fill:#F44336
    style WAF fill:#F44336
    style DB1 fill:#FF9800
    style FS fill:#FFC107
```

## Component Diagram

```plantuml
@startuml ComponentDiagram

package "Mobile Application" {
    [UI Layer] as UI
    [State Management] as State
    [Services Layer] as MobileServices
    [Local Storage] as LocalDB

    UI --> State
    State --> MobileServices
    MobileServices --> LocalDB
}

package "Backend API" {
    [API Gateway] as Gateway
    [Authentication] as Auth
    [Transaction Handler] as TxHandler
    [KYC Service] as KYC
    [Voice Proxy] as Voice

    Gateway --> Auth
    Gateway --> TxHandler
    Gateway --> KYC
    Gateway --> Voice
}

package "Business Logic" {
    [KYC Verification] as KYCLogic
    [Transaction Monitoring] as TxMonitor
    [Credit Scoring] as CreditScore
    [Risk Assessment] as Risk

    TxHandler --> TxMonitor
    KYC --> KYCLogic
    KYCLogic --> Risk
    TxHandler --> CreditScore
}

package "Data Access" {
    [Database Manager] as DBManager
    [File Manager] as FileManager
    [Cache Manager] as CacheManager

    KYCLogic --> DBManager
    TxMonitor --> DBManager
    CreditScore --> DBManager
    KYCLogic --> FileManager
    Auth --> CacheManager
}

database "MySQL" {
    [Users Table] as Users
    [Transactions Table] as Transactions
    [KYC Profiles Table] as KYCProfiles
}

storage "S3/NFS" {
    [KYC Documents] as Docs
}

database "Redis" {
    [Session Cache] as Sessions
    [Data Cache] as DataCache
}

cloud "External APIs" {
    [Speechmatics] as SpeechAPI
    [Google OAuth] as GoogleAPI
    [Mobile Money] as MobileMoneyAPI
}

MobileServices --> Gateway : HTTPS REST API
UI --> Voice : WebSocket

DBManager --> Users
DBManager --> Transactions
DBManager --> KYCProfiles

FileManager --> Docs

CacheManager --> Sessions
CacheManager --> DataCache

Voice --> SpeechAPI
Auth --> GoogleAPI
TxHandler --> MobileMoneyAPI

@enduml
```

## Technology Stack

```mermaid
graph LR
    subgraph "Frontend Stack"
        A1[Flutter 3.x]
        A2[Dart 3.x]
        A3[Provider<br/>State Management]
        A4[HTTP Package]
        A5[Shared Preferences<br/>Local Storage]
        A6[Flutter TTS]
        A7[Speech to Text]
        A8[Local Auth<br/>Biometrics]
    end

    subgraph "Backend Stack"
        B1[Node.js 18+]
        B2[TypeScript 5.x]
        B3[Express.js 4.x]
        B4[MySQL 8.0]
        B5[Redis 7.x]
        B6[WebSocket ws]
        B7[Multer<br/>File Upload]
        B8[JWT<br/>Authentication]
        B9[Bcrypt<br/>Password Hash]
    end

    subgraph "DevOps Stack"
        C1[Docker]
        C2[Docker Compose]
        C3[Nginx]
        C4[PM2<br/>Process Manager]
        C5[Git/GitHub]
        C6[Prometheus]
        C7[Grafana]
    end

    subgraph "External APIs"
        D1[Speechmatics API]
        D2[Google OAuth 2.0]
        D3[Twilio SMS]
        D4[TNM Mpamba API]
        D5[Airtel Money API]
    end

    style A1 fill:#4CAF50
    style B1 fill:#2196F3
    style C1 fill:#FF9800
    style D1 fill:#9C27B0
```

## Security Architecture

```plantuml
@startuml SecurityArchitecture

actor User
participant "Mobile App" as App
participant "WAF" as WAF
participant "Load Balancer" as LB
participant "API Server" as API
participant "Auth Service" as Auth
database "Database" as DB
storage "File Storage" as Storage

== Security Layers ==

User -> App: Launch App
App -> App: Check SSL Certificate Pinning

App -> WAF: HTTPS Request (TLS 1.3)
WAF -> WAF: DDoS Protection
WAF -> WAF: SQL Injection Check
WAF -> WAF: XSS Protection
WAF -> LB: Forward Request

LB -> API: HTTP Request
API -> Auth: Verify JWT Token

Auth -> Auth: Validate Token Signature
Auth -> Auth: Check Token Expiry
Auth -> Auth: Verify IP Address

alt Valid Token
    Auth --> API: Authorized
    API -> API: Rate Limiting Check
    API -> API: Input Validation
    API -> API: Sanitize Input

    API -> DB: Encrypted Query (SSL)
    DB -> DB: Row-Level Security
    DB --> API: Encrypted Data

    API -> API: Encrypt Sensitive Data (AES-256)
    API --> LB: Response
    LB --> WAF: Response
    WAF --> App: HTTPS Response

else Invalid Token
    Auth --> API: Unauthorized
    API --> LB: 401 Error
    LB --> WAF: Error
    WAF --> App: Unauthorized
end

== File Upload Security ==

User -> App: Upload KYC Document
App -> App: Virus Scan (Local)
App -> App: File Type Validation
App -> API: Encrypted Upload

API -> API: Validate File Type
API -> API: Check File Size
API -> API: Scan for Malware
API -> Storage: Store with Encryption
Storage -> Storage: AES-256 Encryption
Storage --> API: File URL (Signed)

== Data Protection ==

note over DB
    - All passwords hashed (bcrypt)
    - PII encrypted (AES-256)
    - SSL/TLS connections
    - Backup encryption
    - Access logs
end note

note over API
    - JWT token auth
    - Rate limiting
    - Input validation
    - CORS protection
    - Helmet.js security headers
end note

note over App
    - SSL pinning
    - Secure storage
    - Code obfuscation
    - Root/jailbreak detection
    - Biometric encryption
end note

@enduml
```

## Scalability Strategy

```mermaid
graph TB
    subgraph "Horizontal Scaling"
        A1[Add App Servers<br/>Auto-scaling]
        A2[Database Replication<br/>Read Replicas]
        A3[Load Balancing<br/>Nginx]
        A4[Cache Layer<br/>Redis Cluster]
    end

    subgraph "Performance Optimization"
        B1[CDN for Static Assets]
        B2[Connection Pooling]
        B3[Query Optimization<br/>Indexes]
        B4[Lazy Loading]
        B5[Data Pagination]
    end

    subgraph "Monitoring & Auto-scaling"
        C1[CPU Usage > 70%<br/>Add Server]
        C2[Memory Usage > 80%<br/>Scale Up]
        C3[Response Time > 500ms<br/>Alert]
        C4[Database Connections<br/>Pool Size]
    end

    subgraph "Future Enhancements"
        D1[Microservices<br/>Architecture]
        D2[Event-Driven<br/>Architecture]
        D3[Kubernetes<br/>Orchestration]
        D4[Serverless<br/>Functions]
    end

    A1 --> C1
    A2 --> C4
    B3 --> C3

    style A1 fill:#4CAF50
    style B1 fill:#2196F3
    style C1 fill:#FF9800
    style D1 fill:#9C27B0
```
