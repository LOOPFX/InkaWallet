# InkaWallet Activity Diagrams

## User Registration Process

```plantuml
@startuml UserRegistrationActivity

start
:User opens app;
:Click "Register";

:Enter personal details;
note right
    - Full name
    - Email address
    - Phone number
    - Password
end note

:Click "Register";

if (All fields valid?) then (yes)
    :Submit registration;

    if (Email/phone unique?) then (yes)
        :Create user account;
        :Hash password;
        :Generate JWT token;
        :Send welcome notification;
        :Navigate to home screen;
        stop
    else (no - duplicate)
        :Show error message;
        note right: "Email or phone already registered"
        :Return to registration form;
        stop
    endif
else (no - validation errors)
    :Highlight invalid fields;
    note right
        - Empty fields
        - Invalid email format
        - Weak password
        - Invalid phone format
    end note
    :Return to registration form;
    stop
endif

@enduml
```

## KYC Submission Process

```plantuml
@startuml KYCSubmissionActivity

start
:User navigates to KYC;

if (KYC status?) then (not_started)
    :Show "Start KYC" button;
    :Click "Start KYC";

    :Fill personal information;
    partition "Personal Details" {
        :Enter first name;
        :Enter last name;
        :Enter date of birth;
        :Enter national ID;
        :Enter address;
        :Select gender;
    }

    if (Has disability?) then (yes)
        :Select disability type;
        note right
            - Visual impairment
            - Hearing impairment
            - Mobility impairment
            - Other
        end note
    else (no)
        :Continue;
    endif

    :Click "Save Profile";

    if (Profile valid?) then (yes)
        :Save KYC profile;
        :Navigate to document upload;

        partition "Document Upload" {
            repeat
                :Select document type;
                note right
                    - National ID
                    - Selfie
                    - Proof of address
                end note

                if (Voice guidance enabled?) then (yes)
                    :Speak: "Position document in frame";
                endif

                :Choose camera or gallery;

                if (Camera selected?) then (yes)
                    :Open camera;
                    :Capture photo;
                else (gallery selected)
                    :Open gallery;
                    :Select photo;
                endif

                :Upload document;

                if (Upload successful?) then (yes)
                    :Document saved;
                    if (Voice guidance enabled?) then (yes)
                        :Speak: "Document uploaded successfully";
                    endif
                else (no - upload failed)
                    :Show error;
                    :Retry upload;
                endif

            repeat while (Uploaded < 2 documents?)
        }

        :Enable "Submit for Verification";
        :Click "Submit";

        if (Sufficient documents?) then (yes)
            :Submit KYC for verification;
            :Update status to "pending_verification";
            :Send notification to user;
            :Send notification to admins;
            :Navigate to status screen;
            stop
        else (no - insufficient)
            :Show error: "Upload at least 2 documents";
            :Return to upload screen;
            stop
        endif

    else (no - validation errors)
        :Highlight errors;
        :Return to profile form;
        stop
    endif

elseif (pending_verification) then
    :Show pending status;
    :Display expected review time;
    note right: "Under review. Usually 24-48 hours"
    stop

elseif (verified) then
    :Show verified status;
    :Display verification tier;
    :Show transaction limits;
    stop

else (rejected)
    :Show rejection reason;
    :Show "Resubmit KYC" button;
    if (User clicks resubmit?) then (yes)
        :Reset KYC status;
        :Navigate to profile form;
        stop
    else (no)
        stop
    endif
endif

@enduml
```

## Send Money Transaction Process

