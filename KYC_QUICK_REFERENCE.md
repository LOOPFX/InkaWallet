# KYC System - Quick Reference

## What Was Added

### Backend (Node.js/TypeScript)

1. **Database Schema** (`backend/database/kyc_schema.sql`)
   - 5 new tables for comprehensive KYC management
   - Transaction monitoring for AML/CFT compliance
   - Support for disability and accessibility preferences

2. **API Routes** (`backend/src/routes/kyc.routes.ts`)
   - User endpoints: profile, documents, status, submit
   - Admin endpoints: pending reviews, verify/reject
   - Transaction limit checks

3. **File Uploads** (`backend/uploads/kyc-documents/`)
   - Multer integration for document uploads
   - 10MB file size limit
   - JPEG, PNG, PDF support

### Mobile App (Flutter/Dart)

1. **KYC Profile Screen** (`mobile/lib/screens/kyc_profile_screen.dart`)
   - Complete personal information form
   - Disability & accessibility support
   - Next of kin information
   - Voice-accessible

2. **Document Upload Screen** (`mobile/lib/screens/kyc_document_upload_screen.dart`)
   - Camera/gallery integration
   - Voice-guided capture
   - Document type selection
   - Upload progress tracking

3. **KYC Status Screen** (`mobile/lib/screens/kyc_status_screen.dart`)
   - Real-time verification status
   - Transaction limits display
   - Tier information
   - Benefits overview

4. **KYC Service** (`mobile/lib/services/kyc_service.dart`)
   - Transaction limit checks
   - Status queries
   - Verification level checks

5. **Settings Integration** (`mobile/lib/screens/settings_screen.dart`)
   - KYC verification menu item
   - Status display

### Documentation

1. **Implementation Guide** (`KYC_IMPLEMENTATION_GUIDE.md`)
   - Complete regulatory framework
   - API documentation
   - Testing guide
   - Security considerations

2. **Test Script** (`backend/test_kyc.sh`)
   - Automated endpoint testing
   - Profile creation flow
   - Limit check validation

## How to Use

### For Users

1. **Start KYC from Settings**
   - Open Settings → Account Verification
   - Tap "KYC Verification"

2. **Complete Profile**
   - Fill in personal information
   - At least one ID required
   - Disability support options

3. **Upload Documents**
   - Minimum 2 documents required
   - Use camera or gallery
   - Voice guidance available

4. **Submit for Verification**
   - Review all information
   - Submit to admin team
   - Wait 24-48 hours

5. **Check Status**
   - View in Settings or KYC Status screen
   - See transaction limits
   - Track verification progress

### For Admins

1. **View Pending Verifications**
   ```
   GET /api/kyc/admin/pending
   ```

2. **Approve KYC**
   ```
   PUT /api/kyc/admin/verify/:id
   Body: {
     "action": "verify",
     "verification_level": "tier1",
     "daily_limit": 50000,
     "monthly_limit": 500000
   }
   ```

3. **Reject KYC**
   ```
   PUT /api/kyc/admin/verify/:id
   Body: {
     "action": "reject",
     "rejection_reason": "Document not clear"
   }
   ```

## Verification Tiers

### Tier 1 - Basic
- Daily: MKW 50,000
- Monthly: MKW 500,000
- Requirements: ID + Proof of address + Selfie

### Tier 2 - Enhanced
- Daily: MKW 200,000
- Monthly: MKW 2,000,000
- Requirements: Tier 1 + Employment letter

### Tier 3 - Full
- Daily: Unlimited
- Monthly: Unlimited
- Requirements: Tier 2 + Face-to-face verification

## Transaction Enforcement

All financial operations check KYC limits:
- Send money
- Buy airtime
- Pay bills
- BNPL loans
- Withdraw funds

If limit exceeded or KYC not verified:
- User sees prompt to complete KYC
- Transaction is blocked
- Clear message explains reason

## Accessibility Features

### Voice-Guided Document Capture
- "Position ID card in frame"
- "Hold still"
- "Captured successfully"

### Alternative Methods
- Voice input for forms
- Assisted verification option
- Extended timeouts

### Disability Support
- Visual impairment settings
- Hearing impairment support
- Physical disability accommodations

## Security

### Data Protection
- All KYC data encrypted
- Secure file storage
- SSL/TLS encryption
- Access control

### Privacy
- User consent required
- Audit logs maintained
- IP address tracking
- Data retention policies

## Testing

Run backend test:
```bash
cd backend
./test_kyc.sh
```

Test mobile flow:
```bash
cd mobile
flutter run
# Navigate to Settings → KYC Verification
```

## Deployment

1. **Apply Database Schema** ✓ (Done)
   ```bash
   mysql -u root -p inkawallet_db < database/kyc_schema.sql
   ```

2. **Install Dependencies** ✓ (Done)
   ```bash
   npm install multer @types/multer http-parser
   ```

3. **Start Backend**
   ```bash
   npm start
   ```

4. **Build Mobile App**
   ```bash
   flutter pub get
   flutter run
   ```

## Compliance

✅ Reserve Bank of Malawi requirements
✅ Financial Intelligence Authority (FIA)
✅ Anti-Money Laundering (AML)
✅ Counter Financing of Terrorism (CFT)
✅ Inclusive finance for people with disabilities
✅ Support for unbanked/underbanked population

## Support

- **Technical**: Check backend console logs
- **Regulatory**: Reserve Bank of Malawi guidance
- **User**: Voice-enabled step-by-step assistance

---

**Status**: Implementation Complete ✅
**Tested**: Backend endpoints working ✅
**Next**: Mobile app testing with document uploads
