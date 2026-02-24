# InkaWallet State Diagrams

## KYC Profile State Diagram

```plantuml
@startuml KYCStateDiagram

[*] --> NotStarted : User registered

NotStarted --> DraftProfile : User starts KYC
DraftProfile : Entry: Create empty profile
DraftProfile : Do: User fills personal info
DraftProfile : Exit: Save profile data

DraftProfile --> PendingDocuments : Profile saved
PendingDocuments : Entry: Navigate to upload screen
PendingDocuments : Do: User uploads documents
PendingDocuments : Exit: Validate document count

PendingDocuments --> PendingDocuments : Upload document [count < 2]
PendingDocuments --> ReadyForSubmission : Upload document [count >= 2]

ReadyForSubmission : Entry: Enable submit button
ReadyForSubmission : Do: User can review & submit
ReadyForSubmission : Exit: Submit KYC

ReadyForSubmission --> PendingVerification : Submit KYC
PendingVerification : Entry: Notify admins
PendingVerification : Do: Admin reviews documents
PendingVerification : Exit: Admin makes decision

PendingVerification --> Verified : Approve [documents valid]
PendingVerification --> Rejected : Reject [documents invalid]

Verified : Entry: Assign tier & limits
Verified : Entry: Notify user
Verified : Do: User can transact with limits
Verified : Exit: Tier can be upgraded

Verified --> Verified : Upgrade tier [higher documents provided]
Verified --> Suspended : Suspicious activity detected

Rejected : Entry: Record rejection reason
Rejected : Entry: Notify user
Rejected : Do: User can resubmit
Rejected : Exit: Clear rejected status

Rejected --> DraftProfile : Resubmit KYC

Suspended : Entry: Freeze account
Suspended : Entry: Notify user & authorities
Suspended : Do: Investigation ongoing
Suspended : Exit: Investigation complete

Suspended --> Verified : Investigation cleared
Suspended --> Terminated : Fraud confirmed

Terminated : Entry: Permanent ban
Terminated : Entry: Report to authorities
Terminated : Do: No further access

Terminated --> [*]

note right of NotStarted
    Initial state when user
    registers account
end note

note right of PendingVerification
    Typical wait time:
    24-48 hours
end note

note right of Verified
    Tiers:
    - Tier 1: MKW 50K daily
    - Tier 2: MKW 200K daily
    - Tier 3: Unlimited
end note

note right of Suspended
    Triggers:
    - Multiple failed transactions
    - High-value suspicious transfers
    - Duplicate accounts
    - Reported fraud
end note

@enduml
```

## Transaction State Diagram

```plantuml
@startuml TransactionStateDiagram

[*] --> Initiated : User starts transaction

Initiated : Entry: Create transaction record
Initiated : Do: Validate amount & recipient
Initiated : Exit: Validation complete

Initiated --> Validating : Amount > 0 && Recipient valid
Initiated --> Failed : Amount <= 0 || Invalid recipient

Validating : Entry: Check KYC & limits
Validating : Do: Verify balance & limits
Validating : Exit: All checks done

Validating --> PendingConfirmation : All checks passed
Validating --> Failed : Check failed

PendingConfirmation : Entry: Show confirmation dialog
PendingConfirmation : Do: User reviews details
PendingConfirmation : Exit: User decision

PendingConfirmation --> Processing : User confirms
PendingConfirmation --> Cancelled : User cancels

Processing : Entry: Lock wallets
Processing : Do: Execute transaction
Processing : Exit: Unlock wallets

Processing --> Completed : Database commit successful
Processing --> Failed : Database rollback

Completed : Entry: Send notifications
Completed : Entry: Update monitoring
Completed : Do: Transaction finalized
Completed : Exit: Record in history

Completed --> [*]

Failed : Entry: Log error
Failed : Entry: Notify user
Failed : Do: Show error message
Failed : Exit: Cleanup

Failed --> [*]

Cancelled : Entry: Log cancellation
Cancelled : Entry: Release locks
Cancelled : Exit: Return to previous screen

Cancelled --> [*]

note right of Validating
    Checks performed:
    - KYC verification status
    - Daily/monthly limits
    - Sufficient balance
    - Recipient account active
end note

note right of Processing
    Atomic operations:
    1. Debit sender wallet
    2. Credit receiver wallet
    3. Create transaction record
    4. Update monitoring
    All or nothing
end note

note right of Failed
    Reasons:
    - Insufficient balance
    - Limit exceeded
    - Network error
    - Database error
    - KYC not verified
end note

@enduml
```

## User Session State Diagram

