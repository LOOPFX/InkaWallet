# InkaWallet Software Development Documentation - Index

## Overview

This directory contains comprehensive software development documentation for the InkaWallet mobile financial inclusion platform, created during the Requirements and Design stages of the software development lifecycle.

## Documentation Files

### 1. Requirements Documentation

#### [REQUIREMENTS_SPECIFICATION.md](./REQUIREMENTS_SPECIFICATION.md)

**Purpose**: Comprehensive functional and non-functional requirements specification

**Contents**:

- Project introduction and scope
- Target user groups
- 30+ Functional Requirements (FR) organized by feature:
  - Authentication (FR-AUTH): Registration, login, biometric, 2FA, OAuth
  - Wallet Management (FR-WALLET): Balance, top-up, transaction history
  - Money Transfer (FR-TRANSFER): Send, receive, request, QR payments
  - KYC Verification (FR-KYC): Profile creation, document upload, admin verification, limit enforcement
  - Buy Now Pay Later (FR-BNPL): Loan application, payments, overdue handling
  - Credit Scoring (FR-CREDIT): Score calculation, viewing
  - Voice Control (FR-VOICE): Wake word, command processing, TTS feedback
  - Bills and Services (FR-BILLS): Utility bills, airtime purchase
  - Notifications (FR-NOTIF): Push and in-app notifications
  - Admin Functions (FR-ADMIN): Dashboard, user management
- 20+ Non-Functional Requirements (NFR):
  - Performance (NFR-PERF): Response time, throughput, database performance
  - Security (NFR-SEC): Encryption, authentication, authorization, audit logging
  - Reliability (NFR-REL): Availability, fault tolerance, backup
  - Accessibility (NFR-ACCESS): Screen reader, voice control, visual accessibility
  - Usability (NFR-USE): Learning curve, error handling
  - Compliance (NFR-COMP): Regulatory compliance, data privacy
  - Scalability (NFR-SCALE): Horizontal scaling, data growth
  - Maintainability (NFR-MAINT): Code quality, deployment
- System constraints
- Acceptance criteria

### 2. Use Case Documentation

#### [USE_CASE_DIAGRAMS.md](./USE_CASE_DIAGRAMS.md)

**Purpose**: Visual representation of system interactions and user journeys

**Contents**:

- **Main System Use Case Diagram**: Shows all actors (Customer, Blind User, Admin, Reserve Bank of Malawi) and their interactions with the system
- **Authentication Use Case**: Detailed view of registration, login, biometric authentication, 2FA, and Google OAuth flows
- **KYC Verification Use Case**: Customer KYC submission, admin verification, compliance reporting, and limit management
- **Money Transfer Use Case**: Send money, receive money, request money, and QR code payment flows
- **Voice Control Use Case**: Wake word detection, voice command processing, TTS feedback, and haptic feedback
- **Detailed Use Case Descriptions**:
  - UC-001: Register Account
  - UC-024: Submit KYC Profile
  - UC-020: Use Voice Commands

**Diagram Format**: PlantUML (can be rendered in many tools including VS Code, GitHub, documentation generators)

### 3. Database Design Documentation

#### [DATABASE_DESIGN.md](./DATABASE_DESIGN.md)

**Purpose**: Complete database architecture and design documentation

**Contents**:

- **Entity Relationship Diagram (ERD)**: Visual representation of all 15 tables and their relationships (Mermaid format)
- **Detailed Table Schemas**:
  - USERS: User accounts and authentication
  - WALLETS: User wallet balances
  - TRANSACTIONS: All financial transactions
  - KYC_PROFILES: Customer verification profiles
  - KYC_DOCUMENTS: Uploaded identity documents
  - KYC_VERIFICATION_HISTORY: Audit trail of KYC decisions
  - TRANSACTION_MONITORING: Daily/monthly transaction tracking for limits
  - BENEFICIARIES: Saved recipients
  - BNPL_LOANS: Buy Now Pay Later loan records
  - BNPL_PAYMENTS: Loan payment history
  - CREDIT_SCORES: User creditworthiness scores
  - MONEY_REQUESTS: Money request records
  - NOTIFICATIONS: System notifications
  - ACTIVITY_LOGS: Security and audit logs
  - TWO_FACTOR_AUTH: 2FA codes
