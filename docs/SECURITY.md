# InkaWallet Security Documentation

## Overview

InkaWallet implements multiple layers of security to protect user data, transactions, and ensure the integrity of the financial system. This document outlines all security measures implemented in the application.

## Security Architecture

### 1. Authentication & Authorization

#### JWT (JSON Web Tokens)

- **Access Tokens**: Short-lived tokens (1 hour) for API authentication
- **Refresh Tokens**: Long-lived tokens (7 days) stored securely in database
- **Token Rotation**: Automatic token refresh before expiration
- **Secure Storage**: Tokens stored in Flutter Secure Storage (encrypted)

```typescript
// Token Generation
const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: "1h" });
const refreshToken = jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: "7d" });
```

#### Biometric Authentication

- Fingerprint recognition
- Face recognition (where supported)
- Fallback to PIN/Password
- Implemented using Flutter's `local_auth` package

#### Session Management

- 15-minute inactivity timeout
- Automatic logout on suspicious activity
- Device binding (future enhancement)
- Session revocation on logout

### 2. Data Encryption

#### At Rest

- **Sensitive Data**: Encrypted using AES-256-CBC
- **Passwords**: Hashed using bcrypt (12 rounds)
- **Database**: MySQL encryption at rest
- **Local Storage**: Flutter Secure Storage for tokens

```dart
// Encryption Example
String encryptData(String plainText) {
  final key = Key.fromLength(32);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
  return encrypter.encrypt(plainText, iv: iv).base64;
}
```

#### In Transit

- **HTTPS/TLS 1.3**: All API communication encrypted
- **Certificate Pinning**: Prevent man-in-the-middle attacks (recommended)
- **API Headers**: Secure headers with Helmet.js

### 3. Transaction Security

#### Multi-Step Verification

1. **Authentication**: User must be logged in
2. **Balance Check**: Verify sufficient funds
3. **Amount Validation**: Check min/max limits
4. **Confirmation**: User confirmation required
5. **Execution**: Atomic database transaction
6. **Notification**: Real-time feedback

#### Transaction Limits

```typescript
MIN_TRANSACTION_AMOUNT: 100 MWK
MAX_TRANSACTION_AMOUNT: 500,000 MWK
DAILY_TRANSACTION_LIMIT: 1,000,000 MWK
```

#### Database Transactions

```sql
START TRANSACTION;
-- Check balance
-- Deduct from sender
-- Create transaction record
-- Log activity
COMMIT;
-- ROLLBACK on any error
```

### 4. Input Validation & Sanitization

#### Frontend Validation

```dart
// Phone validation
static final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

// Email validation
static final RegExp emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

// Password strength
static final RegExp passwordRegex = RegExp(
  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
);
```

#### Backend Validation

```typescript
// Using express-validator
body("amount").isFloat({ min: 100, max: 500000 }).withMessage("Invalid amount");
```

#### SQL Injection Prevention

- Parameterized queries
- ORM/Query builder
- Input sanitization

```typescript
// Safe query
await db.query("SELECT * FROM users WHERE email = ?", [email]);

// Unsafe (NEVER DO THIS)
await db.query(`SELECT * FROM users WHERE email = '${email}'`);
```

### 5. Rate Limiting & Abuse Prevention

#### API Rate Limiting

```typescript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: "Too many requests",
});
```

#### Login Attempt Limiting

- Maximum 3 failed attempts
- Account locked for 15 minutes
- Logged in `failed_login_attempts` table

#### Brute Force Protection

- Progressive delays after failed attempts
- CAPTCHA after multiple failures (future)
- IP-based blocking for suspicious activity

### 6. Logging & Monitoring

#### Activity Logging

All critical actions are logged:

```sql
CREATE TABLE activity_logs (
  user_id VARCHAR(36),
  action VARCHAR(100),
  resource VARCHAR(100),
  ip_address VARCHAR(45),
  details JSON,
  created_at TIMESTAMP
);
```

#### Logged Events

- User registration
- Login/logout
- Transaction creation
- Balance checks
- Profile updates
- Failed login attempts
- API errors

#### Log Security

- Sensitive data masked
- No passwords in logs
- Secure log storage
- Regular log rotation

```typescript
// Masking example
logger.info("Transaction", {
  userId: user.id,
  amount: transaction.amount,
  recipient: maskSensitiveData(recipient.phone, 4), // +265****0001
});
```

### 7. Database Security

#### Access Control

- Dedicated database user with minimal privileges
- No direct database access from client
- Stored procedures for critical operations
- Row-level security (future enhancement)

#### Backup & Recovery

```bash
# Automated daily backups
mysqldump -u user -p inkawallet_db > backup_$(date +%Y%m%d).sql

# Encrypted backups
mysqldump -u user -p inkawallet_db | gzip | openssl enc -aes-256-cbc -out backup.sql.gz.enc
```

#### Data Integrity

- Foreign key constraints
- Unique constraints
- Check constraints
- Triggers for audit trails