```plantuml
@startuml UserSessionStateDiagram

[*] --> LoggedOut : App launch

LoggedOut : Entry: Clear session data
LoggedOut : Do: Show login screen
LoggedOut : Exit: Prepare authentication

LoggedOut --> Authenticating : User enters credentials
LoggedOut --> Authenticating : Biometric initiated
LoggedOut --> Authenticating : Google OAuth initiated

Authenticating : Entry: Validate credentials
Authenticating : Do: Check password/biometric
Authenticating : Exit: Authentication result

Authenticating --> Pending2FA : Valid + 2FA enabled
Authenticating --> LoggedIn : Valid + No 2FA
Authenticating --> LoggedOut : Invalid credentials

Pending2FA : Entry: Generate 2FA code
Pending2FA : Entry: Send SMS
Pending2FA : Do: User enters code
Pending2FA : Exit: Validate code

Pending2FA --> LoggedIn : Code valid
Pending2FA --> LoggedOut : Code invalid [3 attempts]

LoggedIn : Entry: Generate JWT token
LoggedIn : Entry: Load user data
LoggedIn : Entry: Initialize wallet
LoggedIn : Do: User active
LoggedIn : Exit: Cleanup session

LoggedIn --> Active : Token valid
LoggedIn --> LoggedOut : Token expired

Active : Entry: Start session timer
Active : Do: User interactions
Active : Do: Refresh token periodically
Active : Exit: Save state

Active --> Active : User action [< 30 min idle]
Active --> Idle : No action [30 min timeout]
Active --> LoggedOut : User logout
Active --> LoggedOut : Token expired
Active --> Suspended : Account suspended

Idle : Entry: Pause session
Idle : Do: Show idle warning
Idle : Exit: Resume or logout

Idle --> Active : User interaction
Idle --> LoggedOut : Timeout [5 min]

Suspended : Entry: Clear session
Suspended : Entry: Show suspension notice
Suspended : Do: Contact support

Suspended --> [*]

note right of Authenticating
    Methods:
    - Email/password
    - Biometric (fingerprint/face)
    - Google OAuth
end note

note right of Active
    Session management:
    - JWT token refresh every 15 min
    - Idle timeout: 30 min warning
    - Auto logout: 35 min total idle
end note

note right of Idle
    User gets warning at 30 min:
    "You've been idle. Continue?"
    Auto logout at 35 min
end note

@enduml
```

## BNPL Loan State Diagram

```plantuml
@startuml BNPLLoanStateDiagram

[*] --> Applied : User applies for loan

Applied : Entry: Create loan record
Applied : Do: Validate eligibility
Applied : Exit: Decision made

Applied --> Approved : Credit score >= 550
Applied --> Rejected : Credit score < 550

Approved : Entry: Disburse funds to wallet
Approved : Entry: Create payment schedule
Approved : Entry: Send notification
Approved : Do: Loan active
Approved : Exit: Track payments

Approved --> Active : Funds disbursed

Active : Entry: Start payment tracking
Active : Do: Monitor payment schedule
Active : Exit: Loan status determined

Active --> PendingPayment : Payment due date approaching

PendingPayment : Entry: Send payment reminder
PendingPayment : Do: Wait for payment
PendingPayment : Exit: Payment received or overdue

PendingPayment --> Active : Payment received on time
PendingPayment --> Overdue : Payment missed

Active --> PaidOff : Final payment received

Overdue : Entry: Apply late fee
Overdue : Entry: Reduce credit score
Overdue : Entry: Send overdue notice
Overdue : Do: Wait for payment
Overdue : Exit: Payment status update

Overdue --> Active : Payment received
Overdue --> DefaultRisk : Overdue > 30 days

DefaultRisk : Entry: Suspend account features
DefaultRisk : Entry: Contact user
DefaultRisk : Entry: Major credit score reduction
DefaultRisk : Do: Recovery process
DefaultRisk : Exit: Resolution

DefaultRisk --> Active : Full payment + penalties
DefaultRisk --> Defaulted : No payment > 60 days

Defaulted : Entry: Report to credit bureau
Defaulted : Entry: Initiate legal action
Defaulted : Entry: Ban from future loans
Defaulted : Do: Debt collection

Defaulted --> [*]

PaidOff : Entry: Update credit score positively
PaidOff : Entry: Send completion notification
PaidOff : Entry: Unlock higher loan limits
PaidOff : Do: Loan completed

PaidOff --> [*]

Rejected : Entry: Send rejection notice
Rejected : Entry: Suggest score improvement
Rejected : Do: Cannot proceed

Rejected --> [*]

note right of Active
    Payment tracking:
    - Weekly installments
    - Auto-debit if enabled
    - Manual payment option
    - Reminders 2 days before due
end note

note right of Overdue
    Penalties:
    - Late fee: 2% per week
    - Credit score: -50 points
    - Account restrictions
end note

note right of DefaultRisk
    Restrictions:
    - Cannot apply for new loans
    - Cannot send money
    - Receive only mode
    - Mandatory KYC review
end note

note right of PaidOff
    Benefits:
    - Credit score: +100 points
    - Higher loan limits
    - Better interest rates
    - Priority approval
end note

@enduml
```