- **Normalization Analysis**: 1NF, 2NF, 3NF compliance
- **Denormalization Decisions**: TRANSACTION_MONITORING for performance
- **Index Strategy**: 20+ indexes (primary, composite, covering)
- **Data Constraints**: CHECK constraints, FOREIGN KEY relationships
- **Security Measures**: AES-256 encryption, bcrypt hashing, SSL/TLS, audit logs
- **Performance Optimization**: Query optimization, partitioning, caching strategies
- **Backup Strategy**: Daily full backups, 6-hour incremental, 30-day retention

### 4. UML Class Diagrams

#### [UML_CLASS_DIAGRAMS.md](./UML_CLASS_DIAGRAMS.md)

**Purpose**: Object-oriented design and system architecture

**Contents**:

- **System Architecture Class Diagram**: High-level view showing Mobile App, Backend API, and External Services components
- **Mobile App Class Diagram**: Detailed Flutter architecture
  - Providers: AuthProvider, WalletProvider, ThemeProvider, NotificationProvider, AccessibilityProvider
  - Services: ApiService, KycService, VoiceCommandService, AccessibilityService, BiometricService, NotificationService, SpeechmaticsService
  - Models: User, Wallet, Transaction, KycProfile, KycDocument, BnplLoan, CreditScore, NotificationModel
  - Screens: All 15 app screens
- **Backend Class Diagram**: Detailed Node.js/TypeScript architecture
  - Routes: AuthRoutes, KycRoutes, TransactionRoutes, WalletRoutes, BnplRoutes, CreditRoutes, BillsRoutes, NotificationRoutes
  - Middleware: AuthMiddleware, ValidationMiddleware, ErrorMiddleware, RateLimitMiddleware
  - Services: SpeechmaticsProxyService, KycVerificationService, TransactionMonitoringService, CreditScoringService, NotificationService
  - Config: DatabaseConfig, JwtConfig, SpeechmaticsConfig
  - Types: User, Transaction, KycProfile, BnplLoan, enums
- **Domain Model Class Diagram**: Core business entities and relationships
  - Entities: User, Wallet, Transaction, KycProfile, BnplLoan, CreditScore, TransactionMonitor
  - Enums: TransactionType, TransactionStatus, KycStatus, VerificationLevel

**Diagram Format**: PlantUML

### 5. Sequence Diagrams

#### [SEQUENCE_DIAGRAMS.md](./SEQUENCE_DIAGRAMS.md)

**Purpose**: Detailed flow of operations and interactions between components

**Contents**:

- **User Registration and Login Flow**:
  - Registration process with validation and JWT token generation
  - Email/password login with error handling
  - Biometric login flow with fallback mechanisms
- **KYC Verification Flow**: End-to-end process from customer submission to admin approval
  - Customer creates profile and uploads documents
  - Admin reviews documents and performs compliance checks
  - Tier assignment and notification delivery
- **Send Money Transaction Flow**: Complete money transfer process
  - KYC limit checking
  - Balance validation
  - Atomic transaction processing (database transaction)
  - Notification to both sender and receiver
- **Voice Command Flow**: Hands-free voice interaction
  - Wake word detection ("Inka")
  - Speechmatics real-time transcription
  - Intent recognition and parameter extraction
  - Command execution with voice feedback
- **BNPL Loan Application Flow**: Loan eligibility and approval
  - Credit score calculation
  - Loan application with amount validation
  - Payment tracking and overdue handling
- **2FA Authentication Flow**: Two-factor authentication setup and usage
  - Code generation and SMS delivery
  - Code verification with retry logic
  - Login with 2FA enabled

**Diagram Format**: PlantUML

### 6. Activity Diagrams

#### [ACTIVITY_DIAGRAMS.md](./ACTIVITY_DIAGRAMS.md)

**Purpose**: Business process flows and decision logic

**Contents**:

- **User Registration Process**: Step-by-step registration flow with validation
- **KYC Submission Process**: Complete KYC workflow from start to verification
  - Personal details form
  - Disability declaration (optional)
  - Document upload with voice guidance
  - Submission validation
- **Send Money Transaction Process**: Decision flow for money transfers
  - Recipient selection
  - Amount validation
  - KYC and limit checking
  - Biometric authentication (optional)
  - Transaction processing with rollback on error