```plantuml
@startuml SendMoneyActivity

start
:User navigates to "Send Money";
:Load wallet balance;
:Display balance;

:Select recipient;
note right
    - From contacts
    - From recent transactions
    - By phone number
    - By QR code scan
end note

:Enter amount;
:Enter description (optional);

if (Amount > 0?) then (yes)
    if (Amount <= balance?) then (yes)

        :Check KYC status;

        if (KYC verified?) then (yes)
            :Check transaction limits;

            partition "Limit Check" {
                :Get daily limit;
                :Get monthly limit;
                :Get daily spent amount;
                :Get monthly spent amount;
                :Calculate remaining limits;
            }

            if (Amount within limits?) then (yes)
                :Show transaction summary;
                note right
                    Recipient: John Doe
                    Amount: MKW 5,000
                    Fee: MKW 0
                    Total: MKW 5,000
                end note

                :Click "Confirm";

                if (Biometric auth enabled?) then (yes)
                    :Request biometric;
                    if (Biometric verified?) then (yes)
                        :Process transaction;
                    else (no - auth failed)
                        :Show error;
                        :Cancel transaction;
                        stop
                    endif
                else (no)
                    :Process transaction;
                endif

                partition "Transaction Processing" {
                    :Begin database transaction;
                    :Lock sender wallet;
                    :Deduct from sender balance;
                    :Lock receiver wallet;
                    :Add to receiver balance;
                    :Create transaction record;
                    :Update transaction monitoring;
                    :Commit database transaction;
                }

                if (Transaction successful?) then (yes)
                    :Send notification to sender;
                    :Send notification to receiver;
                    :Update local wallet balance;
                    :Add to local notifications;
                    :Show success message;
                    if (Voice enabled?) then (yes)
                        :Speak: "Money sent successfully";
                        :Success haptic feedback;
                    endif
                    stop
                else (no - failed)
                    :Rollback transaction;
                    :Show error message;
                    stop
                endif

            else (no - exceeds limit)
                :Show limit error;
                note right
                    "Daily limit exceeded"
                    Remaining: MKW 2,000
                end note
                stop
            endif

        else (no - KYC not verified)
            :Show KYC required dialog;
            if (User clicks "Complete KYC"?) then (yes)
                :Navigate to KYC screen;
                stop
            else (no)
                :Cancel transaction;
                stop
            endif
        endif

    else (no - insufficient balance)
        :Show error: "Insufficient balance";
        :Suggest top-up;
        stop
    endif
else (no - invalid amount)
    :Show error: "Enter valid amount";
    stop
endif

@enduml
```

## BNPL Loan Application Process

```plantuml
@startuml BNPLLoanActivity

start
:User navigates to BNPL;

:Check KYC status;

if (KYC verified?) then (yes)
    :Calculate credit score;

    partition "Credit Score Calculation" {
        :Analyze transaction history;
        :Check BNPL repayment history;
        :Check account age;
        :Calculate final score;
    }

    if (Credit score >= 550?) then (yes)
        :Show BNPL options;
        note right
            - 4 weeks loan
            - 8 weeks loan
            - 12 weeks loan
            Interest: 5%
        end note

        :Select loan option;
        :Enter loan amount;

        :Calculate loan details;
        note right
            Principal: MKW 10,000
            Interest (5%): MKW 500
            Total: MKW 10,500
            Weekly payment: MKW 2,625
        end note

        :Show loan summary;
        :Click "Apply for Loan";

        if (Amount within limits?) then (yes)
            :Create loan record;
            :Add amount to wallet;
            :Create transaction record;
            :Send confirmation notification;

            if (Voice enabled?) then (yes)
                :Speak: "Loan approved. MKW 10,000 added to wallet";
            endif

            :Show success message;
            :Navigate to BNPL dashboard;

            partition "Loan Repayment Tracking" {
                repeat
                    :Wait for payment due date;
                    :Send payment reminder;

                    if (User pays installment?) then (yes)
                        :Process payment;
                        :Update loan record;
                        :Send payment confirmation;
                    else (no)
                        :Mark payment as overdue;
                        :Apply late fee (if applicable);
                        :Update credit score;
                        :Send overdue notice;
                    endif
                repeat while (Loan not fully paid?)
            }

            :Mark loan as completed;
            :Update credit score;
            :Send completion notification;
            stop

        else (no - exceeds limit)
            :Show error: "Amount exceeds maximum";
            stop
        endif

    else (no - low score)
        :Show error: "Credit score too low";
        :Suggest ways to improve score;
        note right
            - Complete more transactions
            - Maintain positive balance
            - Verify KYC to higher tier
        end note
        stop
    endif

else (no - KYC not verified)
    :Show KYC required dialog;
    if (User clicks "Complete KYC"?) then (yes)
        :Navigate to KYC screen;
        stop
    else (no)
        stop
    endif
endif

@enduml
```

