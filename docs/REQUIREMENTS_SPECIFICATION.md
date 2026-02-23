# InkaWallet Requirements Specification

## 1. Introduction

### 1.1 Purpose

This document specifies the functional and non-functional requirements for InkaWallet, a mobile financial inclusion platform designed for the Malawian market with special focus on accessibility for blind and visually impaired users.

### 1.2 Scope

InkaWallet is a comprehensive mobile wallet application that enables:

- Secure money transfers between users
- Bill payments and airtime purchases
- Buy Now Pay Later (BNPL) services
- Credit scoring and assessment
- KYC verification for regulatory compliance
- Hands-free voice control for accessibility
- Integration with Malawian mobile money providers

### 1.3 Target Users

- **Primary Users**: Unbanked and underbanked population in Malawi
- **Secondary Users**: Blind and visually impaired individuals requiring accessible financial services
- **Administrative Users**: KYC verification officers and system administrators
- **Regulatory Users**: Reserve Bank of Malawi compliance officers

### 1.4 Definitions and Acronyms

- **KYC**: Know Your Customer
- **BNPL**: Buy Now Pay Later
- **2FA**: Two-Factor Authentication
- **TTS**: Text-to-Speech
- **MKW**: Malawian Kwacha
- **RBM**: Reserve Bank of Malawi
- **FIA**: Financial Intelligence Authority
- **AML**: Anti-Money Laundering
- **CFT**: Combating the Financing of Terrorism
- **PEP**: Politically Exposed Person

## 2. Functional Requirements

### 2.1 User Authentication (FR-AUTH)

#### FR-AUTH-001: User Registration

**Priority**: Critical  
**Description**: Users must be able to create a new account with email, phone number, and password.

**Acceptance Criteria**:

- System validates email format (RFC 5322 standard)
- System validates phone number format (+265 followed by 9 digits)
- Password must meet minimum requirements:
  - Minimum 8 characters
  - At least one uppercase letter
  - At least one lowercase letter
  - At least one number
  - At least one special character
- System checks for duplicate email/phone before registration
- System sends verification SMS to phone number
- Password is hashed using bcrypt (10 rounds) before storage
- JWT token is generated upon successful registration
- User is automatically logged in after registration

**Related Use Cases**: UC-001 (Register Account)

#### FR-AUTH-002: Email/Password Login

**Priority**: Critical  
**Description**: Users must be able to log in using registered email and password.

**Acceptance Criteria**:

- System validates email and password format
- System compares hashed password using bcrypt
- Maximum 5 failed login attempts before 15-minute lockout
- Successful login generates JWT token (24-hour expiry)
- System logs login activity (IP address, device, timestamp)
- Failed login attempts are logged for security monitoring

**Related Use Cases**: UC-002 (Login)

#### FR-AUTH-003: Biometric Authentication

**Priority**: High  
**Description**: Users can optionally enable fingerprint or face ID for quick login.

**Acceptance Criteria**:

- System detects biometric hardware availability
- User credentials are encrypted and stored in secure storage
- Biometric verification uses device native APIs
- Fallback to email/password if biometric fails
- User can disable biometric login at any time
- Maximum 3 failed biometric attempts before fallback

**Related Use Cases**: UC-003 (Enable Biometric Login)

#### FR-AUTH-004: Two-Factor Authentication (2FA)

**Priority**: High  
**Description**: Users can enable 2FA for additional security.

**Acceptance Criteria**:

- System generates 6-digit numeric code
- Code expires after 10 minutes
- Code is sent via SMS to registered phone
- User must enter code within expiry time
- Maximum 3 code verification attempts
- Code is single-use only
- System marks code as used after successful verification

**Related Use Cases**: UC-004 (Enable 2FA)

#### FR-AUTH-005: Google OAuth Login

**Priority**: Medium  
**Description**: Users can register/login using Google account.

**Acceptance Criteria**:

- Integration with Google OAuth 2.0
- System retrieves email, name from Google profile
- User account is created if email doesn't exist
- Existing account is linked if email matches
- User profile picture is downloaded and stored
- OAuth tokens are stored securely

**Related Use Cases**: UC-005 (Google OAuth Login)

#### FR-AUTH-006: Password Reset

**Priority**: High  
**Description**: Users can reset forgotten password via email/SMS.

**Acceptance Criteria**:

- User enters registered email or phone
- System generates unique reset token (valid 1 hour)
- Reset link sent via email
- Reset code sent via SMS
- User must verify identity before setting new password
- Old password becomes invalid after reset

### 2.2 Wallet Management (FR-WALLET)

#### FR-WALLET-001: View Balance

**Priority**: Critical  
**Description**: Users can view their current wallet balance.

**Acceptance Criteria**:

- Balance is displayed in MKW currency format
- Balance is real-time (updated after each transaction)
- User can toggle balance visibility (show/hide)
- Balance includes pending transactions indicator
- System maintains transaction-level precision (2 decimal places)

**Related Use Cases**: UC-006 (Check Balance)

#### FR-WALLET-002: Top Up Wallet

**Priority**: Critical  
**Description**: Users can add money to wallet via mobile money or bank transfer.

**Acceptance Criteria**:

- Integration with Mpamba API
- Integration with Airtel Money API
- User selects top-up method (Mpamba, Airtel Money, Bank)
- Minimum top-up amount: MKW 100
- Maximum top-up amount: MKW 500,000 per transaction
- Transaction confirmation via push notification
- Balance updates immediately upon confirmation
- Top-up fees are clearly displayed before confirmation

**Related Use Cases**: UC-007 (Top Up Wallet)

#### FR-WALLET-003: Transaction History

**Priority**: High  
**Description**: Users can view complete transaction history.

**Acceptance Criteria**:

- Transactions displayed in reverse chronological order
- Filter by transaction type (send, receive, airtime, bills, BNPL)
- Filter by date range (today, week, month, custom)
- Search by recipient name or amount
- Export transaction history as PDF
- Each transaction shows:
  - Date and time
  - Transaction type
  - Amount
  - Recipient/sender name
  - Status (completed, pending, failed)
  - Transaction reference number

**Related Use Cases**: UC-008 (View Transactions)

### 2.3 Money Transfer (FR-TRANSFER)

#### FR-TRANSFER-001: Send Money to User

**Priority**: Critical  
**Description**: Users can send money to other InkaWallet users.

**Acceptance Criteria**:

- User selects recipient from contacts or enters phone number
- System validates recipient exists and account is active
- User enters amount and optional description
- System validates sufficient balance
- System checks KYC limits before processing
- User confirms transaction details
- Biometric authentication required for amounts > MKW 10,000
- Transaction is atomic (all-or-nothing database operation)
- Both sender and receiver receive instant notifications
- Transaction reference number is generated

**Related Use Cases**: UC-009 (Send Money)

#### FR-TRANSFER-002: Receive Money

**Priority**: Critical  
**Description**: Users can receive money from other users.

**Acceptance Criteria**:

- Money is credited instantly to wallet
- Push notification sent immediately
- In-app notification added to notification center
- Balance is updated in real-time
- Transaction appears in history
- Sender information is displayed

**Related Use Cases**: UC-010 (Receive Money)

#### FR-TRANSFER-003: Request Money

**Priority**: Medium  
**Description**: Users can request money from other users.

**Acceptance Criteria**:

- User selects contact and enters amount
- Recipient receives request notification
- Recipient can accept or decline request
- Accepted request triggers normal send money flow
- Request expires after 7 days if not responded
- User can cancel pending requests

**Related Use Cases**: UC-011 (Request Money)

#### FR-TRANSFER-004: QR Code Payment

**Priority**: High  
**Description**: Users can send/receive money using QR codes.

**Acceptance Criteria**:

