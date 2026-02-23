# InkaWallet Use Case Diagrams

## Main System Use Case Diagram

```plantuml
@startuml InkaWallet_Main_UseCases

left to right direction
skinparam packageStyle rectangle

actor "Customer" as Customer
actor "Admin" as Admin
actor "Blind User" as BlindUser
actor "Reserve Bank of Malawi" as RBM

rectangle "InkaWallet System" {

  ' Authentication Use Cases
  package "Authentication" {
    usecase "Register Account" as UC1
    usecase "Login" as UC2
    usecase "Biometric Login" as UC3
    usecase "Enable 2FA" as UC4
    usecase "Reset Password" as UC5
  }

  ' Wallet Management
  package "Wallet Management" {
    usecase "View Balance" as UC6
    usecase "Top Up Wallet" as UC7
    usecase "View Transaction History" as UC8
    usecase "Toggle Balance Visibility" as UC9
  }

  ' Money Transfer
  package "Money Transfer" {
    usecase "Send Money" as UC10
    usecase "Receive Money" as UC11
    usecase "Scan QR to Pay" as UC12
    usecase "Generate Payment QR" as UC13
    usecase "Request Money" as UC14
  }

  ' Services
  package "Services" {
    usecase "Buy Airtime" as UC15
    usecase "Pay Bills" as UC16
    usecase "Check Credit Score" as UC17
    usecase "Apply for BNPL Loan" as UC18
    usecase "Repay BNPL Loan" as UC19
  }

  ' Voice & Accessibility
  package "Accessibility" {
    usecase "Use Voice Commands" as UC20
    usecase "Enable Voice Control" as UC21
    usecase "Text-to-Speech" as UC22
    usecase "Haptic Feedback" as UC23
  }

  ' KYC Verification
  package "KYC Verification" {
    usecase "Submit KYC Profile" as UC24
    usecase "Upload Documents" as UC25
    usecase "Check KYC Status" as UC26
    usecase "Verify KYC" as UC27
    usecase "Reject KYC" as UC28
  }

  ' Admin Functions
  package "Admin Functions" {
    usecase "Manage Users" as UC29
    usecase "View Pending KYC" as UC30
    usecase "Monitor Transactions" as UC31
    usecase "Generate Reports" as UC32
    usecase "Flag Suspicious Activity" as UC33
  }
}

' Customer relationships
Customer --> UC1
Customer --> UC2
Customer --> UC3
Customer --> UC4
Customer --> UC5
Customer --> UC6
Customer --> UC7
Customer --> UC8
Customer --> UC9
Customer --> UC10
Customer --> UC11
Customer --> UC12
Customer --> UC13
Customer --> UC14
Customer --> UC15
Customer --> UC16
Customer --> UC17
Customer --> UC18
Customer --> UC19
Customer --> UC24
Customer --> UC25
Customer --> UC26

' Blind User (extends Customer)
BlindUser --|> Customer
BlindUser --> UC20
BlindUser --> UC21
BlindUser --> UC22
BlindUser --> UC23

' Admin relationships
Admin --> UC27
Admin --> UC28
Admin --> UC29
Admin --> UC30
Admin --> UC31
Admin --> UC32
Admin --> UC33

' RBM relationships
RBM --> UC32
RBM --> UC33

' Include relationships
UC10 ..> UC24 : <<include>>
UC18 ..> UC24 : <<include>>
UC15 ..> UC6 : <<include>>
UC16 ..> UC6 : <<include>>

' Extend relationships
UC3 ..> UC2 : <<extend>>
UC4 ..> UC2 : <<extend>>

@enduml
```

## Authentication Use Case Diagram (Detailed)

```plantuml
@startuml Authentication_UseCases

left to right direction

actor Customer
actor "Google OAuth" as Google
actor "SMS Provider" as SMS

rectangle "Authentication System" {
  usecase "Register Account" as Register
  usecase "Login with Email" as EmailLogin
  usecase "Login with Google" as GoogleLogin
  usecase "Enable Biometric Auth" as BiometricAuth
  usecase "Verify Biometric" as VerifyBio
  usecase "Enable 2FA" as Enable2FA
  usecase "Send 2FA Code" as Send2FA
  usecase "Verify 2FA Code" as Verify2FA
  usecase "Forgot Password" as ForgotPass
  usecase "Reset Password" as ResetPass
  usecase "Logout" as Logout
}

Customer --> Register
Customer --> EmailLogin
Customer --> GoogleLogin
Customer --> BiometricAuth
Customer --> Enable2FA
Customer --> ForgotPass
Customer --> Logout

GoogleLogin --> Google
Enable2FA --> SMS : uses
Send2FA --> SMS : uses

EmailLogin ..> VerifyBio : <<extend>>
EmailLogin ..> Verify2FA : <<extend>>
ForgotPass ..> Send2FA : <<include>>
ForgotPass ..> ResetPass : <<include>>
BiometricAuth ..> VerifyBio : <<include>>
Enable2FA ..> Send2FA : <<include>>
Enable2FA ..> Verify2FA : <<include>>

@enduml
```