### 8. API Security

#### CORS Configuration

```typescript
app.use(
  cors({
    origin: ["http://localhost:3000", "https://inkawallet.com"],
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE"],
  }),
);
```

#### Security Headers (Helmet)

```typescript
app.use(
  helmet({
    contentSecurityPolicy: true,
    xssFilter: true,
    noSniff: true,
    ieNoOpen: true,
    hsts: true,
  }),
);
```

#### Request Validation

- Content-Type validation
- Request size limits
- Timeout configuration

### 9. Offline Security

#### Local Data Protection

- Encrypted local database
- Secure key storage
- Data expiration
- Automatic sync on reconnection

#### Transaction Queue Security

```dart
// Encrypted offline transactions
final encryptedTransaction = encryptionService.encryptTransaction({
  'recipient': recipient,
  'amount': amount,
  'timestamp': DateTime.now().toIso8601String(),
});

await StorageService.saveTransaction(encryptedTransaction);
```

### 10. Vulnerability Management

#### Regular Updates

- Dependency updates
- Security patches
- Flutter/Node.js updates
- Database updates

#### Security Testing

- [ ] Penetration testing
- [ ] Code security review
- [ ] Dependency vulnerability scanning
- [ ] SQL injection testing
- [ ] XSS testing
- [ ] Authentication bypass testing

#### Vulnerability Disclosure

- Responsible disclosure policy
- Security contact: security@inkawallet.com
- Bug bounty program (future)

## Security Best Practices for Developers

### 1. Never Commit Secrets

```bash
# Use .gitignore
.env
*.key
*.pem
credentials.json
```

### 2. Use Environment Variables

```typescript
const JWT_SECRET = process.env.JWT_SECRET;
// Never: const JWT_SECRET = 'hardcoded_secret';
```

### 3. Validate All Input

```typescript
// Always validate and sanitize
const sanitizedEmail = sanitizeInput(req.body.email);
if (!validateEmail(sanitizedEmail)) {
  throw new ValidationError("Invalid email");
}
```

### 4. Use Prepared Statements

```typescript
// Good
await db.query("SELECT * FROM users WHERE id = ?", [userId]);

// Bad
await db.query(`SELECT * FROM users WHERE id = ${userId}`);
```

### 5. Handle Errors Securely

```typescript
// Don't expose internal details
catch (error) {
  logger.error('Error details', error);
  res.status(500).json({ message: 'Internal server error' });
  // Not: res.status(500).json({ error: error.stack });
}
```

## Compliance & Standards

### GDPR Compliance

- Data minimization
- Right to erasure
- Data portability
- Consent management
- Privacy by design

### PCI DSS (for card integration)

- Secure network
- Protect cardholder data
- Vulnerability management
- Access control
- Regular monitoring

### OWASP Top 10 Mitigation

1. ✅ Injection: Parameterized queries
2. ✅ Broken Authentication: JWT + Biometric
3. ✅ Sensitive Data Exposure: Encryption
4. ✅ XML External Entities: N/A (JSON only)
5. ✅ Broken Access Control: RBAC
6. ✅ Security Misconfiguration: Helmet, strict config
7. ✅ XSS: Input sanitization
8. ✅ Insecure Deserialization: Type validation
9. ✅ Known Vulnerabilities: Regular updates
10. ✅ Insufficient Logging: Comprehensive logging

## Incident Response Plan

### 1. Detection

- Monitor logs for anomalies
- Set up alerts for suspicious activity
- Regular security audits

### 2. Response

- Isolate affected systems
- Investigate breach
- Notify affected users
- Document incident

### 3. Recovery

- Patch vulnerabilities
- Restore from backups
- Reset compromised credentials
- Update security measures

### 4. Post-Incident

- Conduct root cause analysis
- Update security policies
- Train team on lessons learned
- Improve monitoring

## Security Checklist for Production

- [ ] All secrets in environment variables
- [ ] HTTPS enabled with valid certificate
- [ ] Database user has minimal privileges
- [ ] Backups automated and tested
- [ ] Monitoring and alerting configured
- [ ] Rate limiting enabled
- [ ] CORS properly configured
- [ ] Security headers enabled
- [ ] Input validation on all endpoints
- [ ] Error handling doesn't leak information
- [ ] Logs properly configured and secured
- [ ] Dependencies up to date
- [ ] Security audit completed
- [ ] Penetration testing performed
- [ ] Incident response plan documented
- [ ] Team trained on security practices

## Security Contact

For security issues or vulnerabilities:

- Email: security@inkawallet.com
- Response time: Within 24 hours
- Please do NOT open public issues for security vulnerabilities

## Responsible Disclosure

1. Report vulnerability privately
2. Provide detailed description
3. Allow reasonable time to fix
4. Do not exploit vulnerability
5. Receive acknowledgment and credit

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://flutter.dev/docs/deployment/security)
- [Node.js Security Checklist](https://github.com/goldbergyoni/nodebestpractices#6-security-best-practices)