- User can generate personal QR code
- QR code contains user ID and optional amount
- Camera scans QR codes in good lighting
- Amount can be pre-filled in QR or entered by sender
- QR code payment follows same validation as send money
- Voice guidance for blind users during QR scan

**Related Use Cases**: UC-012 (Pay with QR)

### 2.4 KYC Verification (FR-KYC)

#### FR-KYC-001: Create KYC Profile

**Priority**: Critical  
**Description**: Users must complete KYC profile for regulatory compliance.

**Acceptance Criteria**:

- Required fields:
  - First name, last name
  - Date of birth (must be 18+ years)
  - National ID number (unique)
  - Gender
  - Address (physical)
  - Occupation
- Optional fields:
  - Disability type (visual, hearing, mobility, other)
  - Alternative contact person
- System validates national ID format (XXXX-XXXX-XXXX)
- System checks for duplicate national IDs
- Profile is saved as draft before document upload

**Related Use Cases**: UC-024 (Submit KYC Profile)

#### FR-KYC-002: Upload KYC Documents

**Priority**: Critical  
**Description**: Users must upload identity verification documents.

**Acceptance Criteria**:

- Required documents (minimum 2):
  - National ID (front and back)
  - Selfie photo
  - Proof of address (utility bill, bank statement)
- Supported formats: JPEG, PNG, PDF
- Maximum file size: 10 MB per document
- Camera integration with voice guidance
- Gallery selection option
- Document preview before upload
- Upload progress indicator
- Retry option for failed uploads

**Related Use Cases**: UC-025 (Upload Documents)

#### FR-KYC-003: Submit KYC for Verification

**Priority**: Critical  
**Description**: Users submit completed KYC for admin review.

**Acceptance Criteria**:

- Minimum 2 documents required
- Profile must be complete
- Status changes to "pending_verification"
- Admin team receives notification
- User receives submission confirmation
- Estimated review time: 24-48 hours
- User cannot modify profile while pending

**Related Use Cases**: UC-026 (Submit for Verification)

#### FR-KYC-004: Admin Verify KYC

**Priority**: Critical  
**Description**: Admins review and approve/reject KYC submissions.

**Acceptance Criteria**:

- Admin can view all pending KYCs
- Admin reviews:
  - Document authenticity
  - Photo quality
  - ID-Selfie match
  - Address verification
  - Age verification (18+)
  - AML/CFT checks
  - PEP database check
- Admin assigns verification tier:
  - Tier 1: Basic documents (MKW 50K daily limit)
  - Tier 2: Enhanced documents (MKW 200K daily limit)
  - Tier 3: Complete verification (unlimited)
- Admin provides rejection reason if rejected
- User receives verification result notification
- Verification history is logged
- RBM compliance report generated

**Related Use Cases**: UC-027 (Verify KYC - Admin)

#### FR-KYC-005: Transaction Limit Enforcement

**Priority**: Critical  
**Description**: System enforces transaction limits based on KYC tier.

**Acceptance Criteria**:

- Tier 1 limits:
  - Daily: MKW 50,000
  - Monthly: MKW 500,000
- Tier 2 limits:
  - Daily: MKW 200,000
  - Monthly: MKW 2,000,000
- Tier 3 limits:
  - Unlimited
- System tracks daily and monthly totals
- Limits reset at midnight (daily) and 1st of month (monthly)
- Transaction is blocked if limit exceeded
- User sees remaining limit before transaction

**Related Use Cases**: UC-028 (Check Transaction Limits)

### 2.5 Buy Now Pay Later (FR-BNPL)

#### FR-BNPL-001: Apply for BNPL Loan

**Priority**: High  
**Description**: Users can apply for short-term BNPL loans.

**Acceptance Criteria**:

- KYC verification required (Tier 1 minimum)
- Credit score requirement: 550+ (Good or higher)
- Loan options:
  - 4 weeks (5% interest)
  - 8 weeks (8% interest)
  - 12 weeks (10% interest)
