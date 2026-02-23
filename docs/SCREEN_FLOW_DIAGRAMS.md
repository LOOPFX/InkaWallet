# InkaWallet Screen Flow Diagrams

## Complete Application Flow

```mermaid
graph TB
    Start([App Launch]) --> CheckAuth{Authenticated?}

    CheckAuth -->|No| Login[Login Screen]
    CheckAuth -->|Yes| Home[Home Screen]

    Login --> BiometricLogin{Biometric<br/>Enabled?}
    BiometricLogin -->|Yes| BiometricAuth[Biometric Auth]
    BiometricLogin -->|No| EmailLogin[Email/Password]

    BiometricAuth -->|Success| Check2FA{2FA<br/>Enabled?}
    EmailLogin -->|Success| Check2FA

    Check2FA -->|Yes| TwoFA[2FA Verification]
    Check2FA -->|No| Home
    TwoFA -->|Success| Home

    Login -->|New User| Register[Register Screen]
    Register -->|Success| Home

    Home --> SendMoney[Send Money Screen]
    Home --> ReceiveMoney[Receive Money Screen]
    Home --> MyQR[My QR Screen]
    Home --> ScanPay[Scan & Pay Screen]
    Home --> TopUp[Top Up Screen]
    Home --> Transactions[Transactions Screen]
    Home --> Airtime[Airtime Screen]
    Home --> Bills[Bills Screen]
    Home --> BNPL[BNPL Screen]
    Home --> CreditScore[Credit Score Screen]
    Home --> Notifications[Notifications Screen]
    Home --> Settings[Settings Screen]

    SendMoney --> ScanPay
    SendMoney -->|Success| TransactionSuccess[Success Dialog]
    TransactionSuccess --> Home

    ReceiveMoney --> MyQR

    ScanPay -->|QR Scanned| SendMoney

    TopUp -->|Mpamba| MpambaWeb[Mpamba Web]
    TopUp -->|Airtel| AirtelWeb[Airtel Money Web]
    MpambaWeb -->|Success| Home
    AirtelWeb -->|Success| Home

    Airtime -->|Success| Home
    Bills -->|Success| Home

    BNPL -->|Apply| BNPLApplication[Loan Application]
    BNPLApplication -->|Success| BNPL
    BNPL -->|Pay| BNPLPayment[Payment Confirmation]
    BNPLPayment -->|Success| BNPL

    Settings --> ChangePassword[Change Password]
    Settings --> KYCStatus[KYC Status Screen]
    Settings --> Profile[Profile Screen]

    KYCStatus -->|Not Started| KYCProfile[KYC Profile Screen]
    KYCProfile -->|Continue| KYCDocuments[KYC Documents Screen]
    KYCDocuments -->|Submit| KYCStatus

    Settings -->|Logout| Login

    style Home fill:#4CAF50,color:#fff
    style Login fill:#2196F3,color:#fff
    style Register fill:#2196F3,color:#fff
    style KYCProfile fill:#FF9800,color:#fff
    style KYCDocuments fill:#FF9800,color:#fff
    style KYCStatus fill:#FF9800,color:#fff
```

## Authentication Flow Detail

```plantuml
@startuml AuthenticationFlow

start

:App Launch;

if (Has Valid Token?) then (yes)
  :Navigate to Home;
  stop
else (no)
  :Show Login Screen;
endif

partition "Login Options" {
  if (User Selection?) then (Email/Password)
    :Enter Email;
    :Enter Password;
    :Tap Login;

    if (Credentials Valid?) then (yes)
      if (2FA Enabled?) then (yes)
        :Generate 2FA Code;
        :Send SMS;
        :Show 2FA Input;
        :User Enters Code;

        if (Code Valid?) then (yes)
          :Generate JWT Token;
          :Navigate to Home;
          stop
        else (no)
          :Show Error;
          stop
        endif
      else (no)
        :Generate JWT Token;
        :Navigate to Home;
        stop
      endif
    else (no)
      :Show "Invalid Credentials";
      stop
    endif

  elseif (Biometric) then
    if (Biometric Available?) then (yes)
      :Show Biometric Prompt;
      :User Provides Biometric;

      if (Verified?) then (yes)
        :Retrieve Saved Credentials;
        :Auto Login;
        :Navigate to Home;
        stop
      else (no)
        :Show Error;
        stop
      endif
    else (no)
      :Show "Not Available";
      stop
    endif

  else (Google OAuth)
    :Redirect to Google;
    :User Authorizes;

    if (Authorized?) then (yes)
      :Retrieve User Info;

      if (Account Exists?) then (yes)
        :Login User;
      else (no)
        :Create Account;
      endif

      :Generate JWT Token;
      :Navigate to Home;
      stop
    else (no)
      :Show Error;
      stop
    endif

  else (Register)
    :Navigate to Register;
    stop
  endif
}

@enduml
```

