# InkaWallet Accessibility & Voice Control Documentation

## Overview

InkaWallet is designed as a fully accessible digital wallet that can be operated entirely through voice commands, biometric authentication, and haptic feedback. This makes it usable by everyone, including blind users and people with upper limb impairments.

## Accessibility Features

### 1. **Biometric Authentication**

Supports multiple biometric methods for secure, touch-free access:

- **Fingerprint Recognition** - Quick unlock with fingerprint
- **Face Recognition** - Hands-free authentication with facial scan
- **Iris Scan** - Advanced biometric security (device-dependent)

#### Implementation

```dart
// BiometricService
- authenticate() - General biometric authentication
- authenticateForLogin() - Biometric login
- authenticateForTransaction(amount) - Confirm transactions
- enableBiometric() - Enable biometric authentication
- hasFaceRecognition() - Check if face recognition available
- hasFingerprint() - Check if fingerprint available
```

### 2. **Voice Control System**

Complete hands-free navigation using advanced voice commands powered by Speechmatics API.

#### Voice Commands

**Navigation Commands:**

- "Help" - Get list of available commands
- "Go back" - Return to previous screen
- "Settings" - Open settings
- "Balance" - Check wallet balance

**Transaction Commands:**

- "Send money" - Initiate money transfer
- "Send [amount] to [number]" - Direct transfer (e.g., "Send 100 to 0888123456")
- "Request money" - Request money from someone
- "Confirm" - Confirm transaction
- "Cancel" - Cancel transaction

**Service Commands:**

- "Buy airtime" - Purchase mobile airtime
- "Pay bills" - Pay utility bills
- "Scan QR" - Activate QR scanner
- "My QR" - Show your QR code
- "Credit score" - Check credit score
- "BNPL" or "Buy now pay later" - Access BNPL services

**Authentication Commands:**

- "Login" - Voice-guided login process
- "Register" - Voice-guided registration

#### Voice Login Process

1. User says "Login"
2. System asks for email (supports natural speech: "john at example dot com")
3. System asks for password
4. System confirms and logs in

### 3. **Haptic Feedback Patterns**

Different vibration patterns for different actions:

```dart
// Vibration Patterns
- vibrateShort() - Quick tap (50ms) - Button press
- vibrateDouble() - Two pulses - Mode change
- vibrateSuccess() - Triple pulse pattern - Success confirmation
- vibrateError() - Long-short pattern - Error notification
- vibrateNavigation() - Brief pulse (30ms) - Screen navigation
- vibrateAction() - Medium pulse (100ms) - Action trigger
- vibrateConfirmation() - Triple confirmation pattern - Transaction confirmed
```

### 4. **Text-to-Speech (TTS)**

All UI elements and actions are announced:

- Screen names when navigating
- Button labels when focused
- Input field names when selected
- Transaction amounts and recipients
- Confirmation messages
- Error messages

#### TTS Configuration

- Language: English (US)
- Speech Rate: 0.5 (slower for clarity)
- Volume: 1.0 (maximum)
- Pitch: 1.0 (normal)

### 5. **Speech Recognition**

Real-time speech-to-text for:

- Voice commands
- Email input (converts "at" to @, "dot" to .)
- Phone number input
- Amount input (supports "kwacha" or "MKW")
- Account number recognition

## Speechmatics API Integration

### Configuration

The app integrates with Speechmatics for advanced voice recognition:

```dart
// Initialize Speechmatics
SpeechmaticsService service = SpeechmaticsService();
await service.initialize();

// Set API key (store securely in production)
await service.setApiKey('YOUR_SPEECHMATICS_API_KEY');
```

### Real-time Recognition Configuration

```json
{
  "type": "StartRecognition",
  "audio_format": {
    "type": "raw",
    "encoding": "pcm_s16le",
    "sample_rate": 16000
  },
  "transcription_config": {
    "language": "en",
    "operating_point": "enhanced",
    "enable_partials": true,
    "max_delay": 3.0,
    "enable_entities": true
  }
}
```

### Intent Detection

The system automatically detects user intent from speech:

```dart
// Example intent detection
"Send 100 kwacha to 0888123456"
→ Intent: send_money
→ Amount: 100.0
→ Recipient: "0888123456"
→ Confidence: 0.9
```

## Usage Examples

### Example 1: Voice-Controlled Money Transfer

```
User: "Send money"
App: "How much would you like to send?"
User: "One hundred kwacha"
App: "Who would you like to send 100 kwacha to?"
User: "Zero eight eight eight one two three four five six"
App: "Sending 100 kwacha to 0888123456. Say confirm to proceed or cancel to abort."
User: "Confirm"
App: *vibrates confirmation pattern* "Transaction successful"
```

### Example 2: Voice Login

```
User: "Login"
App: "Please say your email address"
User: "admin at inkawallet dot com"
App: "Please say your password"
User: "admin one two three"
App: *vibrates* "Login successful. Welcome!"
```

### Example 3: Biometric Login

```
User: *Taps biometric login card*
App: "Authenticating with biometrics" *face scan or fingerprint*
App: *vibrates confirmation* "Login successful. Welcome!"
```

### Example 4: Voice Navigation

```
User: *Presses floating mic button*
App: *vibrates short* "Listening..."
User: "Check balance"
App: *vibrates success* "Your current balance is 104,800 kwacha"

User: *Presses mic again*
User: "Buy airtime"
App: *vibrates navigation* *Opens airtime screen* "Airtime purchase screen. How much airtime would you like to buy?"
```

## Screen-Specific Features

### Login Screen

- Voice login option
- Biometric quick login card (if available)
- Floating mic button for voice commands
- Voice-guided registration

### Home Screen