## KYC Verification Use Case Diagram

```plantuml
@startuml KYC_UseCases

left to right direction

actor Customer
actor Admin
actor "Reserve Bank\nof Malawi" as RBM
actor "Document\nVerification\nService" as DocVerify

rectangle "KYC Verification System" {

  package "Customer KYC Flow" {
    usecase "Complete Personal Info" as PersonalInfo
    usecase "Upload ID Document" as UploadID
    usecase "Take Selfie" as Selfie
    usecase "Upload Proof of Address" as ProofAddress
    usecase "Declare Disability" as Disability
    usecase "Submit for Verification" as Submit
    usecase "Check KYC Status" as CheckStatus
    usecase "Resubmit Rejected KYC" as Resubmit
  }

  package "Admin Verification" {
    usecase "View Pending KYC" as ViewPending
    usecase "Review Documents" as ReviewDocs
    usecase "Verify Identity" as VerifyID
    usecase "Approve KYC" as Approve
    usecase "Reject KYC" as Reject
    usecase "Set Tier Level" as SetTier
    usecase "Set Transaction Limits" as SetLimits
    usecase "Flag for Investigation" as FlagInvestigation
  }

  package "Compliance" {
    usecase "Check AML/CFT Rules" as CheckAML
    usecase "Monitor Transactions" as MonitorTx
    usecase "Generate Compliance Report" as ComplianceReport
    usecase "Audit KYC History" as AuditHistory
  }
}

' Customer relationships
Customer --> PersonalInfo
Customer --> UploadID
Customer --> Selfie
Customer --> ProofAddress
Customer --> Disability
Customer --> Submit
Customer --> CheckStatus
Customer --> Resubmit

' Admin relationships
Admin --> ViewPending
Admin --> ReviewDocs
Admin --> VerifyID
Admin --> Approve
Admin --> Reject
Admin --> SetTier
Admin --> SetLimits
Admin --> FlagInvestigation
Admin --> AuditHistory

' RBM relationships
RBM --> ComplianceReport
RBM --> MonitorTx

' Include/Extend relationships
Submit ..> PersonalInfo : <<include>>
Submit ..> UploadID : <<include>>
Submit ..> Selfie : <<include>>
Submit ..> ProofAddress : <<include>>

Approve ..> SetTier : <<include>>
Approve ..> SetLimits : <<include>>
Approve ..> CheckAML : <<include>>

ReviewDocs --> DocVerify : uses
VerifyID ..> CheckAML : <<include>>

Reject ..> Resubmit : <<extend>>

@enduml
```

## Money Transfer Use Case Diagram

```plantuml
@startuml MoneyTransfer_UseCases

left to right direction

actor Sender
actor Receiver
actor "Payment\nProvider" as Provider
actor "Mobile Money\nProvider" as MobileMoney

rectangle "Money Transfer System" {

  package "Send Money Flow" {
    usecase "Select Recipient" as SelectRecipient
    usecase "Enter Amount" as EnterAmount
    usecase "Choose Payment Method" as ChooseMethod
    usecase "Verify Transaction" as VerifyTx
    usecase "Check KYC Limits" as CheckLimits
    usecase "Process Transfer" as ProcessTransfer
    usecase "Send Notification" as SendNotif
    usecase "Update Balance" as UpdateBalance
  }

  package "Receive Money" {
    usecase "Generate QR Code" as GenQR
    usecase "Share Payment Link" as ShareLink
    usecase "Receive Notification" as ReceiveNotif
    usecase "View Incoming Transfer" as ViewIncoming
  }

  package "Request Money" {
    usecase "Create Money Request" as CreateRequest
    usecase "Send Request to Contact" as SendRequest
    usecase "Approve Request" as ApproveRequest
    usecase "Decline Request" as DeclineRequest
  }

  package "QR Payment" {
    usecase "Scan QR Code" as ScanQR
    usecase "Verify QR Details" as VerifyQR
    usecase "Confirm Payment" as ConfirmPayment
  }
}

' Sender relationships
Sender --> SelectRecipient
Sender --> EnterAmount
Sender --> ChooseMethod
Sender --> VerifyTx
Sender --> ScanQR
Sender --> CreateRequest

' Receiver relationships
Receiver --> GenQR
Receiver --> ShareLink
Receiver --> ReceiveNotif
Receiver --> ViewIncoming
Receiver --> ApproveRequest
Receiver --> DeclineRequest

' Include relationships
SelectRecipient ..> ProcessTransfer : <<include>>
EnterAmount ..> CheckLimits : <<include>>
ProcessTransfer ..> UpdateBalance : <<include>>
ProcessTransfer ..> SendNotif : <<include>>
ConfirmPayment ..> ProcessTransfer : <<include>>

ScanQR ..> VerifyQR : <<include>>
VerifyQR ..> ConfirmPayment : <<include>>

CreateRequest ..> SendRequest : <<include>>
ApproveRequest ..> ProcessTransfer : <<include>>

' External systems
ChooseMethod --> Provider : uses
ChooseMethod --> MobileMoney : uses

@enduml
```