## Voice Control State Diagram

```plantuml
@startuml VoiceControlStateDiagram

[*] --> Disabled : App start [voice disabled]
[*] --> Initialized : App start [voice enabled]

Disabled : Entry: No voice features
Disabled : Do: Standard UI only
Disabled : Exit: None

Disabled --> Initialized : User enables voice in settings

Initialized : Entry: Load voice service
Initialized : Entry: Initialize wake word detector
Initialized : Do: Start wake word detection
Initialized : Exit: Cleanup detector

Initialized --> ListeningForWakeWord : Voice service ready

ListeningForWakeWord : Entry: Start microphone
ListeningForWakeWord : Do: Detect "Inka"
ListeningForWakeWord : Do: TTS: "Voice control ready"
ListeningForWakeWord : Exit: Wake word detected

ListeningForWakeWord --> ListeningForWakeWord : Background noise
ListeningForWakeWord --> WakeWordDetected : "Inka" detected
ListeningForWakeWord --> Disabled : User disables voice

WakeWordDetected : Entry: Vibrate haptic
WakeWordDetected : Entry: TTS: "Listening..."
WakeWordDetected : Exit: Start transcription

WakeWordDetected --> ListeningForCommand : Activate Speechmatics

ListeningForCommand : Entry: Stream audio to API
ListeningForCommand : Do: Real-time transcription
ListeningForCommand : Exit: Command received

ListeningForCommand --> ProcessingIntent : Speech detected
ListeningForCommand --> ListeningForWakeWord : Timeout [5 sec silence]

ProcessingIntent : Entry: Analyze transcript
ProcessingIntent : Do: Extract intent & parameters
ProcessingIntent : Exit: Intent identified

ProcessingIntent --> ExecutingCommand : Intent recognized
ProcessingIntent --> CommandNotUnderstood : Intent not recognized

CommandNotUnderstood : Entry: TTS: "Sorry, I didn't understand"
CommandNotUnderstood : Entry: Vibrate error pattern
CommandNotUnderstood : Exit: Reset

CommandNotUnderstood --> ListeningForWakeWord : Return to wake word

ExecutingCommand : Entry: Log command
ExecutingCommand : Do: Execute action
ExecutingCommand : Do: TTS: Progress updates
ExecutingCommand : Exit: Action complete

ExecutingCommand --> NeedsMoreInfo : Missing parameters
ExecutingCommand --> CommandSuccess : Execution successful
ExecutingCommand --> CommandFailed : Execution failed

NeedsMoreInfo : Entry: TTS: Ask for parameter
NeedsMoreInfo : Do: Listen for response
NeedsMoreInfo : Exit: Parameter received

NeedsMoreInfo --> ProcessingIntent : User provides info
NeedsMoreInfo --> ListeningForWakeWord : User cancels

CommandSuccess : Entry: TTS: Success message
CommandSuccess : Entry: Vibrate success pattern
CommandSuccess : Do: Show result
CommandSuccess : Exit: Complete

CommandSuccess --> ListeningForWakeWord : Return to wake word

CommandFailed : Entry: TTS: Error message
CommandFailed : Entry: Vibrate error pattern
CommandFailed : Do: Show error
CommandFailed : Exit: Log error

CommandFailed --> ListeningForWakeWord : Return to wake word

note right of ListeningForWakeWord
    Always active when voice enabled
    Listens for "Inka" keyword
    Low power consumption
end note

note right of ListeningForCommand
    Speechmatics streaming:
    - Real-time transcription
    - 5 second timeout
    - Automatic punctuation
end note

note right of ExecutingCommand
    Supported commands:
    - Check balance
    - Send money
    - Pay bills
    - Buy airtime
    - Request money
    - Check transactions
    - Help
end note

note right of NeedsMoreInfo
    Interactive dialogue:
    System: "To whom?"
    User: "John Banda"
    System: "How much?"
    User: "5000"
end note

@enduml
```

## Credit Score State Diagram