## Money Transfer Flow

```plantuml
@startuml MoneyTransferFlow

start

:Tap "Send Money";
:Navigate to Send Money Screen;

:Select Recipient;
note right
  Options:
  - From contacts
  - By phone number
  - Scan QR code
  - Recent recipients
end note

if (Recipient Selected?) then (yes)
  :Enter Amount;

  if (Amount Valid?) then (yes)
    :Show Transaction Summary;

    partition "Validation Checks" {
      :Check Balance;

      if (Sufficient Balance?) then (yes)
        :Check KYC Status;

        if (KYC Verified?) then (yes)
          :Check Transaction Limits;

          if (Within Limits?) then (yes)
            :Show Confirmation Dialog;

            if (Amount > 10,000?) then (yes)
              :Request Biometric Auth;

              if (Biometric Verified?) then (yes)
                :Process Transaction;
              else (no)
                :Show "Auth Failed";
                stop
              endif
            else (no)
              :User Confirms;
              :Process Transaction;
            endif

            if (Transaction Success?) then (yes)
              :Update Sender Balance;
              :Update Receiver Balance;
              :Send Notifications;
              :Show Success Dialog;
              :Navigate to Home;
              stop
            else (no)
              :Show Error;
              :Offer Retry;
              stop
            endif

          else (no - limit exceeded)
            :Show "Limit Exceeded";
            :Display Remaining Limit;
            stop
          endif

        else (no - KYC not verified)
          :Show KYC Required Dialog;

          if (User Clicks "Complete KYC"?) then (yes)
            :Navigate to KYC Screen;
            stop
          else (no)
            stop
          endif
        endif

      else (no - insufficient)
        :Show "Insufficient Balance";
        :Suggest Top Up;
        stop
      endif
    }

  else (no - invalid amount)
    :Show "Invalid Amount";
    stop
  endif

else (no)
  :Show "Select Recipient";
  stop
endif

@enduml
```

## KYC Verification Flow

```plantuml
@startuml KYCFlow

start

:Navigate to Settings;
:Tap "KYC Verification";
:Navigate to KYC Status Screen;

if (KYC Status?) then (Not Started)
  :Show "Start KYC" Button;
  :User Taps Start;
  :Navigate to KYC Profile Screen;

  partition "Profile Form" {
    :Enter First Name;
    :Enter Last Name;
    :Enter Date of Birth;
    :Enter National ID;
    :Enter Address;
    :Select Gender;

    if (Has Disability?) then (yes)
      :Select Disability Type;
    endif

    :Enter Occupation;
    :Tap "Save & Continue";

    if (Form Valid?) then (yes)
      :Save Profile;
      :Navigate to Document Upload;
    else (no)
      :Show Validation Errors;
      stop
    endif
  }

  partition "Document Upload" {
    repeat
      :Tap "Upload Document";
      :Select Document Type;

      if (Voice Guidance Enabled?) then (yes)
        :Speak: "Position document in frame";
      endif

      :Choose Camera or Gallery;

      if (Camera?) then (yes)
        :Open Camera;
        :Capture Photo;
      else (gallery)
        :Open Gallery;
        :Select Photo;
      endif

      :Upload to Server;

      if (Upload Success?) then (yes)
        :Show Success;
        if (Voice Enabled?) then (yes)
          :Speak: "Document uploaded";
        endif
      else (no)
        :Show Error;
        :Offer Retry;
      endif

    repeat while (Documents < 2?)

    :Enable Submit Button;
    :User Taps Submit;

    if (Minimum Docs Uploaded?) then (yes)
      :Submit for Verification;
      :Update Status to "Pending";
      :Send Admin Notification;
      :Navigate to Status Screen;
      stop
    else (no)
      :Show "Upload More Docs";
      stop
    endif
  }

elseif (Pending Verification) then
  :Show Pending Status;
  :Display Expected Wait Time;
  note right: "Usually 24-48 hours"
  stop

elseif (Verified) then
  :Show Verification Badge;
  :Display Tier Level;
  :Show Transaction Limits;
  :Show Benefits;

  if (Tier < 3?) then (yes)
    :Show "Upgrade Tier" Button;
  endif

  stop

else (Rejected)
  :Show Rejection Reason;
  :Show "Resubmit KYC" Button;

  if (User Clicks Resubmit?) then (yes)
    :Reset Status;
    :Navigate to Profile Form;
    stop
  else (no)
    stop
  endif
endif

@enduml
```