- **BNPL Loan Application Process**: Loan application workflow
  - Credit score calculation
  - Loan option selection
  - Repayment tracking
  - Overdue handling
- **Voice Command Processing**: Voice interaction flow
  - Wake word detection loop
  - Intent recognition
  - Parameter extraction with interactive dialogue
  - Action execution with feedback
- **Admin KYC Verification Process**: Admin workflow for KYC review
  - Document review
  - Compliance checks (AML/CFT, PEP database)
  - Tier assignment
  - Reserve Bank reporting
- **Biometric Authentication Setup**: Enabling biometric login
  - Device capability check
  - Credential encryption and storage
- **Two-Factor Authentication Flow**: 2FA setup and login process

**Diagram Format**: PlantUML

### 7. State Diagrams

#### [STATE_DIAGRAMS.md](./STATE_DIAGRAMS.md)

**Purpose**: Lifecycle and state transitions of key entities

**Contents**:

- **KYC Profile State Diagram**:
  - States: NotStarted → DraftProfile → PendingDocuments → ReadyForSubmission → PendingVerification → Verified/Rejected → Suspended/Terminated
  - Triggers and transitions for each state
  - Entry/exit actions
- **Transaction State Diagram**:
  - States: Initiated → Validating → PendingConfirmation → Processing → Completed/Failed/Cancelled
  - Atomic transaction handling
  - Error states and rollback
- **User Session State Diagram**:
  - States: LoggedOut → Authenticating → Pending2FA → LoggedIn → Active → Idle
  - Session timeout handling
  - Token expiry and refresh
- **BNPL Loan State Diagram**:
  - States: Applied → Approved/Rejected → Active → PendingPayment → Overdue → DefaultRisk → Defaulted/PaidOff
  - Payment tracking
  - Overdue penalties and restrictions
- **Voice Control State Diagram**:
  - States: Disabled → Initialized → ListeningForWakeWord → WakeWordDetected → ListeningForCommand → ProcessingIntent → ExecutingCommand → CommandSuccess/Failed
  - Interactive dialogue for missing parameters
- **Credit Score State Diagram**:
  - States: Unscored → Poor → Fair → Good → Excellent → VeryPoor
  - Score calculation factors (positive and negative)
  - Tier benefits
- **Notification State Diagram**:
  - States: Created → Pending → Sending → Delivered → Read → Archived/Expired
  - Retry logic for failed deliveries
  - Action handling

**Diagram Format**: PlantUML

### 8. Screen Designs

#### [SCREEN_DESIGNS.md](./SCREEN_DESIGNS.md)

**Purpose**: Comprehensive UI/UX design specifications for all mobile app screens

**Contents**:

- **Design Principles**: Accessibility-first design, visual design system, color schemes, typography
- **Screen Inventory**: Complete list of all 18 screens with routes and purposes
- **Navigation Flow Diagram**: Visual representation of app navigation (Mermaid)
- **Detailed Wireframes**: Text-based wireframes for all 18 screens:
  1. Login Screen (biometric, OAuth, 2FA)
  2. Register Screen (validation, password requirements)
  3. Home Screen (dashboard, balance card, quick actions, recent transactions)
  4. Send Money Screen (recipient selection, amount input, summary)
  5. Receive Money Screen (QR code, payment details, money requests)
  6. Top Up Screen (Mpamba, Airtel Money, bank transfer)
  7. Transactions Screen (filters, search, export, history)
  8. KYC Status Screen (verification status, limits, benefits)
  9. BNPL Screen (credit score, active loans, payment options)
  10. Settings Screen (account, security, accessibility, notifications)
  11. Plus: Airtime, Bills, Notifications, My QR, Scan & Pay, Credit Score, KYC Profile, KYC Documents screens
- **UI Specifications**:
  - Component specs for each screen (sizes, spacing, colors)
  - Voice commands supported per screen
  - Accessibility labels and hints
- **Design Tokens**:
  - Color palette (primary, secondary, accent, status colors)
  - Typography scale (heading1-3, body1-2, caption)
  - Spacing system (8dp grid)
  - Border radius values
- **Responsive Design**: Breakpoints (360dp, 600dp, 960dp) and adaptive layouts
- **Animation Guidelines**: Transitions (300ms), micro-interactions, loading states
- **Error States**: Empty states, error messages, network errors, validation feedback
- **Platform Considerations**: Android Material Design 3, iOS Cupertino widgets
- **Testing Checklist**: Visual, accessibility, and functional testing criteria