## Voice Command Processing

```plantuml
@startuml VoiceCommandActivity

start
:User opens app;

if (Voice control enabled?) then (yes)
    :Initialize wake word detection;
    :Speak: "Voice control ready. Say Inka to begin";

    repeat
        :Listen for wake word;

        if (Wake word detected?) then (yes - "Inka")
            :Speak: "Listening...";
            :Vibrate (short);
            :Start Speechmatics streaming;

            :User speaks command;
            :Transcribe audio in real-time;

            partition "Intent Recognition" {
                :Analyze transcript;
                :Extract intent;
                :Extract parameters;
            }

            if (Intent recognized?) then (yes)

                fork
                    :CHECK_BALANCE;
                    :Fetch wallet balance;
                    :Speak: "Your balance is MKW 25,000";
                    :Vibrate success;
                fork again
                    :SEND_MONEY;
                    if (Parameters complete?) then (yes)
                        :Execute send money;
                    else (no - missing params)
                        :Ask: "To whom?";
                        :Listen for recipient;
                        :Ask: "How much?";
                        :Listen for amount;
                        :Execute send money;
                    endif
                fork again
                    :PAY_BILLS;
                    :Ask: "Which utility?";
                    :Listen for utility;
                    :Ask: "How much?";
                    :Listen for amount;
                    :Execute bill payment;
                fork again
                    :CHECK_TRANSACTIONS;
                    :Fetch recent transactions;
                    :Speak: "Your last transaction was...";
                fork again
                    :REQUEST_MONEY;
                    :Ask: "From whom?";
                    :Listen for person;
                    :Ask: "How much?";
                    :Listen for amount;
                    :Create money request;
                fork again
                    :BUY_AIRTIME;
                    :Ask: "Which network?";
                    :Listen for network;
                    :Ask: "How much?";
                    :Listen for amount;
                    :Purchase airtime;
                fork again
                    :HELP;
                    :Speak available commands;
                end fork

                if (Action successful?) then (yes)
                    :Speak success message;
                    :Vibrate success pattern;
                else (no - error)
                    :Speak error message;
                    :Vibrate error pattern;
                endif

            else (no - not recognized)
                :Speak: "Sorry, I didn't understand. Please try again";
                :Vibrate error;
            endif

            :Stop listening;
            :Return to wake word detection;

        else (no - no wake word)
            :Continue listening;
        endif

    repeat while (App is active?)

else (no - voice disabled)
    :Use standard UI;
    stop
endif

stop

@enduml
```

## Admin KYC Verification Process