## Voice Control Use Case Diagram

```plantuml
@startuml VoiceControl_UseCases

left to right direction

actor "Blind User" as BlindUser
actor "Speechmatics API" as Speechmatics
actor "TTS Engine" as TTS

rectangle "Voice Control System" {

  package "Voice Input" {
    usecase "Say Wake Word (Inka)" as WakeWord
    usecase "Listen for Command" as Listen
    usecase "Process Speech" as ProcessSpeech
    usecase "Extract Intent" as ExtractIntent
    usecase "Execute Command" as Execute
  }

  package "Voice Output" {
    usecase "Speak Balance" as SpeakBalance
    usecase "Announce Transaction" as AnnounceTx
    usecase "Read Screen Content" as ReadScreen
    usecase "Provide Guidance" as Guidance
    usecase "Error Feedback" as ErrorFeedback
  }

  package "Voice Commands" {
    usecase "Check Balance" as VoiceBalance
    usecase "Send Money by Voice" as VoiceSend
    usecase "Buy Airtime by Voice" as VoiceAirtime
    usecase "Pay Bill by Voice" as VoiceBill
    usecase "Check History by Voice" as VoiceHistory
  }

  package "Haptic Feedback" {
    usecase "Vibrate on Success" as VibrateSuccess
    usecase "Vibrate on Error" as VibrateError
    usecase "Confirm Action" as HapticConfirm
  }
}

' Blind User relationships
BlindUser --> WakeWord
BlindUser --> VoiceBalance
BlindUser --> VoiceSend
BlindUser --> VoiceAirtime
BlindUser --> VoiceBill
BlindUser --> VoiceHistory

' Voice flow
WakeWord ..> Listen : <<include>>
Listen ..> ProcessSpeech : <<include>>
ProcessSpeech ..> ExtractIntent : <<include>>
ExtractIntent ..> Execute : <<include>>

' External services
ProcessSpeech --> Speechmatics : uses
SpeakBalance --> TTS : uses
AnnounceTx --> TTS : uses
ReadScreen --> TTS : uses
Guidance --> TTS : uses
ErrorFeedback --> TTS : uses

' Command execution
VoiceBalance ..> SpeakBalance : <<include>>
VoiceSend ..> AnnounceTx : <<include>>
VoiceAirtime ..> AnnounceTx : <<include>>
VoiceBill ..> AnnounceTx : <<include>>

Execute ..> VibrateSuccess : <<extend>>
Execute ..> VibrateError : <<extend>>

@enduml
```

## Use Case Descriptions

### UC1: Register Account

**Actor**: Customer  
**Preconditions**: None  
**Main Flow**:

1. User opens app and selects "Register"
2. User enters email, password, full name, phone number
3. System validates input
4. System creates account
5. System sends verification email
6. User verifies email
7. System activates account

**Alternative Flow**:

- User can register with Google OAuth
- System validates uniqueness of email/phone

**Postconditions**: User has active account

---

### UC24: Submit KYC Profile

**Actor**: Customer  
**Preconditions**: User is logged in  
**Main Flow**:

1. User navigates to Settings → KYC Verification
2. User fills personal information form
3. User uploads required documents (ID, selfie, proof of address)
4. User declares disability status (if applicable)
5. System validates all required fields
6. User submits for verification
7. System creates KYC profile with status "pending_verification"
8. System notifies admin team
9. System sends confirmation to user

**Alternative Flow**:

- If documents missing, system prompts user to upload
- If disability declared, system enables accessibility features

**Postconditions**: KYC profile created with pending status

---

### UC20: Use Voice Commands

**Actor**: Blind User  
**Preconditions**: Voice control enabled in settings  
**Main Flow**:

1. User says "Inka" (wake word)
2. System listens for command
3. User says command (e.g., "check balance")
4. System processes speech using Speechmatics
5. System extracts intent
6. System executes command
7. System announces result via text-to-speech
8. System provides haptic feedback

**Alternative Flow**:

- If command unclear, system asks for clarification
- If error occurs, system announces error and vibrates

**Postconditions**: Command executed, user receives audio/haptic feedback
