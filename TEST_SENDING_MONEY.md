# InkaWallet Send Money - Feature Guide

## ✅ What I've Implemented:

### 1. **InkaWallet Account Numbers**

- Every user now has a unique account number (format: `IW0000001260`)
- Users can send money using either:
  - Phone number: `+265888111222`
  - Account number: `IW0000002529`

### 2. **Phone Number Validation by Provider**

#### **MPamba (TNM Numbers)**

- Valid formats: `08XXXXXXX`, `088XXXXXXX`, `0888XXXXXXX`, `+2658XXXXXXX`
- Example: `+265888111222`, `088111222`
- ❌ If user tries to send to Airtel number (099) via MPamba → **ERROR**: "Invalid TNM number. Must start with 08/088/0888 or +2658"

#### **Airtel Money**

- Valid formats: `09XXXXXXX`, `099XXXXXXX`, `0999XXXXXXX`, `+2659XXXXXXX`
- Example: `+265999123456`, `099123456`
- ❌ If user tries to send to TNM number (088) via Airtel → **ERROR**: "Invalid Airtel number. Must start with 09/099/0999 or +2659"

### 3. **Bank Transfers**

- 8 Malawian banks available:
  1. National Bank of Malawi
  2. Standard Bank Malawi
  3. FMB (First Merchant Bank)
  4. NBS Bank
  5. CDH Investment Bank
  6. MyBucks Banking Corporation
  7. Ecobank Malawi
  8. Opportunity Bank Malawi

- User MUST select a bank from the list
- ❌ Invalid bank name → **ERROR** with list of available banks

### 4. **Password/PIN Confirmation**

- **EVERY** transaction requires password confirmation
- Password is verified before processing
- ❌ Wrong password → **ERROR**: "Invalid password"

## 📡 API Endpoints:

### Get Available Banks

```bash
GET /api/transactions/banks
```

Response:

```json
{
  "banks": [
    "National Bank of Malawi",
    "Standard Bank Malawi",
    ...
  ]
}
```

### Send Money

```bash
POST /api/transactions/send
Authorization: Bearer <token>

{
  "receiver_identifier": "+265888111222",  // Phone or account number
  "amount": 5000,
  "payment_method": "inkawallet",  // or airtel_money, mpamba, bank
  "password": "user_password",      // REQUIRED
  "bank_name": "NBS Bank",          // Required only if payment_method = bank
  "description": "Payment for services"  // Optional
}
```

## 🧪 Test Scenarios:

### ✅ SUCCESS Cases:

1. InkaWallet transfer with phone: `+265888111222` + `payment_method: inkawallet`
2. InkaWallet transfer with account: `IW0000002529` + `payment_method: inkawallet`
3. MPamba to TNM number: `+265888111222` + `payment_method: mpamba`
4. Airtel to Airtel number: `+265999123456` + `payment_method: airtel_money`
5. Bank transfer: `payment_method: bank` + `bank_name: NBS Bank`

### ❌ FAILURE Cases:

1. MPamba to Airtel number (099): **"Invalid TNM number"**
2. Airtel to TNM number (088): **"Invalid Airtel number"**
3. Bank transfer without bank_name: **"Invalid bank name"** + list
4. Wrong password: **"Invalid password"**
5. Insufficient balance: **"Insufficient balance"**
6. InkaWallet to non-existent user: **"Receiver not found"**

## 🎯 User Experience:

When sending money, the flow will be:

1. **Select Payment Method** → `inkawallet`, `airtel_money`, `mpamba`, or `bank`

2. **If Bank** → Show dropdown of 8 Malawian banks

3. **Enter Receiver**:
   - InkaWallet: Phone or Account Number
   - Mobile Money: Phone (validated against provider)
   - Bank: Account number

4. **Enter Amount**

5. **Confirm with Password** → User must enter their password

6. **Validation Checks**:
   - ✅ Correct phone format for provider
   - ✅ Valid bank selected
   - ✅ Correct password
   - ✅ Sufficient balance

7. **Transaction Processed** → Success or specific error message

## 🔒 Security:

- Password required for every transaction
- Account locked check
- Balance verification
- Transaction rollback on any error
- Proper error messages (no sensitive data leaked)

## Current User Accounts:

| Email                     | Phone         | Account Number |
| ------------------------- | ------------- | -------------- |
| admin@inkawallet.com      | +265888000000 | IW0000001260   |
| maria.kalonga@example.com | +265888111222 | IW0000002529   |
| joseph.banda@example.com  | +265888333444 | IW0000003867   |
| grace.chirwa@example.com  | +265888555666 | IW0000004746   |
| james.phiri@example.com   | +265888777888 | IW0000005131   |