- Minimum loan: MKW 1,000
- Maximum loan based on credit score:
  - 550-649: MKW 10,000
  - 650-749: MKW 50,000
  - 750+: MKW 100,000
- Loan amount added to wallet immediately
- Payment schedule generated
- User receives loan agreement

**Related Use Cases**: UC-013 (Apply BNPL)

#### FR-BNPL-002: BNPL Payment

**Priority**: High  
**Description**: Users make scheduled BNPL payments.

**Acceptance Criteria**:

- Weekly installments calculated automatically
- Payment due notifications 2 days before
- Auto-debit option from wallet
- Manual payment option
- Partial payments not allowed
- Payment updates loan balance
- Credit score updated on payment
- Completion notification when fully paid

**Related Use Cases**: UC-014 (Pay BNPL Installment)

#### FR-BNPL-003: Overdue BNPL Handling

**Priority**: High  
**Description**: System handles overdue BNPL payments.

**Acceptance Criteria**:

- Late fee: 2% per week overdue
- Credit score penalty: -50 points per missed payment
- Overdue notifications daily
- Account restrictions after 30 days overdue:
  - Cannot apply for new loans
  - Cannot send money
  - Receive only mode
- Default status after 60 days
- Report to credit bureau
- Debt collection process initiated

**Related Use Cases**: UC-015 (Handle Overdue BNPL)

### 2.6 Credit Scoring (FR-CREDIT)

#### FR-CREDIT-001: Calculate Credit Score

**Priority**: High  
**Description**: System calculates user credit score based on activity.

**Acceptance Criteria**:

- Score range: 300-850
- Factors considered:
  - Transaction history (weight: 30%)
  - BNPL repayment history (weight: 40%)
  - Account age (weight: 10%)
  - Average balance (weight: 10%)
  - KYC tier (weight: 10%)
- Score updated:
  - After each BNPL payment
  - After KYC tier change
  - Weekly for transaction activity
- Score categories:
  - 300-549: Poor
  - 550-649: Fair
  - 650-749: Good
  - 750-850: Excellent

**Related Use Cases**: UC-016 (Calculate Credit Score)

#### FR-CREDIT-002: View Credit Score

**Priority**: Medium  
**Description**: Users can view their current credit score.

**Acceptance Criteria**:

- Score displayed with rating (Poor, Fair, Good, Excellent)
- Score history chart (last 6 months)
- Factors affecting score shown
- Tips to improve score
- Score update date displayed

**Related Use Cases**: UC-017 (View Credit Score)

### 2.7 Voice Control (FR-VOICE)

#### FR-VOICE-001: Wake Word Detection

**Priority**: High  
**Description**: System listens for "Inka" wake word to activate voice control.

**Acceptance Criteria**:

- Local wake word detection (no internet required)
- Wake word: "Inka" (case-insensitive)
- Detection accuracy: 95%+
- Background noise filtering
- Low power consumption
- TTS confirmation: "Listening..."
- Haptic feedback on detection

**Related Use Cases**: UC-020 (Use Voice Commands)

#### FR-VOICE-002: Voice Command Processing

**Priority**: High  
**Description**: System processes natural language voice commands.

**Acceptance Criteria**:

- Speechmatics API integration for transcription
- Real-time streaming transcription
- Commands supported:
  - "Check my balance"
  - "Send money to [name]"
  - "Pay bills"
  - "Buy airtime"
  - "Request money from [name]"
  - "Check transactions"
  - "Help"
- Intent extraction from natural language
- Parameter extraction (names, amounts)
- Interactive dialogue for missing parameters
- Command timeout: 5 seconds of silence

**Related Use Cases**: UC-021 (Process Voice Command)

#### FR-VOICE-003: Text-to-Speech Feedback

**Priority**: High  
**Description**: System provides audio feedback for all actions.

**Acceptance Criteria**:

- Flutter TTS integration
- Clear speech at adjustable speed
- Feedback for all user actions:
  - Button presses
  - Transaction confirmations
  - Error messages
  - Balance updates
