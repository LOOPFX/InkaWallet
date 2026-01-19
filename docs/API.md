# InkaWallet API Documentation

## Base URL

```
http://localhost:3000/api
```

## Authentication

All protected endpoints require authentication using JWT tokens.

### Headers

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

## API Endpoints

### Authentication

#### Register User

```http
POST /auth/register
```

**Request Body:**

```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "+265999000001",
  "password": "SecurePass@123"
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+265999000001",
    "is_verified": false
  }
}
```

#### Login

```http
POST /auth/login
```

**Request Body:**

```json
{
  "emailOrPhone": "john@example.com",
  "password": "SecurePass@123"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+265999000001",
    "is_verified": true
  }
}
```

#### Refresh Token

```http
POST /auth/refresh
```

**Request Body:**

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200):**

```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Logout

```http
POST /auth/logout
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Logout successful"
}
```

### Wallet

#### Get Balance

```http
GET /wallet/balance
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Response (200):**

```json
{
  "success": true,
  "wallet": {
    "id": "wallet-id",
    "user_id": "user-id",
    "balance": 10000.0,
    "currency": "MWK",
    "account_number": "265999000001",
    "is_active": true,
    "created_at": "2026-01-01T00:00:00.000Z",
    "updated_at": "2026-01-19T00:00:00.000Z"
  }
}
```

### Transactions

#### Send Money

```http
POST /transactions/send
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Request Body:**

```json
{
  "recipient_phone": "+265999000002",
  "amount": 500.0,
  "wallet_provider": "InkaWallet",
  "description": "Payment for services"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Transaction completed successfully",
  "transaction": {
    "id": "txn-id",
    "wallet_id": "wallet-id",
    "type": "send",
    "amount": 500.0,
    "currency": "MWK",
    "recipient_phone": "+265999000002",
    "recipient_wallet_provider": "InkaWallet",
    "description": "Payment for services",
    "status": "completed",
    "reference_number": "TXN123456789",
    "created_at": "2026-01-19T10:30:00.000Z",
    "completed_at": "2026-01-19T10:30:01.000Z"
  }
}
```

#### Get Transaction History

```http
GET /transactions/history?page=1&limit=20
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Query Parameters:**

- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20)

**Response (200):**

```json
{
  "success": true,
  "transactions": [
    {
      "id": "txn-id-1",
      "wallet_id": "wallet-id",
      "type": "send",
      "amount": 500.0,
      "currency": "MWK",
      "recipient_name": "Jane Doe",
      "recipient_phone": "+265999000002",
      "recipient_wallet_provider": "InkaWallet",
      "status": "completed",
      "reference_number": "TXN123456789",
      "created_at": "2026-01-19T10:30:00.000Z",
      "completed_at": "2026-01-19T10:30:01.000Z"
    },
    {
      "id": "txn-id-2",
      "wallet_id": "wallet-id",
      "type": "receive",
      "amount": 1000.0,
      "currency": "MWK",
      "sender_name": "Bob Smith",
      "sender_phone": "+265999000003",
      "status": "completed",
      "reference_number": "TXN987654321",
      "created_at": "2026-01-18T15:20:00.000Z",
      "completed_at": "2026-01-18T15:20:01.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 45,
    "totalPages": 3
  }
}
```

#### Get Transaction Details

```http
GET /transactions/:id
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Response (200):**

```json
{
  "success": true,
  "transaction": {
    "id": "txn-id",
    "wallet_id": "wallet-id",
    "type": "send",
    "amount": 500.0,
    "currency": "MWK",
    "recipient_name": "Jane Doe",
    "recipient_phone": "+265999000002",
    "recipient_wallet_provider": "InkaWallet",
    "description": "Payment for services",
    "status": "completed",
    "reference_number": "TXN123456789",
    "created_at": "2026-01-19T10:30:00.000Z",
    "completed_at": "2026-01-19T10:30:01.000Z"
  }
}
```

### User

#### Get Profile

```http
GET /user/profile
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Response (200):**