**Diagram Formats**: Mermaid (navigation), text-based wireframes

### 9. Screen Flow Diagrams

#### [SCREEN_FLOW_DIAGRAMS.md](./SCREEN_FLOW_DIAGRAMS.md)

**Purpose**: Detailed user journey flows and screen navigation patterns

**Contents**:

- **Complete Application Flow**: Mermaid diagram showing all screen connections from app launch to all features
- **Authentication Flow Detail**: PlantUML showing email/password, biometric, Google OAuth, and 2FA decision paths
- **Money Transfer Flow**: Complete send money process with balance checks, KYC validation, limit enforcement, biometric auth
- **KYC Verification Flow**: End-to-end from profile creation → document upload → admin review → approval/rejection
- **BNPL Loan Flow**: Eligibility check → credit score calculation → loan application → payment tracking → overdue handling → completion
- **Voice Command Flow**: Wake word detection loop → Speechmatics transcription → intent recognition → command execution → feedback
- **Settings & Profile Flow**: All settings navigation and configuration changes
- **Transaction History Flow**: Filtering by type/date, searching, exporting PDF, loading more
- **Notification Flow**: Event → create → store → push → user action → navigation → mark read
- **Error Handling Flow**: Network errors, validation errors, server errors, offline queuing
- **Deep Link Flows**:
  - Push notification routing (transaction, KYC, BNPL, payment due)
  - QR code scanning and payment processing

**Diagram Formats**: Mermaid, PlantUML

### 10. System Architecture

#### [SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md)

**Purpose**: Overall system design and infrastructure documentation

**Contents**:

- **System Architecture Diagram**: Multi-tier architecture view
  - Client Layer: Flutter mobile app (screens, components)
  - API Gateway Layer: Backend API server with routes and WebSocket
  - Service Layer: Business logic services (KYC, transaction monitoring, credit scoring, voice proxy)
  - Data Layer: MySQL database tables
  - File Storage: KYC document storage
  - External Services: Speechmatics, Google OAuth, SMS, mobile money APIs, Reserve Bank of Malawi
- **Deployment Architecture**: Production deployment setup
  - Load Balancer (Nginx with SSL termination)
  - Application Servers (Node.js instances on port 3000)
  - Database Cluster (Primary + 2 Replicas)
  - Cache Layer (Redis cluster for sessions and data)
  - File Storage (NFS/S3)
  - Monitoring & Logging (Prometheus, Grafana, ELK Stack)
  - Backup System (Daily + S3 storage)
- **Infrastructure Diagram**: Detailed server and network architecture
  - Server specifications
  - Replication setup
  - Health checks
- **Network Architecture**: Security zones and network flow
  - DMZ (Firewall, Load Balancer, WAF)
  - Application Zone (Private network)
  - Database Zone (Private network)
  - Cache Zone (Private network)
  - Storage Zone
- **Component Diagram**: Software components and dependencies
  - Mobile components
  - Backend components
  - Business logic components
  - Data access components
  - External integrations
- **Technology Stack**: Complete technology inventory
  - Frontend: Flutter, Dart, Provider, HTTP, TTS, Speech-to-Text
  - Backend: Node.js, TypeScript, Express, MySQL, Redis, WebSocket, Multer, JWT, Bcrypt
  - DevOps: Docker, Docker Compose, Nginx, PM2, Git, Prometheus, Grafana
  - External: Speechmatics, Google OAuth, Twilio, Mpamba, Airtel Money
- **Security Architecture**: Security layers and measures
  - SSL/TLS encryption
  - WAF protection
  - JWT authentication
  - Rate limiting
  - Input validation
  - Database encryption
  - File encryption
  - Audit logging
- **Scalability Strategy**: Growth handling approach
  - Horizontal scaling (auto-scaling app servers)
  - Database replication
  - Load balancing
  - Caching (Redis)
  - Performance optimization
  - Future enhancements (microservices, Kubernetes)

**Diagram Formats**: Mermaid, PlantUML

## How to Use This Documentation

### For Developers