```plantuml
@startuml AdminKYCVerificationActivity

start
:Admin logs in;
:Navigate to Admin Panel;
:Click "KYC Verifications";

:Load pending KYC list;

if (Pending KYCs available?) then (yes)
    :Select KYC profile;
    :Display user details;

    partition "Document Review" {
        :View National ID photo;
        :View selfie photo;
        :View proof of address;

        :Check photo quality;
        :Verify ID authenticity;
        :Match selfie with ID photo;
        :Verify address proof;
    }

    partition "Compliance Checks" {
        :Check against watchlist;
        :Verify age (18+);
        :Check for duplicate accounts;
        :Verify Malawian residency;
    }

    partition "AML/CFT Verification" {
        :Search PEP database;
        :Check sanctions lists;
        :Verify source of funds (if applicable);
    }

    if (All checks passed?) then (yes)
        :Decision: Approve;

        partition "Tier Assignment" {
            if (Basic documents only?) then (yes)
                :Assign Tier 1;
                note right
                    Daily: MKW 50,000
                    Monthly: MKW 500,000
                end note
            elseif (Enhanced documents + proof?) then (yes)
                :Assign Tier 2;
                note right
                    Daily: MKW 200,000
                    Monthly: MKW 2,000,000
                end note
            else (Complete verification)
                :Assign Tier 3;
                note right
                    Unlimited
                end note
            endif
        }

        :Update KYC status to "verified";
        :Record verification details;
        :Add to verification history;
        :Send approval notification to user;
        :Generate compliance report;

        if (Reserve Bank reporting required?) then (yes)
            :Submit to RBM system;
        endif

        :Show success message;
        :Return to pending list;

    else (no - checks failed)
        :Decision: Reject;
        :Enter rejection reason;
        note right
            - Document unclear
            - ID mismatch
            - Underage
            - Duplicate account
            - Failed AML check
        end note

        :Update KYC status to "rejected";
        :Record rejection details;
        :Add to verification history;
        :Send rejection notification to user;
        :Show rejection message;
        :Return to pending list;
    endif

else (no pending)
    :Show "No pending verifications";
    stop
endif

@enduml
```

## Biometric Authentication Setup

```plantuml
@startuml BiometricSetupActivity

start
:User navigates to Settings;
:Click "Security";
:Click "Enable Biometric Login";

:Check device capability;

if (Biometric hardware available?) then (yes)
    if (Biometric enrolled on device?) then (yes)
        :Show biometric prompt;
        note right: "Confirm your fingerprint/face"

        :User provides biometric;

        if (Biometric verified?) then (yes)
            :Get user credentials;
            :Encrypt credentials;
            :Store in secure storage;
            :Enable biometric login flag;
            :Show success message;
            note right: "Biometric login enabled"
            stop
        else (no - verification failed)
            :Show error;
            note right: "Biometric verification failed. Try again"
            stop
        endif

    else (no - not enrolled)
        :Show enrollment prompt;
        :Guide user to device settings;
        note right: "Please set up fingerprint/face ID in device settings"
        stop
    endif

else (no - not supported)
    :Show not supported message;
    note right: "Biometric authentication not supported on this device"
    stop
endif

@enduml
```

## Two-Factor Authentication Flow

```plantuml
@startuml TwoFactorAuthActivity

start

partition "Enable 2FA" {
    :User navigates to Settings;
    :Click "Enable 2FA";

    :Request 2FA code;
    :Generate 6-digit code;
    :Set expiry (10 minutes);
    :Save code to database;
    :Send SMS to user phone;

    :Show code input screen;
    :User enters code;

    if (Code correct and not expired?) then (yes)
        :Mark code as used;
        :Enable 2FA for user;
        :Show success message;
    else (no)
        if (Code expired?) then (yes)
            :Show "Code expired";
            :Offer to resend;
        else (incorrect)
            :Show "Invalid code";
            :Allow retry (max 3 attempts);
        endif
    endif
}

partition "Login with 2FA" {
    :User enters email & password;
    :Verify credentials;

    if (Credentials valid?) then (yes)
        if (2FA enabled for user?) then (yes)
            :Generate new 2FA code;
            :Send SMS;
            :Show code input;

            :User enters code;

            if (Code valid?) then (yes)
                :Mark code as used;
                :Generate JWT token;
                :Login successful;
                :Navigate to home;
                stop
            else (no)
                :Show error;
                :Allow retry;
                stop
            endif
        else (no 2FA)
            :Generate JWT token;
            :Login successful;
            stop
        endif
    else (no - invalid)
        :Show error;
        stop
    endif
}

@enduml
```
