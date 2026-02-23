# KYC (Know Your Customer) Implementation Guide

## InkaWallet - Malawi Regulatory Compliance

---

## Overview

InkaWallet has implemented a comprehensive KYC (Know Your Customer) system to comply with:

- **Reserve Bank of Malawi** regulations
- **Financial Intelligence Authority (FIA)** requirements
- **Anti-Money Laundering (AML)** standards
- **Counter Financing of Terrorism (CFT)** guidelines

This system is designed for **inclusive finance**, supporting people with disabilities and the unbanked/underbanked population.

---

## Regulatory Framework

### Reserve Bank of Malawi Requirements

InkaWallet must verify customer identity for:

- All new wallet accounts
- Transactions exceeding MKW 50,000
- Monthly transaction volumes
- High-risk transactions

### Verification Tiers

#### Tier 1 - Basic (Default)

- **Daily Limit**: MKW 50,000
- **Monthly Limit**: MKW 500,000
- **Requirements**:
  - National ID OR Passport OR Driver's License OR Voter's ID
  - Proof of address (utility bill, bank statement)
  - Selfie for verification
- **Processing Time**: 24-48 hours

#### Tier 2 - Enhanced

- **Daily Limit**: MKW 200,000
- **Monthly Limit**: MKW 2,000,000
- **Additional Requirements**:
  - Employment letter or business registration
  - Bank reference letter
  - Enhanced due diligence
- **Processing Time**: 3-5 business days

#### Tier 3 - Full

- **Daily Limit**: Unlimited
- **Monthly Limit**: Unlimited
- **Additional Requirements**:
  - Face-to-face verification
  - Source of wealth documentation
  - Enhanced monitoring
- **Processing Time**: 5-7 business days

---

## Database Schema

### Tables Created

1. **kyc_profiles** - Main KYC information
   - Personal details (name, DOB, gender, nationality)
   - Identification numbers (national ID, passport, etc.)
   - Address information (residential, city, district, region)
   - Employment details (occupation, employer, income range)
   - Source of funds (salary, business, agriculture, etc.)
   - Disability & accessibility support
   - Next of kin information
   - Verification status and limits
   - Risk rating and PEP status

2. **kyc_documents** - Uploaded verification documents
   - Document types (ID, passport, proof of address, selfie, etc.)
   - File storage paths
   - Verification status
   - Accessibility formats (audio descriptions, sign language videos)

3. **kyc_verification_history** - Audit trail
   - All KYC actions (created, submitted, verified, rejected, etc.)
   - Admin actions
   - Status changes
   - IP addresses

4. **transaction_monitoring** - AML/CFT compliance
   - Daily/monthly transaction totals
   - Suspicious activity flags
   - Investigation tracking

5. **beneficiaries** - Frequent recipients tracking
   - Enhanced due diligence for regular transfers
   - Business beneficiary information

---

## API Endpoints

### User Endpoints

#### Get KYC Profile

```
GET /api/kyc/profile
Authorization: Bearer <token>
```

#### Create/Update KYC Profile

```
POST /api/kyc/profile
Authorization: Bearer <token>
Content-Type: application/json

Body: {
  "first_name": "John",
  "last_name": "Banda",
  "date_of_birth": "1990-01-15",
  "gender": "male",
  "nationality": "Malawian",
  "national_id": "12345-67-8",
  "residential_address": "123 Main Street",
  "city": "Lilongwe",
  "district": "Lilongwe",
  "region": "Central",
  "occupation": "Teacher",
  "source_of_funds": "salary",
  "has_disability": false,
  "disability_type": "none",
  "preferred_communication": "voice",
  "next_of_kin_name": "Jane Banda",
  "next_of_kin_relationship": "Sister",
  "next_of_kin_phone": "+265999123456",
  "pep_status": false
}
```

#### Upload Document

```
POST /api/kyc/documents
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- document: [file]
- document_type: "national_id_front" | "national_id_back" | "passport" | "proof_of_address" | "selfie" | etc.
- is_audio_description: false
- has_sign_language_video: false
```

#### Get Uploaded Documents

```
GET /api/kyc/documents
Authorization: Bearer <token>
```

#### Submit for Verification

```
POST /api/kyc/submit
Authorization: Bearer <token>
```

