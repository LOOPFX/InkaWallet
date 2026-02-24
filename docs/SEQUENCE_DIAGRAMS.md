# InkaWallet Sequence Diagrams

## User Registration and Login Flow

```plantuml
@startuml UserRegistration

actor User
participant "Mobile App" as App
participant "AuthProvider" as Auth
participant "ApiService" as API
participant "Backend\nServer" as Server
database "MySQL\nDatabase" as DB

== User Registration ==

User -> App: Open App
User -> App: Click "Register"
App -> Auth: register(email, password, name, phone)

Auth -> API: POST /api/auth/register
API -> Server: HTTP Request

Server -> Server: Validate input
Server -> Server: Hash password (bcrypt)
Server -> DB: INSERT INTO users

alt Registration Success
    DB --> Server: User created
    Server -> Server: Generate JWT token
    Server --> API: {token, user}
    API --> Auth: Success response
    Auth -> Auth: Save token locally
    Auth --> App: Registration successful
    App --> User: Show success message
    App -> App: Navigate to Home
else Email/Phone Already Exists
    DB --> Server: Duplicate entry error
    Server --> API: {error: "Email/phone exists"}
    API --> Auth: Error response
    Auth --> App: Registration failed
    App --> User: Show error message
end

@enduml
```

```plantuml
@startuml UserLogin

actor User
participant "Mobile App" as App
participant "AuthProvider" as Auth
participant "BiometricService" as Bio
participant "ApiService" as API
participant "Backend\nServer" as Server
database "MySQL\nDatabase" as DB

== Email/Password Login ==

User -> App: Click "Login"
User -> App: Enter email & password
App -> Auth: login(email, password)

Auth -> API: POST /api/auth/login
API -> Server: {email, password}

Server -> DB: SELECT * FROM users WHERE email=?
DB --> Server: User data

Server -> Server: Compare password hash
alt Password Correct
    Server -> Server: Generate JWT token
    Server -> DB: INSERT INTO activity_logs
    Server --> API: {token, user}
    API --> Auth: Login success
    Auth -> Auth: Save token & user data
    Auth --> App: Authenticated
    App --> User: Navigate to Home
else Password Incorrect
    Server --> API: {error: "Invalid credentials"}
    API --> Auth: Login failed
    Auth --> App: Authentication failed
    App --> User: Show error message
end

== Biometric Login ==

User -> App: Click "Use Biometric"
App -> Bio: authenticate()

Bio -> Bio: Check biometric availability
Bio -> User: Show biometric prompt
User -> Bio: Provide fingerprint/face

alt Biometric Success
    Bio -> Bio: Get saved credentials
    Bio -> Auth: login(savedEmail, savedPassword)
    Auth -> API: POST /api/auth/login
    API -> Server: {email, password}
    Server --> API: {token, user}
    API --> Auth: Login success
    Auth --> App: Authenticated
    App --> User: Navigate to Home
else Biometric Failed
    Bio --> App: Authentication failed
    App --> User: "Biometric authentication failed"
end

@enduml
```

## KYC Verification Flow