## BNPL Loan Flow

```plantuml
@startuml BNPLFlow

start

:Navigate to BNPL Screen;

partition "Eligibility Check" {
  :Check KYC Status;

  if (KYC Verified?) then (yes)
    :Calculate Credit Score;

    partition "Credit Calculation" {
      :Analyze Transaction History;
      :Check BNPL Repayment History;
      :Check Account Age;
      :Calculate Final Score;
    }

    if (Credit Score >= 550?) then (yes)
      :Show Eligible Status;
      :Display Credit Score;
      :Show Loan Options;

      :User Selects Loan Duration;
      note right
        Options:
        - 4 weeks (5% interest)
        - 8 weeks (8% interest)
        - 12 weeks (10% interest)
      end note

      :User Enters Loan Amount;

      if (Amount <= Max Allowed?) then (yes)
        :Calculate Loan Details;
        note right
          - Principal
          - Interest
          - Total amount
          - Weekly payment
        end note

        :Show Loan Summary;
        :User Taps "Apply for Loan";
        :Show Confirmation Dialog;
        :User Confirms;

        :Create Loan Record;
        :Add Amount to Wallet;
        :Create Transaction;
        :Generate Payment Schedule;
        :Send Confirmation;

        :Show Success Message;
        :Navigate to BNPL Dashboard;

        partition "Payment Tracking" {
          repeat
            :Wait for Payment Due Date;
            :Send Reminder (2 days before);

            if (Payment Made?) then (yes)
              :Process Payment;
              :Deduct from Wallet;
              :Update Loan Balance;
              :Update Credit Score (+);
              :Send Payment Confirmation;
            else (no - overdue)
              :Mark as Overdue;
              :Apply Late Fee (2% per week);
              :Update Credit Score (-50);
              :Send Overdue Notice;

              if (Overdue > 30 Days?) then (yes)
                :Suspend Account Features;
                :Cannot apply for new loans;
                :Cannot send money;
                :Contact user;

                if (Overdue > 60 Days?) then (yes)
                  :Mark as Defaulted;
                  :Report to Credit Bureau;
                  :Initiate Legal Action;
                  :Ban from Future Loans;
                  stop
                endif
              endif
            endif

          repeat while (Loan Balance > 0?)

          :Mark Loan as Paid Off;
          :Update Credit Score (+100);
          :Unlock Higher Limits;
          :Send Completion Notification;
          stop
        }

      else (no - exceeds max)
        :Show "Amount Exceeds Maximum";
        stop
      endif

    else (no - low score)
      :Show "Credit Score Too Low";
      :Suggest Ways to Improve;
      note right
        - Complete more transactions
        - Maintain positive balance
        - Upgrade KYC tier
      end note
      stop
    endif

  else (no - not verified)
    :Show KYC Required Dialog;

    if (User Clicks "Complete KYC"?) then (yes)
      :Navigate to KYC Screen;
      stop
    else (no)
      stop
    endif
  endif
}

@enduml
```

## Voice Command Flow

```plantuml
@startuml VoiceFlow

start

:User Opens App;

if (Voice Control Enabled?) then (yes)
  :Initialize Voice Service;
  :Start Wake Word Detection;
  :Speak: "Voice control ready. Say Inka to begin";

  repeat
    :Listen for Wake Word;

    if (Wake Word "Inka" Detected?) then (yes)
      :Vibrate (short);
      :Speak: "Listening...";
      :Start Speechmatics Streaming;

      :User Speaks Command;
      :Transcribe Audio;

      partition "Intent Recognition" {
        :Analyze Transcript;
        :Extract Intent;
        :Extract Parameters;
      }

      if (Intent Recognized?) then (yes)

        switch (Intent Type?)
        case (CHECK_BALANCE)
          :Fetch Wallet Balance;
          :Speak: "Your balance is [amount] Kwacha";
          :Vibrate Success;

        case (SEND_MONEY)
          if (Recipient Parameter?) then (yes)
            if (Amount Parameter?) then (yes)
              :Execute Send Money;
              :Speak Result;
            else (no amount)
              :Speak: "How much?";
              :Listen for Amount;
              :Execute Send Money;
              :Speak Result;
            endif
          else (no recipient)
            :Speak: "To whom?";
            :Listen for Recipient;
            :Speak: "How much?";
            :Listen for Amount;
            :Execute Send Money;
            :Speak Result;
          endif

        case (PAY_BILLS)
          :Speak: "Which utility?";
          :Listen for Utility;
          :Speak: "How much?";
          :Listen for Amount;
          :Execute Bill Payment;
          :Speak Result;

        case (BUY_AIRTIME)
          :Speak: "Which network?";
          :Listen for Network;
          :Speak: "How much?";
          :Listen for Amount;
          :Purchase Airtime;
          :Speak Result;

        case (CHECK_TRANSACTIONS)
          :Fetch Recent Transactions;
          :Speak: "Your last transaction was [details]";

        case (REQUEST_MONEY)
          :Speak: "From whom?";
          :Listen for Person;
          :Speak: "How much?";
          :Listen for Amount;
          :Create Money Request;
          :Speak: "Request sent";

        case (HELP)
          :Speak Available Commands;

        endswitch

        if (Action Successful?) then (yes)
          :Speak Success Message;
          :Vibrate Success Pattern;
        else (no)
          :Speak Error Message;
          :Vibrate Error Pattern;
        endif

      else (no - not recognized)
        :Speak: "Sorry, I didn't understand";
        :Vibrate Error;
      endif

      :Stop Listening;
      :Return to Wake Word Detection;

    else (no)
      :Continue Listening;
    endif

  repeat while (App is Active?)

else (no - disabled)
  :Use Standard UI;
  stop
endif

stop

@enduml
```