#### Get KYC Status

```
GET /api/kyc/status
Authorization: Bearer <token>
```

#### Check Transaction Limits

```
POST /api/kyc/check-limits
Authorization: Bearer <token>
Content-Type: application/json

Body: {
  "amount": 75000
}

Response: {
  "allowed": true,
  "verification_level": "tier1",
  "daily_limit": 50000,
  "daily_used": 10000,
  "daily_remaining": 40000,
  "monthly_limit": 500000,
  "monthly_used": 120000,
  "monthly_remaining": 380000
}
```

### Admin Endpoints

#### Get Pending Verifications

```
GET /api/kyc/admin/pending
Authorization: Bearer <admin-token>
```

#### Verify/Reject KYC

```
PUT /api/kyc/admin/verify/:kycProfileId
Authorization: Bearer <admin-token>
Content-Type: application/json

Body (Approve): {
  "action": "verify",
  "verification_level": "tier1",
  "daily_limit": 50000,
  "monthly_limit": 500000
}

Body (Reject): {
  "action": "reject",
  "rejection_reason": "Document not clear. Please resubmit."
}
```

---

## Mobile Screens

### 1. KYC Profile Screen (`kyc_profile_screen.dart`)

- Comprehensive form for personal information
- At least one ID required validation
- Disability & accessibility support section
- Next of kin information
- PEP declaration
- **Voice guidance**: All fields accessible via voice control
- **Auto-save**: Progress saved locally

### 2. KYC Document Upload Screen (`kyc_document_upload_screen.dart`)

- Camera/gallery selection
- Voice-guided photo capture
- Document type selection
- Upload progress indicators
- Minimum 2 documents required
- **Accessibility**: Voice announcements for camera positioning
- **Formats**: JPEG, PNG, PDF (max 10MB)

### 3. KYC Status Screen (`kyc_status_screen.dart`)

- Real-time verification status
- Transaction limits display
- Tier information
- Rejection reasons (if applicable)
- Benefits overview
- Tier upgrade options

### 4. KYC Service (`kyc_service.dart`)

- Transaction limit checks before operations
- KYC status queries
- Verification level checks

---

## Accessibility Features

### For Blind/Visually Impaired Users

1. **Voice-Guided Document Capture**
   - "Position ID card in frame"
   - "Hold still"
   - "Document captured successfully"

2. **Audio Descriptions**
   - All steps announced clearly
   - Error messages spoken
   - Success confirmations

3. **Alternative Input Methods**
   - Voice input for text fields
   - Verbal description of documents
   - Assisted verification option

### For Users with Other Disabilities

1. **Sign Language Support**
   - Video upload option for sign language users
   - Visual instructions

2. **Cognitive Accessibility**
   - Simple, clear instructions
   - Step-by-step process
   - Progress indicators

3. **Physical Disabilities**
   - Large touch targets
   - Assistance request option
   - Extended timeout for form completion

---

## Transaction Limits Enforcement

### Integration Points

All transaction endpoints must check KYC limits:

```typescript
// Example in transaction route
router.post("/send-money", authenticateToken, async (req, res) => {
  const { amount, receiverId } = req.body;

  // Check KYC limits
  const kycCheck = await checkKycLimits(req.user.userId, amount);

  if (!kycCheck.allowed) {
    return res.status(403).json({
      message: kycCheck.message,
      daily_limit: kycCheck.daily_limit,
      monthly_limit: kycCheck.monthly_limit,
      kyc_status: kycCheck.kyc_status,
    });
  }

  // Proceed with transaction...
});
```

### Mobile Integration

```dart
// Before any transaction
final kycCheck = await _kycService.checkTransactionLimits(amount);

if (!kycCheck['success']) {
  // Show KYC prompt
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('KYC Required'),
      content: Text(kycCheck['data']['message']),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/kyc-status'),
          child: Text('Complete KYC'),
        ),
      ],
    ),
  );
  return;
}

// Proceed with transaction
```

---

## AML/CFT Monitoring

### Suspicious Activity Detection

The system automatically flags transactions for:

1. **Velocity Checks**
   - Multiple transactions in short time
   - Unusual transaction patterns

2. **Amount Thresholds**
   - Single transactions > MKW 1,000,000
   - Daily total > 150% of limit