- Language: English (Malawian accent preferred)
- Volume follows system settings
- Can be muted in settings

**Related Use Cases**: UC-022 (Voice Feedback)

### 2.8 Bills and Services (FR-BILLS)

#### FR-BILLS-001: Pay Utility Bills

**Priority**: High  
**Description**: Users can pay electricity, water, and other utility bills.

**Acceptance Criteria**:

- Supported utilities:
  - ESCOM (Electricity)
  - Lilongwe Water Board
  - Blantyre Water Board
  - MACRA (Communications)
- User enters account number
- System fetches bill amount
- User confirms payment
- Payment processed via wallet
- Receipt generated and emailed
- Bill marked as paid in utility system

**Related Use Cases**: UC-018 (Pay Bills)

#### FR-BILLS-002: Buy Airtime

**Priority**: High  
**Description**: Users can purchase mobile airtime.

**Acceptance Criteria**:

- Supported networks:
  - TNM
  - Airtel Malawi
- User selects network
- User enters amount (min: MKW 100, max: MKW 10,000)
- Airtime delivered within 30 seconds
- Confirmation SMS sent
- Transaction recorded in history

**Related Use Cases**: UC-019 (Buy Airtime)

### 2.9 Notifications (FR-NOTIF)

#### FR-NOTIF-001: Push Notifications

**Priority**: Medium  
**Description**: Users receive push notifications for important events.

**Acceptance Criteria**:

- Notification triggers:
  - Money received
  - Money sent confirmation
  - BNPL payment due
  - KYC status change
  - Login from new device
  - Low balance warning
- Push delivery within 5 seconds of event
- User can enable/disable by category
- Notification badge on app icon
- Rich notifications with actions

**Related Use Cases**: UC-023 (Manage Notifications)

#### FR-NOTIF-002: In-App Notifications

**Priority**: Medium  
**Description**: Users can view notification history in app.

**Acceptance Criteria**:

- Notification center with unread count
- Notifications sorted by date (newest first)
- Filter by category
- Mark as read/unread
- Swipe to delete
- Tap notification to navigate to relevant screen
- Notifications expire after 30 days

**Related Use Cases**: UC-023 (Manage Notifications)

### 2.10 Admin Functions (FR-ADMIN)

#### FR-ADMIN-001: Admin Dashboard

**Priority**: Medium  
**Description**: Admins can view system analytics and metrics.

**Acceptance Criteria**:

- Total users count
- Total transaction volume (today, week, month)
- Pending KYC count
- Active BNPL loans
- Default rate
- Average credit score
- Charts and graphs for trends

**Related Use Cases**: UC-029 (Admin Dashboard)

#### FR-ADMIN-002: User Management

**Priority**: Medium  
**Description**: Admins can manage user accounts.

**Acceptance Criteria**:

- View all users with search and filter
- View user details and transaction history
- Suspend/activate user accounts
- Reset user passwords
- View user KYC status
- View user credit score
- Export user data

**Related Use Cases**: UC-030 (Manage Users)

## 3. Non-Functional Requirements

### 3.1 Performance Requirements (NFR-PERF)

#### NFR-PERF-001: Response Time

**Priority**: High  
**Description**: System must respond to user actions within acceptable time limits.

**Metrics**:

- Page load: < 2 seconds
- API requests: < 500ms average
- Database queries: < 200ms average
- Money transfer: < 3 seconds end-to-end
- Voice command response: < 1 second

#### NFR-PERF-002: Throughput

**Priority**: High  
**Description**: System must handle concurrent users and transactions.

**Metrics**:

- Support 10,000 concurrent users
- Process 100 transactions per second
- Handle 1,000 API requests per second
- Scale horizontally to 50,000 users

#### NFR-PERF-003: Database Performance

**Priority**: High  
**Description**: Database must perform efficiently under load.

**Metrics**:

- Connection pool: 50 connections
- Query cache: 80% hit rate
- Index usage: 95% of queries
- Read replica lag: < 1 second