## Settings & Profile Flow

```mermaid
graph TD
    Home[Home Screen] --> Settings[Settings Screen]

    Settings --> Profile[Profile Screen]
    Settings --> ChangePassword[Change Password]
    Settings --> KYC[KYC Status]
    Settings --> BiometricToggle{Toggle Biometric}
    Settings --> 2FAToggle{Toggle 2FA}
    Settings --> VoiceToggle{Toggle Voice}
    Settings --> TTSToggle{Toggle TTS}
    Settings --> ContrastToggle{Toggle High Contrast}
    Settings --> FontSlider[Font Size Slider]
    Settings --> Notifications[Notification Settings]
    Settings --> About[About]
    Settings --> Terms[Terms & Privacy]
    Settings --> Logout[Logout]

    BiometricToggle -->|Enable| BiometricSetup[Biometric Setup]
    BiometricSetup --> BiometricPrompt[Device Prompt]
    BiometricPrompt -->|Success| SaveCredentials[Save Encrypted Credentials]
    SaveCredentials --> Settings

    2FAToggle -->|Enable| Generate2FA[Generate Code]
    Generate2FA --> SendSMS[Send SMS]
    SendSMS --> Enter2FA[Enter Code]
    Enter2FA -->|Valid| Enable2FA[Enable 2FA]
    Enable2FA --> Settings

    KYC --> KYCStatus[KYC Status Screen]
    KYCStatus -->|Not Started| KYCProfile[KYC Profile]
    KYCProfile --> KYCDocs[KYC Documents]
    KYCDocs --> KYCStatus

    Logout --> ConfirmLogout{Confirm?}
    ConfirmLogout -->|Yes| ClearSession[Clear Session]
    ClearSession --> Login[Login Screen]

    style Settings fill:#2196F3,color:#fff
    style KYCProfile fill:#FF9800,color:#fff
    style KYCDocs fill:#FF9800,color:#fff
```

## Transaction History Flow

```plantuml
@startuml TransactionHistoryFlow

start

:Navigate to Transactions Screen;

:Load Recent Transactions;
note right: Default: Last 20 transactions

:Display Transaction List;

partition "User Actions" {

  if (User Action?) then (Filter by Type)
    :Tap Filter Tab;
    note right
      Tabs:
      - All
      - Send
      - Receive
      - Bills
      - BNPL
    end note
    :Reload Filtered List;

  elseif (Search) then
    :Enter Search Query;
    note right: Search by recipient, amount, ref
    :Filter Results;
    :Display Matches;

  elseif (Date Filter) then
    :Select Date Range;
    note right
      Options:
      - Today
      - This Week
      - This Month
      - Custom Range
    end note
    :Apply Filter;
    :Reload List;

  elseif (Export) then
    :Tap "Export PDF";
    :Generate PDF;
    :Show Share Sheet;
    :User Shares or Saves;

  elseif (View Details) then
    :Tap Transaction Card;
    :Show Transaction Details Dialog;
    note right
      Details:
      - Full amount
      - Date/time
      - Recipient/sender
      - Reference number
      - Status
      - Description
    end note

  elseif (Load More) then
    :Tap "Load More";
    :Fetch Next 20;
    :Append to List;

  else (Back)
    :Navigate to Home;
    stop
  endif
}

@enduml
```

## Notification Flow