```plantuml
@startuml KYCVerification

actor Customer
actor Admin
participant "Mobile App" as App
participant "KycService" as KYC
participant "ApiService" as API
participant "Backend\nServer" as Server
participant "File Storage" as Storage
database "MySQL\nDatabase" as DB

== Customer Submits KYC ==

Customer -> App: Navigate to Settings
Customer -> App: Click "KYC Verification"
App -> App: Show KYC Status Screen

App -> KYC: getKycStatus()
KYC -> API: GET /api/kyc/status
API -> Server: Request
Server -> DB: SELECT FROM kyc_profiles WHERE user_id=?
DB --> Server: KYC data or null
Server --> API: {kyc_status: "not_started"}
API --> KYC: Status data
KYC --> App: Display status
App --> Customer: Show "Start KYC" button

Customer -> App: Click "Start KYC"
App -> App: Navigate to KYC Profile Screen

Customer -> App: Fill personal information
Customer -> App: Enter ID numbers
Customer -> App: Declare disability (if applicable)
Customer -> App: Click "Save & Continue"

App -> API: POST /api/kyc/profile
API -> Server: {firstName, lastName, nationalId, ...}

Server -> Server: Validate required fields
Server -> Server: Check ID uniqueness
Server -> DB: INSERT INTO kyc_profiles

alt Profile Created
    DB --> Server: Profile ID
    Server -> DB: INSERT INTO kyc_verification_history
    Server --> API: {message: "Profile saved"}
    API --> App: Success
    App -> App: Navigate to Document Upload
else Duplicate ID
    DB --> Server: Error: Duplicate entry
    Server --> API: {error: "ID already registered"}
    API --> App: Error
    App --> Customer: "This ID is already registered"
end

== Document Upload ==

Customer -> App: Click "Upload National ID"
App -> App: Show camera/gallery options
Customer -> App: Select camera

App -> App: Open camera
App -> Customer: Voice: "Position ID in frame"
Customer -> App: Take photo
App -> Customer: Voice: "Document captured"

App -> API: POST /api/kyc/documents (multipart/form-data)
API -> Server: File + document_type

Server -> Server: Validate file type & size
Server -> Storage: Save file
Storage --> Server: File path

Server -> DB: INSERT INTO kyc_documents
DB --> Server: Document ID
Server --> API: {message: "Document uploaded"}
API --> App: Success
App --> Customer: "Upload successful"

Customer -> App: Upload selfie
Customer -> App: Upload proof of address
App -> Customer: "Minimum documents uploaded"

Customer -> App: Click "Submit for Verification"
App -> API: POST /api/kyc/submit
API -> Server: Submit request

Server -> DB: SELECT documents count FROM kyc_documents
DB --> Server: Document count

alt Sufficient Documents (>= 2)
    Server -> DB: UPDATE kyc_profiles SET status='pending_verification'
    Server -> DB: INSERT INTO kyc_verification_history
    Server --> API: {message: "Submitted. Review in 24-48h"}
    API --> App: Success
    App --> Customer: "KYC submitted successfully"
else Insufficient Documents
    Server --> API: {error: "Upload at least 2 documents"}
    API --> App: Error
    App --> Customer: "Please upload more documents"
end

== Admin Verification ==

Admin -> App: Login as admin
Admin -> App: Navigate to Admin Panel
App -> API: GET /api/kyc/admin/pending
API -> Server: Request

Server -> DB: SELECT FROM kyc_profiles WHERE status='pending_verification'
DB --> Server: Pending KYC list
Server --> API: [pending KYC profiles]
API --> App: Display list
App --> Admin: Show pending verifications

Admin -> App: Select KYC profile
App --> Admin: Show profile details & documents

Admin -> Admin: Review documents
Admin -> Admin: Verify identity
Admin -> Admin: Check AML/CFT rules

alt Approve KYC
    Admin -> App: Click "Approve"
    Admin -> App: Select tier (Tier 1)
    App -> API: PUT /api/kyc/admin/verify/:id
    API -> Server: {action: "verify", tier: "tier1", limits}

    Server -> DB: UPDATE kyc_profiles SET status='verified', tier='tier1'
    Server -> DB: INSERT INTO kyc_verification_history
    Server -> DB: SELECT user FROM users WHERE id=?
    DB --> Server: User data
    Server -> Server: Send notification to user
    Server --> API: {message: "KYC verified"}
    API --> App: Success
    App --> Admin: "KYC approved"

    note over Customer: Customer receives notification
    Customer -> App: Check notification
    App -> KYC: getKycStatus()
    KYC -> API: GET /api/kyc/status
    API -> Server: Request
    Server -> DB: SELECT FROM kyc_profiles
    DB --> Server: {status: "verified", tier: "tier1"}
    Server --> API: Status data
    API --> App: Display
    App --> Customer: "KYC Verified! ✓"

else Reject KYC
    Admin -> App: Click "Reject"
    Admin -> App: Enter rejection reason
    App -> API: PUT /api/kyc/admin/verify/:id
    API -> Server: {action: "reject", reason}

    Server -> DB: UPDATE kyc_profiles SET status='rejected'
    Server -> DB: INSERT INTO kyc_verification_history
    Server --> API: {message: "KYC rejected"}
    API --> App: Success
    App --> Admin: "KYC rejected"

    note over Customer: Customer receives notification
    Customer -> App: Check status
    App --> Customer: "KYC Rejected. Please resubmit"
end

@enduml
```

