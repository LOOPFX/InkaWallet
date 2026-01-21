# InkaWallet - Inclusive Digital Wallet

## Overview

InkaWallet is an inclusive digital wallet application designed to serve both regular users and those with physical impairments (blind and upper limb impaired). The app prioritizes security, accessibility, and user-friendliness.

## Key Features

### Accessibility & Inclusivity

- **Voice Commands** - Full voice control using Speechmatics API
- **Audio Feedback** - Text-to-speech for all actions and confirmations
- **Haptic Feedback** - Vibration patterns for transaction feedback
- **Inclusive Mode** - Enabled by default, can be toggled in settings
- **High Contrast UI** - Purple-themed, optimized for visibility

### Security

- **Biometric Authentication** - Fingerprint and face recognition
- **End-to-End Encryption** - AES-256 for sensitive data
- **Transaction Confirmation** - Multi-step verification for transfers
- **Secure PIN/Password** - Encrypted storage with bcrypt
- **Session Management** - JWT-based authentication with refresh tokens
- **Audit Logging** - Complete transaction and activity logs

### Core Functionality

- User Registration & Authentication
- Check Account Balance
- Send Money (to InkaWallet users and external wallets)
- Receive Money
- Transaction History
- User Feedback System
- Offline Support with Transaction Queue

### Interoperability

- Mock integration with:
  - Mpamba
  - Airtel Money
  - Bank transfers

### Admin Features

- Web-based admin dashboard
- User management
- Transaction monitoring
- Activity logs
- Research data collection
- Analytics and reporting

## Tech Stack

### Mobile App

- **Framework**: Flutter (Dart)
- **Target**: Android (primary), iOS (compatible)
- **State Management**: Provider/Riverpod
- **Local Storage**: SQLite (sqflite) + Hive
- **Biometrics**: local_auth
- **Voice**: Speechmatics API integration

### Backend

- **Runtime**: Node.js
- **Language**: TypeScript
- **Framework**: Express.js
- **Database**: MySQL
- **Authentication**: JWT (jsonwebtoken)
- **Encryption**: crypto, bcryptjs
- **API Documentation**: Swagger/OpenAPI

### Admin Web

- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **UI Library**: Material-UI (MUI)
- **State Management**: React Context API
- **Charts**: Recharts
- **HTTP Client**: Axios

## Project Structure

```
InkaWallet/
├── mobile/                 # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/         # Data models
│   │   ├── services/       # API, voice, storage services
│   │   ├── screens/        # UI screens (auth, home, send, history, settings)
│   │   ├── providers/      # State management
│   │   └── utils/          # Helpers, constants, themes
│   └── pubspec.yaml
├── backend/                # Node.js backend
│   ├── src/
│   │   ├── controllers/    # Request handlers
│   │   ├── routes/         # API routes
│   │   ├── middleware/     # Auth, validation, error handling
│   │   ├── config/         # Database configuration
│   │   ├── utils/          # Encryption, security, logging
│   │   └── server.ts
│   ├── database/
│   │   └── schema.sql      # Database schema with triggers
│   └── package.json
├── admin/                  # Admin web dashboard
│   ├── src/
│   │   ├── components/     # Layout, reusable components
│   │   ├── pages/          # Dashboard, Users, Transactions, Logs, Feedback
│   │   ├── services/       # API service
│   │   ├── contexts/       # Auth context
│   │   ├── types/          # TypeScript interfaces
│   │   └── App.tsx
│   ├── package.json
│   └── vite.config.ts
└── docs/                   # Documentation
    ├── API.md              # API reference
    ├── SECURITY.md         # Security architecture
    ├── ACCESSIBILITY.md    # Accessibility features
    └── SETUP.md            # Installation guide
```

## Security Measures

1. **Data Encryption**: All sensitive data encrypted at rest and in transit
2. **Secure Communication**: HTTPS/TLS for all API calls
3. **Authentication**: Multi-factor authentication support
4. **Authorization**: Role-based access control (RBAC)
5. **Input Validation**: Comprehensive validation on client and server
6. **Rate Limiting**: Protection against brute force attacks
7. **SQL Injection Protection**: Parameterized queries
8. **XSS Protection**: Input sanitization
9. **CSRF Protection**: Token-based verification
10. **Audit Trail**: Complete logging of all transactions and user actions

## Offline Support

- Local SQLite database for caching
- Transaction queue for offline operations
- Automatic sync when connection restored
- Conflict resolution for data consistency

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.0.0)
- Node.js (>= 18.x)
- MySQL (>= 8.0)
- Android Studio / Xcode
- Speechmatics API key

### Installation

See [SETUP.md](docs/SETUP.md) for detailed installation instructions.

## License

Educational/Research Project

## Contributors

Research Team - Inclusive Financial Technology Project