```mermaid
graph TD
    Event[Transaction/Event Occurs] --> CreateNotif[Create Notification]
    CreateNotif --> StoreDB[Store in Database]
    StoreDB --> SendPush[Send Push Notification]

    SendPush --> UserDevice[User Device]
    UserDevice --> NotifReceived{Notification Received}

    NotifReceived -->|Tap| OpenApp[Open App]
    NotifReceived -->|Ignore| MarkDelivered[Mark as Delivered]

    OpenApp --> Navigate{Has Action?}
    Navigate -->|Transaction| TransactionScreen[Transaction Screen]
    Navigate -->|KYC| KYCScreen[KYC Status Screen]
    Navigate -->|BNPL| BNPLScreen[BNPL Screen]
    Navigate -->|General| NotifCenter[Notification Center]

    TransactionScreen --> MarkRead[Mark as Read]
    KYCScreen --> MarkRead
    BNPLScreen --> MarkRead
    NotifCenter --> MarkRead

    MarkRead --> Archive[Archive Notification]

    style Event fill:#4CAF50,color:#fff
    style OpenApp fill:#2196F3,color:#fff
```

## Error Handling Flow

```plantuml
@startuml ErrorHandlingFlow

start

:User Performs Action;

partition "Action Execution" {
  :Execute API Request;

  if (Network Available?) then (yes)
    :Send Request;

    if (Response Status?) then (200 OK)
      :Parse Response;
      :Update UI;
      :Show Success;
      stop

    elseif (401 Unauthorized) then
      :Clear Session;
      :Navigate to Login;
      :Show "Session Expired";
      stop

    elseif (403 Forbidden) then
      :Show "Access Denied";
      :Log Error;
      stop

    elseif (404 Not Found) then
      :Show "Resource Not Found";
      :Offer Retry;
      stop

    elseif (422 Validation Error) then
      :Parse Error Details;
      :Highlight Invalid Fields;
      :Show Validation Messages;
      stop

    elseif (429 Too Many Requests) then
      :Show "Rate Limit Exceeded";
      :Show Retry Timer;
      stop

    elseif (500 Server Error) then
      :Show "Server Error";
      :Log Error;
      :Offer Retry;
      :Contact Support Option;
      stop

    else (Other Error)
      :Show Generic Error;
      :Log Error Details;
      :Offer Retry;
      stop
    endif

  else (no - offline)
    :Show "No Internet Connection";
    :Enable Offline Mode;

    if (Action Can Be Queued?) then (yes)
      :Queue Action;
      :Show "Will Sync When Online";

      repeat
        :Wait for Connection;
      repeat while (Still Offline?)

      :Process Queued Actions;
      :Show Sync Status;
      stop

    else (no - requires online)
      :Show "This Requires Internet";
      :Disable Action;
      stop
    endif
  endif
}

@enduml
```

---

## Deep Link Flows

### Push Notification Deep Links

```mermaid
graph LR
    Push[Push Notification] --> AppLaunch{App State}

    AppLaunch -->|Closed| ColdStart[Cold Start]
    AppLaunch -->|Background| WarmStart[Warm Start]
    AppLaunch -->|Foreground| HandleInApp[Handle In-App]

    ColdStart --> ParseDeepLink[Parse Deep Link]
    WarmStart --> ParseDeepLink
    HandleInApp --> ParseDeepLink

    ParseDeepLink --> Route{Route Type}

    Route -->|transaction| TxScreen[Transaction Screen]
    Route -->|kyc| KYCScreen[KYC Status Screen]
    Route -->|bnpl| BNPLScreen[BNPL Screen]
    Route -->|payment_due| BNPLPayment[BNPL Payment]
    Route -->|money_received| TxDetail[Transaction Detail]
```

### QR Code Flows

```mermaid
graph TD
    ScanQR[Scan QR Code] --> ParseQR{QR Type}

    ParseQR -->|User Payment| ExtractUser[Extract User ID]
    ParseQR -->|Amount Specified| ExtractAmount[Extract User ID & Amount]

    ExtractUser --> SendMoney[Send Money Screen]
    ExtractAmount --> SendMoney

    SendMoney --> PreFillRecipient[Pre-fill Recipient]
    ExtractAmount --> PreFillAmount[Pre-fill Amount]

    PreFillRecipient --> UserEntersAmount[User Enters Amount]
    PreFillAmount --> UserConfirms[User Confirms]

    UserEntersAmount --> ConfirmTx[Confirm Transaction]
    UserConfirms --> ConfirmTx

    ConfirmTx --> ProcessPayment[Process Payment]
```