## Send Money Transaction Flow

```plantuml
@startuml SendMoney

actor Sender
actor Receiver
participant "Mobile App" as App
participant "WalletProvider" as Wallet
participant "KycService" as KYC
participant "ApiService" as API
participant "Backend\nServer" as Server
participant "TransactionMonitoring" as Monitor
database "MySQL\nDatabase" as DB

== Send Money Flow ==

Sender -> App: Navigate to "Send Money"
App -> Wallet: fetchBalance()
Wallet -> API: GET /api/wallet/balance
API -> Server: Request
Server -> DB: SELECT balance FROM wallets WHERE user_id=?
DB --> Server: {balance: 25000}
Server --> API: Balance data
API --> Wallet: Balance
Wallet --> App: Update UI
App --> Sender: Show balance: MKW 25,000

Sender -> App: Select recipient from contacts
Sender -> App: Enter amount: MKW 5,000
Sender -> App: Enter description
Sender -> App: Click "Send"

== KYC Limit Check ==

App -> KYC: checkTransactionLimits(5000)
KYC -> API: POST /api/kyc/check-limits
API -> Server: {amount: 5000}

Server -> DB: SELECT FROM kyc_profiles WHERE user_id=?
DB --> Server: KYC data

alt KYC Not Verified
    Server -> Server: kyc_status != 'verified'
    Server --> API: {allowed: false, message: "Complete KYC"}
    API --> KYC: Not allowed
    KYC --> App: Limit check failed
    App -> App: Show KYC prompt dialog
    App --> Sender: "Complete KYC to send money"
    Sender -> App: Click "Complete KYC"
    App -> App: Navigate to KYC screen
    note over Sender: Flow ends here - user must complete KYC

else KYC Verified - Check Limits
    Server -> DB: SELECT FROM transaction_monitoring WHERE user_id=? AND date=TODAY
    DB --> Server: {daily_total: 10000, monthly_total: 50000}

    Server -> Server: Calculate remaining limits
    Server -> Server: daily_remaining = 50000 - 10000 = 40000
    Server -> Server: monthly_remaining = 500000 - 50000 = 450000

    alt Amount Exceeds Daily Limit
        Server -> Server: amount (5000) > daily_remaining (4000)?
        Server --> API: {allowed: false, message: "Daily limit exceeded"}
        API --> KYC: Not allowed
        KYC --> App: Limit exceeded
        App --> Sender: "Daily limit exceeded: MKW 4,000 remaining"

    else Amount Within Limits
        Server --> API: {allowed: true, daily_remaining: 35000}
        API --> KYC: Allowed
        KYC --> App: Can proceed

        == Process Transaction ==

        App --> Sender: Show confirmation dialog
        Sender -> App: Confirm transaction

        App -> Wallet: sendMoney(5000, receiverId, description)
        Wallet -> API: POST /api/transactions/send
        API -> Server: {receiverId, amount, description}

        Server -> DB: START TRANSACTION

        Server -> DB: SELECT balance FROM wallets WHERE user_id=sender_id FOR UPDATE
        DB --> Server: {balance: 25000}

        Server -> Server: Check sufficient balance
        alt Insufficient Balance
            Server -> DB: ROLLBACK
            Server --> API: {error: "Insufficient balance"}
            API --> Wallet: Failed
            Wallet --> App: Error
            App --> Sender: "Insufficient balance"

        else Sufficient Balance
            Server -> Server: new_sender_balance = 25000 - 5000 = 20000
            Server -> DB: UPDATE wallets SET balance=20000 WHERE user_id=sender_id

            Server -> DB: SELECT balance FROM wallets WHERE user_id=receiver_id FOR UPDATE
            DB --> Server: {balance: 15000}

            Server -> Server: new_receiver_balance = 15000 + 5000 = 20000
            Server -> DB: UPDATE wallets SET balance=20000 WHERE user_id=receiver_id

            Server -> Server: Generate transaction_id
            Server -> DB: INSERT INTO transactions (sender, receiver, amount, ...)
            DB --> Server: Transaction created

            Server -> Monitor: updateMonitoring(sender_id, 5000)
            Monitor -> DB: UPDATE transaction_monitoring SET daily_total+=5000

            Server -> DB: INSERT INTO activity_logs

            Server -> DB: COMMIT
            DB --> Server: Transaction committed

            Server -> Server: Send notification to sender
            Server -> Server: Send notification to receiver

            Server --> API: {success: true, transaction_id}
            API --> Wallet: Success

            Wallet -> Wallet: Update local balance
            Wallet -> Wallet: Add notification
            Wallet --> App: Transaction successful
            App --> Sender: "Money sent successfully"

            note over Receiver: Receiver gets notification
            Receiver -> App: Open app
            App -> Wallet: fetchBalance()
            App -> App: Show notification
            App --> Receiver: "You received MKW 5,000 from [Sender]"
        end
    end
end

@enduml
```