```json
{
  "success": true,
  "user": {
    "id": "user-id",
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+265999000001",
    "is_verified": true,
    "created_at": "2026-01-01T00:00:00.000Z"
  }
}
```

#### Update Profile

```http
PUT /user/update
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Request Body:**

```json
{
  "first_name": "John",
  "last_name": "Smith"
}
```

**Response (200):**

```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": {
    "id": "user-id",
    "first_name": "John",
    "last_name": "Smith",
    "email": "john@example.com",
    "phone": "+265999000001",
    "is_verified": true,
    "created_at": "2026-01-01T00:00:00.000Z"
  }
}
```

### Feedback

#### Submit Feedback

```http
POST /feedback
```

**Headers:**

```
Authorization: Bearer <access_token>
```

**Request Body:**

```json
{
  "subject": "App Accessibility",
  "message": "The voice commands work great! Very helpful for navigation.",
  "rating": 5
}
```

**Response (201):**

```json
{
  "success": true,
  "message": "Thank you for your feedback"
}
```

### Admin (Admin Only)

#### Get All Users

```http
GET /admin/users
```

**Headers:**

```
Authorization: Bearer <admin_access_token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Admin route - Get users"
}
```

#### Get All Transactions

```http
GET /admin/transactions
```

**Headers:**

```
Authorization: Bearer <admin_access_token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Admin route - Get transactions"
}
```

#### Get Activity Logs

```http
GET /admin/logs
```

**Headers:**

```
Authorization: Bearer <admin_access_token>
```

**Response (200):**

```json
{
  "success": true,
  "message": "Admin route - Get logs"
}
```

## Error Responses

### 400 Bad Request

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Valid email is required"
    }
  ]
}
```

### 401 Unauthorized

```json
{
  "success": false,
  "message": "Invalid or expired token"
}
```

### 403 Forbidden

```json
{
  "success": false,
  "message": "Access denied. Admin privileges required."
}
```

### 404 Not Found

```json
{
  "success": false,
  "message": "Resource not found"
}
```

### 409 Conflict

```json
{
  "success": false,
  "message": "User with this email or phone already exists"
}
```

### 429 Too Many Requests

```json
{
  "success": false,
  "message": "Too many requests from this IP, please try again later."
}
```

### 500 Internal Server Error

```json
{
  "success": false,
  "message": "Internal server error"
}
```

## Rate Limiting

- **Window**: 15 minutes
- **Max Requests**: 100 per window
- **Headers**:
  - `X-RateLimit-Limit`: Maximum requests allowed
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Time when limit resets

## Security Notes

1. **Always use HTTPS** in production
2. **Store tokens securely** (Flutter Secure Storage)
3. **Refresh tokens before expiry** (50 minutes)
4. **Never log sensitive data**
5. **Validate all input** on both client and server
6. **Use strong passwords** (min 8 chars, uppercase, lowercase, number, special char)

## Testing with cURL

### Register

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+265999000001",
    "password": "SecurePass@123"
  }'
```

### Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "emailOrPhone": "john@example.com",
    "password": "SecurePass@123"
  }'
```

### Get Balance

```bash
curl -X GET http://localhost:3000/api/wallet/balance \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Send Money

```bash
curl -X POST http://localhost:3000/api/transactions/send \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "recipient_phone": "+265999000002",
    "amount": 500.00,
    "wallet_provider": "InkaWallet",
    "description": "Test payment"
  }'
```

## Postman Collection

Import the Postman collection for easy testing:

```json
{
  "info": {
    "name": "InkaWallet API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Register",
          "request": {
            "method": "POST",
            "url": "{{base_url}}/auth/register",
            "body": {
              "mode": "raw",
              "raw": "{\n  \"first_name\": \"John\",\n  \"last_name\": \"Doe\",\n  \"email\": \"john@example.com\",\n  \"phone\": \"+265999000001\",\n  \"password\": \"SecurePass@123\"\n}"
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "base_url",
      "value": "http://localhost:3000/api"
    }
  ]
}
```

## Support

For API questions:

- Email: api@inkawallet.com
- Documentation: https://docs.inkawallet.com