1. **Start with**: REQUIREMENTS_SPECIFICATION.md to understand what needs to be built
2. **Then review**: USE_CASE_DIAGRAMS.md to see how users interact with the system
3. **Study**: DATABASE_DESIGN.md and UML_CLASS_DIAGRAMS.md for implementation details
4. **Reference**: SEQUENCE_DIAGRAMS.md and ACTIVITY_DIAGRAMS.md when implementing specific features
5. **Consult**: STATE_DIAGRAMS.md for entity lifecycle management
6. **Deploy using**: SYSTEM_ARCHITECTURE.md for infrastructure setup

### For Project Managers

1. **Requirements tracking**: REQUIREMENTS_SPECIFICATION.md has all functional requirements with acceptance criteria
2. **Feature planning**: USE_CASE_DIAGRAMS.md shows complete feature set
3. **Progress monitoring**: Each requirement can be mapped to implementation files

### For Business Analysts

1. **Use case analysis**: USE_CASE_DIAGRAMS.md and REQUIREMENTS_SPECIFICATION.md
2. **Process flows**: ACTIVITY_DIAGRAMS.md and SEQUENCE_DIAGRAMS.md
3. **Business rules**: STATE_DIAGRAMS.md shows business logic for key entities

### For QA/Testers

1. **Test scenarios**: SEQUENCE_DIAGRAMS.md and ACTIVITY_DIAGRAMS.md show expected flows
2. **Acceptance criteria**: REQUIREMENTS_SPECIFICATION.md has detailed acceptance criteria for each requirement
3. **State testing**: STATE_DIAGRAMS.md shows all possible states and transitions to test

### For Architects

1. **System design**: SYSTEM_ARCHITECTURE.md and UML_CLASS_DIAGRAMS.md
2. **Database design**: DATABASE_DESIGN.md with normalization and indexing strategies
3. **Integration points**: SEQUENCE_DIAGRAMS.md shows external API interactions
4. **Scalability**: SYSTEM_ARCHITECTURE.md has scaling strategies

### For Compliance/Auditors

1. **Regulatory compliance**: REQUIREMENTS_SPECIFICATION.md section on compliance requirements
2. **KYC process**: SEQUENCE_DIAGRAMS.md and STATE_DIAGRAMS.md for KYC verification
3. **Audit trail**: DATABASE_DESIGN.md shows audit logging tables
4. **Security measures**: SYSTEM_ARCHITECTURE.md security section

## Rendering Diagrams

### PlantUML Diagrams

PlantUML diagrams can be rendered in:

- **VS Code**: Install "PlantUML" extension
- **IntelliJ IDEA**: Built-in PlantUML support
- **Online**: https://www.plantuml.com/plantuml/uml/
- **Documentation generators**: Sphinx, MkDocs, etc.

### Mermaid Diagrams

Mermaid diagrams can be rendered in:

- **GitHub**: Native support in markdown preview
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
- **Online**: https://mermaid.live/
- **Documentation generators**: MkDocs, GitBook, etc.

## Document Maintenance

### Version Control

- All documentation is version-controlled in Git
- Update diagrams when implementing new features
- Keep requirements in sync with implementation

### Update Frequency

- **Requirements**: Update when scope changes or new features added
- **Use Cases**: Update when user workflows change
- **Database Design**: Update when schema changes
- **Class Diagrams**: Update when adding new classes or major refactoring
- **Sequence/Activity Diagrams**: Update when process flows change
- **State Diagrams**: Update when entity lifecycles change
- **Architecture**: Update when infrastructure or technology stack changes

## Contact

For questions or clarifications about this documentation:

- **Technical questions**: Contact development team
- **Requirements questions**: Contact product owner/business analyst
- **Compliance questions**: Contact legal/compliance team

## Related Documentation

In addition to these design documents, see also:

- `/KYC_IMPLEMENTATION_GUIDE.md` - KYC feature implementation details
- `/KYC_QUICK_REFERENCE.md` - Quick reference for KYC workflows
- `/VOICE_SETUP_GUIDE.md` - Voice control setup instructions
- `/ACCESSIBILITY_GUIDE.md` - Accessibility implementation guide
- `/DEPLOYMENT_GUIDE.md` - Production deployment instructions
- `/DATABASE_SETUP.md` - Database installation and configuration
- `/README.md` - Project overview and quick start

---

**Document Version**: 1.0  
**Last Updated**: January 2025  
**Status**: Complete - Requirements and Design Stage