## Voice Command Flow

```plantuml
@startuml VoiceCommand

actor "Blind User" as User
participant "Mobile App" as App
participant "VoiceCommandService" as Voice
participant "AccessibilityService" as TTS
participant "Speechmatics API" as Speech
participant "WalletProvider" as Wallet
participant "ApiService" as API

== Voice Control Activation ==

User -> App: Open app
App -> Voice: initialize()
Voice -> Voice: Check voice_control_enabled in settings

alt Voice Control Enabled
    Voice -> Voice: Start wake word detection
    Voice -> TTS: speak("Voice control ready. Say Inka to begin")
    TTS --> User: "Voice control ready"

    User -> User: Says "Inka"

    Voice -> Voice: detectWakeWord("inka")
    Voice -> Voice: wakeWordDetected = true
    Voice -> TTS: speak("Listening...")
    TTS --> User: "Listening..."
    Voice -> Voice: startListening()

    == User Command ==

    User -> User: Says "Check my balance"

    Voice -> Speech: Stream audio to Speechmatics
    Speech -> Speech: Real-time transcription
    Speech --> Voice: Transcript: "check my balance"

    Voice -> Voice: processCommand("check my balance")
    Voice -> Voice: extractIntent(command)
    Voice -> Voice: Intent: CHECK_BALANCE

    == Execute Intent ==

    Voice -> Wallet: fetchBalance()
    Wallet -> API: GET /api/wallet/balance
    API --> Wallet: {balance: 25000, currency: "MKW"}
    Wallet --> Voice: Balance data

    Voice -> TTS: speak("Your balance is 25,000 Malawian Kwacha")
    TTS --> User: "Your balance is 25,000 Malawian Kwacha"

    Voice -> Voice: vibrateSuccess()
    Voice --> User: Haptic feedback

    Voice -> Voice: stopListening()
    Voice -> TTS: speak("Command completed")
    TTS --> User: "Command completed"

    == Another Command ==

    User -> User: Says "Inka"
    Voice -> Voice: detectWakeWord("inka")
    Voice -> TTS: speak("Listening...")
    TTS --> User: "Listening..."

    User -> User: Says "Send money"

    Speech --> Voice: Transcript: "send money"
    Voice -> Voice: extractIntent("send money")
    Voice -> Voice: Intent: SEND_MONEY (needs parameters)

    Voice -> TTS: speak("To whom would you like to send money?")
    TTS --> User: "To whom would you like to send money?"

    User -> User: Says "John Banda"
    Speech --> Voice: Transcript: "john banda"

    Voice -> TTS: speak("How much would you like to send?")
    TTS --> User: "How much would you like to send?"

    User -> User: Says "5000"
    Speech --> Voice: Transcript: "5000"

    Voice -> Voice: executeIntent(SEND_MONEY, {recipient: "John Banda", amount: 5000})
    Voice -> Wallet: sendMoney(5000, recipientId)
    Wallet -> API: POST /api/transactions/send

    alt Transaction Success
        API --> Wallet: Success
        Wallet --> Voice: Transaction completed
        Voice -> TTS: speak("5,000 Kwacha sent to John Banda successfully")
        TTS --> User: "5,000 Kwacha sent to John Banda successfully"
        Voice -> Voice: vibrateSuccess()
        Voice --> User: Success haptic feedback

    else Transaction Failed
        API --> Wallet: {error: "Insufficient balance"}
        Wallet --> Voice: Transaction failed
        Voice -> TTS: speak("Transaction failed. Insufficient balance")
        TTS --> User: "Transaction failed. Insufficient balance"
        Voice -> Voice: vibrateError()
        Voice --> User: Error haptic feedback
    end

else Voice Control Disabled
    Voice --> App: Voice control disabled
    App --> User: Standard UI (no voice features)
end

@enduml
```