### 3.2 Security Requirements (NFR-SEC)

#### NFR-SEC-001: Data Encryption

**Priority**: Critical  
**Description**: Sensitive data must be encrypted at rest and in transit.

**Requirements**:

- HTTPS/TLS 1.3 for all API communication
- AES-256 encryption for PII in database
- Bcrypt (10 rounds) for password hashing
- SSL certificate pinning in mobile app
- Encrypted file storage for KYC documents

#### NFR-SEC-002: Authentication Security

**Priority**: Critical  
**Description**: User authentication must be secure.

**Requirements**:

- JWT tokens with 24-hour expiry
- Refresh tokens with 7-day expiry
- Token revocation on logout
- Session timeout after 30 minutes idle
- Rate limiting: 5 login attempts per 15 minutes
- IP-based suspicious activity detection

#### NFR-SEC-003: Authorization

**Priority**: Critical  
**Description**: Access control must be enforced.

**Requirements**:

- Role-based access control (RBAC)
- Roles: user, admin, super_admin
- JWT contains user roles
- Middleware validates permissions
- Database row-level security for multi-tenancy

#### NFR-SEC-004: Audit Logging

**Priority**: High  
**Description**: Security events must be logged.

**Requirements**:

- Log all authentication attempts
- Log all transactions
- Log KYC status changes
- Log admin actions
- Logs retained for 2 years
- Tamper-proof audit trail

### 3.3 Reliability Requirements (NFR-REL)

#### NFR-REL-001: Availability

**Priority**: Critical  
**Description**: System must be available 24/7.

**Metrics**:

- Uptime: 99.9% (maximum 8.76 hours downtime per year)
- Scheduled maintenance: < 4 hours per month
- Unscheduled downtime: < 1 hour per month

#### NFR-REL-002: Fault Tolerance

**Priority**: High  
**Description**: System must handle failures gracefully.

**Requirements**:

- Database replication (1 primary, 2 replicas)
- Auto-failover to replica if primary fails
- Load balancer health checks every 10 seconds
- Circuit breaker pattern for external APIs
- Graceful degradation (core features work if secondary fails)

#### NFR-REL-003: Data Backup

**Priority**: Critical  
**Description**: Data must be backed up regularly.

**Requirements**:

- Full backup: Daily at 2 AM
- Incremental backup: Every 6 hours
- Backup retention: 30 days
- Offsite backup storage (S3)
- Backup encryption: AES-256
- Backup restore test: Monthly

### 3.4 Accessibility Requirements (NFR-ACCESS)

#### NFR-ACCESS-001: Screen Reader Compatibility

**Priority**: Critical  
**Description**: App must work with screen readers.

**Requirements**:

- All UI elements have semantic labels
- Navigation order is logical
- Form fields have labels and hints
- Buttons have descriptive names
- Images have alternative text
- Voice control as primary input method for blind users

#### NFR-ACCESS-002: Voice Control

**Priority**: Critical  
**Description**: All core functions accessible via voice.

**Requirements**:

- Hands-free operation via wake word
- Natural language understanding
- Voice feedback for all actions
- No reliance on visual confirmation
- Haptic feedback for action confirmation

#### NFR-ACCESS-003: Visual Accessibility

**Priority**: High  
**Description**: App must support visual impairments.

**Requirements**:

- Support system font scaling (100-200%)
- High contrast mode
- Color blind friendly (no color-only information)
- Minimum touch target: 44x44 dp
- Clear focus indicators

### 3.5 Usability Requirements (NFR-USE)

#### NFR-USE-001: Learning Curve

**Priority**: High  
**Description**: Users should learn the app quickly.

**Metrics**:

- New users complete first transaction within 5 minutes
- Voice command recognition: 95% accuracy
- In-app help and tutorials
- Contextual tooltips

#### NFR-USE-002: Error Handling

**Priority**: High  
**Description**: Errors must be user-friendly.

**Requirements**:

- Clear error messages (no technical jargon)
- Suggested solutions for errors
- Voice announcement of errors
- Retry options for failed actions
- Preserve user input on errors

### 3.6 Compliance Requirements (NFR-COMP)

#### NFR-COMP-001: Regulatory Compliance

**Priority**: Critical  
**Description**: System must comply with Malawian financial regulations.

**Requirements**:

- Reserve Bank of Malawi (RBM) compliance
- Financial Intelligence Authority (FIA) reporting
- AML/CFT regulations compliance
- KYC requirements as per RBM guidelines
- Transaction monitoring and suspicious activity reporting

#### NFR-COMP-002: Data Privacy

**Priority**: Critical  
**Description**: System must protect user privacy.

**Requirements**:

- GDPR-like data protection
- User consent for data collection
- Right to access personal data
- Right to delete account and data
- Data minimization (collect only necessary data)
- Privacy policy and terms of service

### 3.7 Scalability Requirements (NFR-SCALE)

#### NFR-SCALE-001: Horizontal Scaling

**Priority**: High  
**Description**: System must scale horizontally.

**Requirements**:

- Stateless application servers
- Load balancer distributes traffic
- Database read replicas for scaling reads
- Redis cache for session and data caching
- Auto-scaling based on CPU/memory metrics

#### NFR-SCALE-002: Data Growth

**Priority**: High  
**Description**: System must handle data growth.

**Requirements**:

- Database partitioning strategy
- Archive old transactions (> 2 years)
- File storage with CDN for KYC documents
- Efficient indexing strategy
- Query optimization

### 3.8 Maintainability Requirements (NFR-MAINT)

#### NFR-MAINT-001: Code Quality

**Priority**: Medium  
**Description**: Code must be maintainable.

**Requirements**:

- TypeScript for type safety
- ESLint for code linting
- Code coverage: > 70%
- Documentation for all APIs
- Meaningful variable and function names

#### NFR-MAINT-002: Deployment

**Priority**: Medium  
**Description**: Deployment must be automated.

**Requirements**:

- CI/CD pipeline (GitHub Actions)
- Automated testing on commits
- Docker containers for deployment
- Zero-downtime deployment
- Rollback capability

## 4. System Constraints

### 4.1 Technology Constraints

- Mobile app: Flutter 3.x, Dart 3.x
- Backend: Node.js 18+, TypeScript 5.x
- Database: MySQL 8.0
- Cache: Redis 7.x
- Voice AI: Speechmatics API

### 4.2 Business Constraints

- Must comply with Malawian banking regulations
- Must integrate with existing mobile money providers
- Must support offline mode for basic features
- Must be free for end users (revenue from transaction fees)

### 4.3 Hardware Constraints

- Android: SDK 21+ (Android 5.0+)
- iOS: iOS 11+
- Minimum 2GB RAM
- Camera for QR and document capture
- Microphone for voice control

## 5. Acceptance Criteria

### 5.1 User Acceptance

- 95% user satisfaction score
- 90% task completion rate
- < 5% error rate in transactions
- Voice command accuracy: 95%

### 5.2 Performance Acceptance

- 99.9% uptime
- < 500ms average API response time
- Support 10,000 concurrent users
- < 3 seconds for money transfer

### 5.3 Security Acceptance

- Pass penetration testing
- No critical vulnerabilities
- Compliance with RBM security standards
- Successful security audit

## 6. Appendix

### 6.1 References

- Reserve Bank of Malawi: https://www.rbm.mw/
- Financial Intelligence Authority: https://www.fia.gov.mw/
- Speechmatics API: https://www.speechmatics.com/

### 6.2 Glossary

- **Wallet**: Digital account holding user funds
- **Transaction**: Any money movement (send, receive, pay)
- **KYC Tier**: Verification level determining transaction limits
- **Credit Score**: Numerical representation of user creditworthiness
- **BNPL**: Short-term loan with weekly repayments
- **Wake Word**: Voice trigger phrase ("Inka") to activate voice control