- Voice-activated balance check
- Voice command for all services
- Floating mic for continuous voice control
- Haptic feedback on all actions

### Send Money Screen

- Voice input for recipient
- Voice input for amount
- Voice confirmation required
- Biometric authentication for amounts > threshold

### Settings Screen

- Master accessibility toggle
- Individual control for:
  - Voice guidance
  - Voice control
  - Haptic feedback
  - Biometric authentication
- Voice commands help
- Test voice recognition

## Accessibility Best Practices Implemented

1. **Zero Visual Dependency**
   - Complete voice guidance for all UI elements
   - Haptic feedback for all interactions
   - Audio confirmations for all actions

2. **No Touch Required**
   - Voice commands for navigation
   - Voice input for all forms
   - Biometric authentication eliminates typing

3. **Error Prevention**
   - Verbal confirmation required for transactions
   - Clear audio feedback for all inputs
   - Haptic patterns differentiate actions

4. **Multimodal Feedback**
   - Visual + Audio + Haptic for every action
   - Redundant notification systems
   - Clear success/error indicators

5. **Context Awareness**
   - Screen-specific voice commands
   - Smart intent detection
   - Transaction amount extraction

## Security Features

### Biometric Security

- Device-level security (uses platform APIs)
- No biometric data stored in app
- Fallback to password if biometric fails
- Optional biometric for transactions

### Voice Security

- Confidence thresholds for commands
- Confirmation required for sensitive actions
- Session-based voice control
- User can disable voice anytime

### Transaction Security

- Biometric required for large amounts
- Voice confirmation for all transfers
- Haptic feedback before execution
- Audit trail of all commands

## Setup Instructions

### 1. Install Dependencies

```yaml
dependencies:
  local_auth: ^2.2.0 # Biometric authentication
  flutter_tts: ^4.0.2 # Text-to-speech
  speech_to_text: ^7.0.0 # Speech recognition
  vibration: ^2.0.0 # Haptic feedback
  http: ^1.1.2 # For Speechmatics API
```

### 2. Configure Permissions

**Android (AndroidManifest.xml):**

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

**iOS (Info.plist):**

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Voice commands for hands-free navigation</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Voice control for accessibility</string>
<key>NSFaceIDUsageDescription</key>
<string>Face recognition for secure login</string>
```

### 3. Initialize Services

```dart
// In main.dart or app initialization
final accessibility = AccessibilityService();
final biometric = BiometricService();
final voiceCommand = VoiceCommandService();
final speechmatics = SpeechmaticsService();

await accessibility.initialize();
await biometric.initialize();
await voiceCommand.initialize();
await speechmatics.setApiKey('YOUR_API_KEY');
```

### 4. Wrap Screens with Voice Control

```dart
VoiceEnabledScreen(
  screenName: 'home',
  onVoiceCommand: (command) {
    // Handle voice commands
  },
  child: YourScreen(),
)
```

## Testing Accessibility

### Voice Command Testing

1. Enable voice control in settings
2. Tap floating mic button
3. Say "Help" to hear available commands
4. Test each command category
5. Verify audio feedback
6. Check haptic responses

### Biometric Testing

1. Go to Settings
2. Enable biometric authentication
3. Test login with biometrics
4. Test transaction confirmation
5. Verify fallback to password

### Haptic Testing

1. Enable haptic feedback
2. Navigate through app
3. Verify different patterns for different actions
4. Test on different devices

## API Reference

### Voice Command Service

```dart
VoiceCommandService()
  .listenForCommand() // Listen for voice command
  .handleSendMoneyCommand(transcript) // Process send money
  .handleLoginCommand() // Process login
  .provideHelp(screen) // Get available commands
  .activate() // Enable voice mode
  .deactivate() // Disable voice mode
```

### Biometric Service

```dart
BiometricService()
  .authenticate(reason) // General authentication
  .authenticateForLogin() // Login authentication
  .authenticateForTransaction(amount) // Transaction auth
  .enableBiometric() // Enable biometric
  .checkAvailability() // Check if available
```

### Speechmatics Service

```dart
SpeechmaticsService()
  .transcribeAudio(audioFilePath) // Batch transcription
  .extractIntent(transcript) // Get intent from speech
  .extractAmount(transcript) // Extract money amount
  .extractRecipient(transcript) // Extract phone/account
```

## Troubleshooting

### Voice Commands Not Working

1. Check microphone permissions
2. Verify Speechmatics API key
3. Enable voice control in settings
4. Test with "Help" command

### Biometric Not Available

1. Check device support
2. Verify biometric enrolled on device
3. Check app permissions
4. Try alternative biometric type

### Haptic Feedback Not Working

1. Check device vibration support
2. Enable haptics in settings
3. Test device vibration (outside app)
4. Check system DND settings

## Future Enhancements

1. **Multi-language Support**
   - Additional language packs
   - Regional voice models
   - Localized commands

2. **Advanced Voice Features**
   - Speaker recognition
   - Custom wake words
   - Offline voice control

3. **Enhanced Biometrics**
   - Voice biometrics
   - Behavioral biometrics
   - Multi-factor biometric

4. **AI Improvements**
   - Context-aware predictions
   - Smart command suggestions
   - Personalized voice models

## Compliance & Standards

- **WCAG 2.1 Level AAA** - Web Content Accessibility Guidelines
- **Section 508** - US accessibility standards
- **EN 301 549** - European accessibility requirements
- **GDPR** - Biometric data handling
- **PCI DSS** - Transaction security

## Support

For accessibility support:

- Email: accessibility@inkawallet.com
- Voice: Say "Help" anytime in the app
- Documentation: https://docs.inkawallet.com/accessibility

---

**InkaWallet** - Proving that digital wallets can be both secure and fully accessible to everyone.