## BNPL Loan Application Flow

```plantuml
@startuml BNPLLoan

actor Customer
participant "Mobile App" as App
participant "KycService" as KYC
participant "ApiService" as API
participant "Backend\nServer" as Server
participant "CreditScoring" as Credit
database "MySQL\nDatabase" as DB

== Check Eligibility ==

Customer -> App: Navigate to "Buy Now Pay Later"
App -> App: Load BNPL screen

App -> KYC: isKycVerified()
KYC -> API: GET /api/kyc/status
API -> Server: Request
Server -> DB: SELECT kyc_status FROM kyc_profiles WHERE user_id=?
DB --> Server: {kyc_status: "verified"}
Server --> API: KYC data
API --> KYC: Verified
KYC --> App: true

alt KYC Not Verified
    KYC --> App: false
    App --> Customer: "Complete KYC to apply for BNPL"
    note over Customer: Customer must complete KYC first

else KYC Verified - Check Credit Score
    App -> API: GET /api/credit/score
    API -> Server: Request
    Server -> Credit: calculateScore(userId)

    Credit -> DB: SELECT transaction history
    Credit -> DB: SELECT bnpl payment history
    Credit -> DB: SELECT account age
    DB --> Credit: Historical data

    Credit -> Credit: Analyze transaction patterns
    Credit -> Credit: Analyze repayment history
    Credit -> Credit: Calculate score
    Credit --> Server: {score: 720, rating: "good"}

    Server -> DB: INSERT/UPDATE credit_scores
    Server --> API: Credit score data
    API --> App: Display score
    App --> Customer: Show eligibility screen

    alt Credit Score Too Low (< 550)
        App --> Customer: "Credit score too low. Improve score first"
        note over Customer: Customer cannot apply

    else Eligible for BNPL
        Customer -> App: View BNPL options
        App --> Customer: Show loan options (4-12 weeks)

        Customer -> App: Select MKW 10,000 loan, 4 weeks
        App --> Customer: Show loan details:
        note over App
            Loan Amount: MKW 10,000
            Interest: 5% (MKW 500)
            Total: MKW 10,500
            Weekly Payment: MKW 2,625
            Duration: 4 weeks
        end note

        Customer -> App: Click "Apply for Loan"
        App -> API: POST /api/bnpl/apply
        API -> Server: {loanAmount: 10000, duration: 4}

        Server -> Server: Calculate loan details
        Server -> Server: total = 10000 * 1.05 = 10500
        Server -> Server: weekly_payment = 10500 / 4 = 2625

        Server -> DB: INSERT INTO bnpl_loans
        Server -> DB: UPDATE wallets SET balance += 10000
        Server -> DB: INSERT INTO transactions (type: 'bnpl_loan')

        DB --> Server: Loan created
        Server --> API: {loanId, status: "approved"}
        API --> App: Loan approved

        App -> App: Add notification
        App -> App: Update balance
        App --> Customer: "Loan approved! MKW 10,000 added to wallet"

        == Make Payment ==

        note over Customer: One week later
        Customer -> App: Navigate to BNPL
        App -> API: GET /api/bnpl/loans
        API -> Server: Request
        Server -> DB: SELECT FROM bnpl_loans WHERE user_id=?
        DB --> Server: Active loans
        Server --> API: Loan list
        API --> App: Display loans
        App --> Customer: Show loan: "MKW 2,625 due today"

        Customer -> App: Click "Pay Installment"
        App -> API: POST /api/bnpl/pay
        API -> Server: {loanId, amount: 2625}

        Server -> DB: START TRANSACTION
        Server -> DB: SELECT balance FROM wallets WHERE user_id=? FOR UPDATE
        DB --> Server: {balance: 15000}

        alt Sufficient Balance
            Server -> DB: UPDATE wallets SET balance -= 2625
            Server -> DB: UPDATE bnpl_loans SET amount_paid += 2625
            Server -> DB: INSERT INTO bnpl_payments
            Server -> DB: COMMIT

            Server --> API: Payment successful
            API --> App: Success
            App -> App: Add notification
            App --> Customer: "Payment successful. 3 installments remaining"

        else Insufficient Balance
            Server -> DB: ROLLBACK
            Server --> API: {error: "Insufficient balance"}
            API --> App: Failed
            App --> Customer: "Insufficient balance to make payment"
        end
    end
end

@enduml
```