```plantuml
@startuml CreditScoreStateDiagram

[*] --> Unscored : Account created

Unscored : Entry: No transaction history
Unscored : Do: Wait for activity
Unscored : Exit: First transaction

Unscored --> Poor : First score calculation [score < 550]
Unscored --> Fair : First score calculation [550-649]
Unscored --> Good : First score calculation [650-749]
Unscored --> Excellent : First score calculation [750+]

Poor : Entry: Score 300-549
Poor : Entry: Limited loan access
Poor : Do: Monitor for improvement
Poor : Exit: Score recalculated

Poor --> Fair : Positive behavior [+100 points]
Poor --> Poor : Transaction activity
Poor --> VeryPoor : Negative behavior [-50 points]

VeryPoor : Entry: Score < 300
VeryPoor : Entry: No loan access
VeryPoor : Do: Account restricted
VeryPoor : Exit: Improvement needed

VeryPoor --> Poor : Consistent positive activity

Fair : Entry: Score 550-649
Fair : Entry: Basic loan access
Fair : Do: Monitor behavior
Fair : Exit: Score recalculated

Fair --> Good : Positive behavior [+100 points]
Fair --> Poor : Negative behavior [-50 points]
Fair --> Fair : Normal activity

Good : Entry: Score 650-749
Good : Entry: Full loan access
Good : Do: Monitor behavior
Good : Exit: Score recalculated

Good --> Excellent : Excellent behavior [+100 points]
Good --> Fair : Negative behavior [-50 points]
Good --> Good : Normal activity

Excellent : Entry: Score 750+
Excellent : Entry: Premium benefits
Excellent : Do: Monitor behavior
Excellent : Exit: Score recalculated

Excellent --> Good : Negative behavior [-50 points]
Excellent --> Excellent : Positive behavior

note right of Unscored
    New users start here
    Need at least 5 transactions
    or 30 days activity
end note

note left of VeryPoor
    Triggers:
    - Loan defaults
    - Frequent overdues
    - Suspicious activity
    Restrictions:
    - No BNPL access
    - Limited transfers
end note

note right of Poor
    Limited benefits:
    - Small BNPL loans only
    - Higher interest rates
    - Lower transaction limits
end note

note right of Fair
    Standard benefits:
    - Moderate BNPL loans
    - Standard interest
    - Normal limits
end note

note right of Good
    Enhanced benefits:
    - Larger BNPL loans
    - Lower interest
    - Higher limits
end note

note right of Excellent
    Premium benefits:
    - Maximum BNPL loans
    - Lowest interest
    - Highest limits
    - Priority support
    - Special offers
end note

note as PositiveFactors
    **Positive Factors** (+points):
    • Successful BNPL repayments (+50)
    • Regular transactions (+10)
    • Maintaining balance (+20)
    • Long account age (+30)
    • KYC tier upgrade (+40)
end note

note as NegativeFactors
    **Negative Factors** (-points):
    • Late BNPL payment (-30)
    • Loan default (-100)
    • Failed transactions (-10)
    • Account suspension (-50)
    • Negative balance (-20)
end note

@enduml
```

## Notification State Diagram

```plantuml
@startuml NotificationStateDiagram

[*] --> Created : Event occurs

Created : Entry: Generate notification
Created : Entry: Store in database
Created : Do: Prepare content
Created : Exit: Ready to send

Created --> Pending : Notification created

Pending : Entry: Add to send queue
Pending : Do: Wait for delivery
Pending : Exit: Attempt delivery

Pending --> Sending : Delivery started

Sending : Entry: Send to device
Sending : Do: Await confirmation
Sending : Exit: Delivery result

Sending --> Delivered : Delivery confirmed
Sending --> Failed : Delivery failed

Delivered : Entry: Mark as delivered
Delivered : Entry: Store delivery timestamp
Delivered : Do: Wait for user action
Delivered : Exit: User interaction

Delivered --> Read : User opens notification
Delivered --> Expired : Auto-expire [30 days]

Read : Entry: Mark as read
Read : Entry: Update read timestamp
Read : Entry: Execute action if any
Read : Do: Notification archived
Read : Exit: Cleanup

Read --> Archived : User dismisses
Read --> ActionTaken : User taps action

ActionTaken : Entry: Navigate to screen
ActionTaken : Entry: Execute callback
ActionTaken : Do: Process action
ActionTaken : Exit: Action complete

ActionTaken --> Archived : Action completed

Archived : Entry: Move to archive
Archived : Do: Available in history
Archived : Exit: None

Archived --> [*]

Failed : Entry: Log failure
Failed : Entry: Retry counter++
Failed : Do: Wait for retry
Failed : Exit: Retry or give up

Failed --> Sending : Retry [attempts < 3]
Failed --> Abandoned : Max retries reached

Abandoned : Entry: Mark as failed
Abandoned : Entry: Log permanent failure
Abandoned : Do: Cleanup

Abandoned --> [*]

Expired : Entry: Mark as expired
Expired : Entry: Auto-archive
Expired : Do: Cleanup

Expired --> [*]

note right of Created
    Event sources:
    - Transaction completed
    - Money received
    - BNPL payment due
    - KYC status change
    - Login from new device
end note

note right of Sending
    Delivery channels:
    - Push notification
    - In-app notification
    - SMS (for critical)
    - Email (for reports)
end note

note right of Delivered
    Priority levels:
    - High: Security alerts
    - Medium: Transactions
    - Low: Promotional
end note

note right of ActionTaken
    Actions:
    - View transaction
    - Open KYC screen
    - Make payment
    - Contact support
end note

@enduml
```