3. **Geographic Patterns**
   - Transactions to high-risk countries
   - Cross-border transfers

4. **Behavioral Analysis**
   - Sudden changes in transaction patterns
   - Dormant accounts suddenly active

### Admin Monitoring Dashboard

Administrators can:

- View flagged transactions
- Investigate suspicious activity
- Mark accounts for enhanced monitoring
- Generate compliance reports

---

## Document Requirements by Region

### All Regions (Malawi)

- **Primary ID**: National ID (mandatory for citizens)
- **Alternative IDs**: Passport, Driver's License, Voter's ID
- **Proof of Address**: Utility bill (ESCOM, water), bank statement, lease agreement
- **Selfie**: Recent photo for biometric matching

### For Foreign Nationals

- **Passport**: Mandatory
- **Visa/Residence Permit**: Current and valid
- **Work Permit**: For employed foreigners
- **Proof of Address**: Same as citizens

### For Businesses

- **Business Registration Certificate**
- **Tax Clearance Certificate**
- **Director IDs**: All directors' identification
- **Proof of Physical Address**

---

## Testing Guide

### Test User Flow

1. **Register New Account**

   ```
   POST /api/auth/register
   ```

2. **Complete KYC Profile**

   ```
   POST /api/kyc/profile
   ```

3. **Upload Documents**

   ```
   POST /api/kyc/documents (at least 2)
   ```

4. **Submit for Verification**

   ```
   POST /api/kyc/submit
   ```

5. **Admin Verification** (as admin)

   ```
   GET /api/kyc/admin/pending
   PUT /api/kyc/admin/verify/:id
   ```

6. **Check Transaction Limits**
   ```
   POST /api/kyc/check-limits
   ```

### Test Scenarios

#### Scenario 1: Verified User

- Status: `verified`
- Tier: `tier1`
- Daily Limit: MKW 50,000
- Expected: Can transact up to limit

#### Scenario 2: Unverified User

- Status: `not_started` or `incomplete`
- Expected: Restricted to basic features only

#### Scenario 3: Pending User

- Status: `pending_verification`
- Expected: Limited transactions, awaiting approval

#### Scenario 4: Rejected User

- Status: `rejected`
- Reason: Displayed to user
- Expected: Can resubmit with corrections

---

## Security Considerations

### Data Protection

1. **Encryption**
   - All KYC data encrypted at rest
   - SSL/TLS for data in transit
   - Secure file storage

2. **Access Control**
   - Only admin users can view/verify KYC
   - Audit logs for all access
   - IP address tracking

3. **Document Security**
   - Files stored outside web root
   - Unique filenames (not user-predictable)
   - Regular security scans

### Privacy Compliance

- GDPR-aligned data handling
- User consent required
- Right to data access
- Right to data deletion
- Data retention policies

---

## Deployment Checklist

- [x] Database schema created (kyc_schema.sql)
- [x] API routes implemented (kyc.routes.ts)
- [x] Mobile screens created (3 screens)
- [x] KYC service implemented
- [x] Upload directory created
- [ ] Apply schema to database
- [ ] Install multer package for file uploads
- [ ] Configure file size limits
- [ ] Set up document backup system
- [ ] Configure admin panel access
- [ ] Train admin team on verification
- [ ] Test all flows end-to-end
- [ ] Set up monitoring and alerts
- [ ] Prepare compliance reports
- [ ] Get regulatory approval

---

## Next Steps

1. **Apply Database Schema**

   ```bash
   cd backend
   mysql -u root -p inkawallet_db < database/kyc_schema.sql
   ```

2. **Install Dependencies**

   ```bash
   cd backend
   npm install multer http-parser
   ```

3. **Test Backend**

   ```bash
   npm start
   # Test endpoints with Postman
   ```

4. **Build Mobile App**

   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

5. **Create Admin Account**
   - Set is_admin = 1 in users table
   - Use for verification workflow

---

## Support

For assistance with KYC implementation:

- Technical issues: Check logs in backend console
- Regulatory questions: Contact Reserve Bank of Malawi
- User support: Guide users through voice-enabled interface

---

**Document Version**: 1.0  
**Last Updated**: 2024  
**Compliance**: Reserve Bank of Malawi, Financial Intelligence Authority