## 2FA Authentication Flow

```plantuml
@startuml TwoFactorAuth

actor User
participant "Mobile App" as App
participant "AuthProvider" as Auth
participant "ApiService" as API
participant "Backend\nServer" as Server
participant "SMS Provider" as SMS
database "MySQL\nDatabase" as DB

== Enable 2FA ==

User -> App: Navigate to Settings
User -> App: Click "Enable 2FA"
App -> Auth: enable2FA()

Auth -> API: POST /api/auth/enable-2fa
API -> Server: Request

Server -> Server: Generate 6-digit code
Server -> Server: code = "123456"
Server -> Server: expires_at = NOW() + 10 minutes

Server -> DB: INSERT INTO two_factor_auth (user_id, code, expires_at)
DB --> Server: 2FA record created

Server -> SMS: sendSMS(user.phone, code)
SMS --> Server: SMS sent

Server --> API: {message: "Code sent to your phone"}
API --> Auth: Success
Auth --> App: Show code input screen
App --> User: "Enter code sent to +265999..."

User -> App: Enter code "123456"
App -> Auth: verify2FA("123456")

Auth -> API: POST /api/auth/verify-2fa
API -> Server: {code: "123456"}

Server -> DB: SELECT FROM two_factor_auth WHERE user_id=? AND is_used=false
DB --> Server: 2FA record

alt Code Valid and Not Expired
    Server -> Server: Validate code and expiry
    Server -> DB: UPDATE two_factor_auth SET is_used=true
    Server -> DB: UPDATE users SET two_factor_enabled=true
    Server --> API: {success: true}
    API --> Auth: 2FA enabled
    Auth --> App: Success
    App --> User: "2FA enabled successfully"

else Code Invalid or Expired
    Server --> API: {error: "Invalid or expired code"}
    API --> Auth: Failed
    Auth --> App: Error
    App --> User: "Invalid code. Please try again"
end

== Login with 2FA ==

User -> App: Enter email & password
App -> Auth: login(email, password)
Auth -> API: POST /api/auth/login
API -> Server: {email, password}

Server -> DB: SELECT FROM users WHERE email=?
DB --> Server: User data

Server -> Server: Verify password

alt Password Correct and 2FA Enabled
    Server -> Server: Generate 2FA code
    Server -> DB: INSERT INTO two_factor_auth
    Server -> SMS: sendSMS(phone, code)

    Server --> API: {requires2FA: true}
    API --> Auth: 2FA required
    Auth --> App: Show 2FA input
    App --> User: "Enter 2FA code"

    User -> App: Enter code
    App -> Auth: verify2FA(code)
    Auth -> API: POST /api/auth/verify-2fa
    API -> Server: {code}

    Server -> DB: SELECT FROM two_factor_auth
    Server -> Server: Validate code

    alt 2FA Code Valid
        Server -> Server: Generate JWT token
        Server --> API: {token, user}
        API --> Auth: Login success
        Auth --> App: Authenticated
        App --> User: Navigate to Home

    else 2FA Code Invalid
        Server --> API: {error: "Invalid 2FA code"}
        API --> Auth: Failed
        Auth --> App: Error
        App --> User: "Invalid 2FA code"
    end

else Password Incorrect
    Server --> API: {error: "Invalid credentials"}
    API --> Auth: Failed
    Auth --> App: Error
    App --> User: "Invalid email or password"
end

@enduml
```
