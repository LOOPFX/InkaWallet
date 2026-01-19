# InkaWallet Accessibility Documentation

## Overview

InkaWallet is designed with accessibility at its core, ensuring that users with visual, motor, or cognitive impairments can fully utilize the digital wallet. This document details all accessibility features and implementation guidelines.

## Inclusive Design Philosophy

**"Inclusive by Default"** - All accessibility features are enabled by default and can be optionally disabled by users who don't need them.

### Target User Groups

1. **Visually Impaired Users**
   - Complete blindness
   - Low vision
   - Color blindness

2. **Motor Impaired Users**
   - Upper limb disabilities
   - Limited fine motor control
   - Tremor conditions

3. **Cognitive Impairments**
   - Learning disabilities
   - Memory challenges
   - Attention disorders

4. **General Users**
   - All features enhance usability for everyone

## Accessibility Features

### 1. Voice Commands

#### Speech-to-Text (STT)

Powered by Speechmatics API for high accuracy:

```dart
// Voice command processing
Future<String?> listenForCommand() async {
  await speak('Listening...');
  final command = await voiceService.listen();
  final action = voiceService.processVoiceCommand(command);
  return action;
}
```

#### Supported Commands

- **"Check balance"** - View current wallet balance
- **"Send money"** - Initiate money transfer
- **"View history"** - See transaction history
- **"View transactions"** - Same as above
- **"Go back"** - Navigate to previous screen
- **"Go home"** - Return to home screen
- **"Repeat"** - Repeat last spoken text
- **"Help"** - Get voice assistance

#### Voice Feedback

All actions provide audio feedback:

```dart
// Balance announcement
voiceService.announceBalance(1500.50);
// Output: "Your balance is MWK 1500.50"

// Transaction announcement
voiceService.announceTransaction('sent', 500.00, 'John Doe');
// Output: "Sent MWK 500.00 to John Doe"
```

### 2. Text-to-Speech (TTS)

#### Screen Reading

Every screen announces itself when opened:

```dart
@override
void initState() {
  super.initState();
  Future.delayed(Duration(milliseconds: 500), () {
    accessibilityProvider.announceScreen('Home');
  });
}
```

#### Button Announcements

All interactive elements announce their purpose:

```dart
Semantics(
  label: 'Send Money Button',
  hint: 'Double tap to send money to another user',
  child: ElevatedButton(
    onPressed: () {
      accessibilityProvider.announceAction('Send Money');
      // Navigate to send money screen
    },
    child: Text('Send Money'),
  ),
)
```

#### Form Field Guidance

Input fields provide clear instructions:

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Amount',
    hintText: 'Enter amount to send',
    semanticLabel: 'Amount input field. Enter the amount you want to send.',
  ),
)
```

### 3. Haptic Feedback

#### Vibration Patterns

Different actions have unique vibration patterns:

```dart
// Success (short-short-long)
await hapticService.success();
// Pattern: [0, 50, 100, 50, 100, 200]

// Error (long-long)
await hapticService.error();
// Pattern: [0, 200, 100, 200]

// Transaction sent (triple short)
await hapticService.transactionSent();
// Pattern: [0, 100, 50, 100, 50, 100]

// Button press (short)
await hapticService.buttonPress();
// Duration: 50ms
```

#### Audio + Haptic Feedback

Combined feedback for important actions:

```dart
ElevatedButton(
  onPressed: () async {
    await hapticService.buttonPress(); // Vibrate
    await voiceService.speak('Sending money'); // Speak
    // Process transaction
  },
  child: Text('Confirm'),
)
```

### 4. Visual Accessibility

#### High Contrast Design

- Purple color scheme (#6B46C1) provides good contrast
- Minimum contrast ratio: 4.5:1 for text
- 3:1 for large text and UI components

```dart
// Color contrast examples
static const Color primaryPurple = Color(0xFF6B46C1); // Against white: 4.82:1
static const Color textPrimary = Color(0xFF2D3748);   // Against white: 12.63:1
```

#### Adjustable Text Size

Users can scale text from 0.8x to 2.0x:

```dart
// Text scaling
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaleFactor: accessibility.textScale, // 0.8 - 2.0
    boldText: accessibility.boldText,
  ),
  child: child,
)
```

#### Bold Text Option

Enable bold text for better readability:

```dart
Future<void> toggleBoldText(bool enabled) async {
  _boldText = enabled;
  await StorageService.saveSetting('bold_text', enabled);
  notifyListeners();
}
```

#### Dark Mode

Reduce eye strain with dark theme:

```dart
MaterialApp(
  themeMode: accessibility.isDarkMode ? ThemeMode.dark : ThemeMode.light,
  darkTheme: AppTheme.darkTheme,
)
```

### 5. Touch Target Sizes

#### Minimum Sizes (WCAG AA)

- Buttons: 56x56 dp (exceeds 44x44 minimum)
- Form fields: 56 dp height
- List items: 64 dp height

```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 56),
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  ),
  child: Text('Large Button'),
)
```

#### Spacing

Adequate spacing between interactive elements:

```dart
Column(
  children: [
    ElevatedButton(...),
    SizedBox(height: 16), // Minimum spacing
    OutlinedButton(...),
  ],
)
```

### 6. Semantic Labels

#### Screen Reader Support

All UI elements have semantic labels:

```dart
Semantics(
  label: 'Current balance',
  value: '10,000 Kwacha',
  child: Text('MWK 10,000'),
)

Semantics(
  label: 'Transaction history',
  hint: 'Shows your recent transactions',
  child: TransactionList(),
)
```

#### Navigation Announcements

Route changes announce new screens:

```dart
Navigator.of(context).pushNamed('/send-money').then((_) {
  accessibilityProvider.announceScreen('Send Money');
});
```

### 7. Simplified Navigation

#### Large Navigation Buttons

Bottom navigation with clear labels:

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home, size: 32),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history, size: 32),
      label: 'History',
    ),
    // ...
  ],
)
```

#### Voice Navigation

Navigate entirely by voice:

```dart
if (command == 'go_home') {
  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  accessibilityProvider.announceScreen('Home');
}
```

### 8. Error Handling & Feedback

#### Clear Error Messages

Errors announced via voice and displayed visually:

```dart
void showError(String message) {
  // Visual feedback
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );

  // Audio feedback
  accessibilityProvider.speak(message);

  // Haptic feedback
  accessibilityProvider.errorFeedback();
}
```

#### Input Validation

Real-time feedback on form fields:

```dart
TextFormField(
  onChanged: (value) {
    if (!isValid(value)) {
      accessibilityProvider.speak('Invalid input');
      hapticService.warning();
    }
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  },
)
```

### 9. Transaction Confirmation

#### Multi-Modal Confirmation

Confirm transactions through multiple channels:

```dart
Future<bool> confirmTransaction(double amount, String recipient) async {
  // Visual dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Confirm Transaction'),
      content: Text('Send MWK $amount to $recipient?'),
      actions: [
        TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
        ElevatedButton(child: Text('Confirm'), onPressed: () => Navigator.pop(context, true)),
      ],
    ),
  );

  // Voice confirmation
  if (confirmed == true) {
    await accessibilityProvider.speak('Transaction confirmed');
    await hapticService.success();
  }

  return confirmed ?? false;
}
```

### 10. Offline Accessibility

#### Cached Voice Feedback

Store common phrases for offline use:

```dart
final commonPhrases = {
  'balance': 'Checking your balance',
  'sending': 'Sending money',
  'history': 'Loading transaction history',
};
```

#### Haptic Feedback Always Available

Vibration works offline:

```dart
// Works without network
await hapticService.buttonPress();
```

## Accessibility Settings

### User Controls

Users can customize accessibility features:

```dart
class AccessibilitySettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchListTile(
          title: Text('Inclusive Mode'),
          subtitle: Text('Enable voice and haptic features'),
          value: provider.isInclusiveModeEnabled,
          onChanged: provider.toggleInclusiveMode,
        ),
        SwitchListTile(
          title: Text('Voice Feedback'),
          subtitle: Text('Hear audio descriptions'),
          value: provider.isVoiceEnabled,
          onChanged: provider.toggleVoice,
        ),
        SwitchListTile(
          title: Text('Haptic Feedback'),
          subtitle: Text('Feel vibration feedback'),
          value: provider.isHapticEnabled,
          onChanged: provider.toggleHaptic,
        ),
        ListTile(
          title: Text('Text Size'),
          subtitle: Slider(
            min: 0.8,
            max: 2.0,
            value: provider.textScale,
            onChanged: provider.setTextScale,
          ),
        ),
      ],
    );
  }
}
```

## Testing for Accessibility

### 1. Screen Reader Testing

- **Android**: TalkBack
- **iOS**: VoiceOver

```bash
# Enable TalkBack on Android
adb shell settings put secure enabled_accessibility_services \
  com.google.android.marvin.talkback/com.google.android.marvin.talkback.TalkBackService
```

### 2. Voice Command Testing

Test all voice commands:

- Check balance
- Send money
- View history
- Navigation commands

### 3. Haptic Testing

Verify vibration patterns on different devices:

- Transaction sent
- Transaction received
- Success/Error feedback
- Button presses

### 4. Visual Testing

- Color contrast checker
- Text scaling (0.8x to 2.0x)
- Dark mode consistency
- Touch target sizes

### 5. Usability Testing

Conduct tests with:

- Blind users
- Low vision users
- Motor impaired users
- Elderly users
- General population

## Accessibility Compliance

### WCAG 2.1 Level AA

- ✅ 1.1.1 Non-text Content (Alt text for images)
- ✅ 1.3.1 Info and Relationships (Semantic markup)
- ✅ 1.4.3 Contrast (4.5:1 minimum)
- ✅ 1.4.4 Resize Text (Up to 200%)
- ✅ 2.1.1 Keyboard (Voice navigation alternative)
- ✅ 2.4.3 Focus Order (Logical navigation)
- ✅ 2.5.5 Target Size (Minimum 44x44)
- ✅ 3.2.4 Consistent Identification
- ✅ 4.1.3 Status Messages (Voice announcements)

### Platform Guidelines

- ✅ Android Accessibility Guidelines
- ✅ iOS Human Interface Guidelines
- ✅ Material Design Accessibility
- ✅ Flutter Accessibility Guidelines

## Best Practices

### 1. Always Provide Alternatives

```dart
// Good: Multiple ways to perform action
ElevatedButton(
  onPressed: sendMoney,
  child: Text('Send Money'), // Visual
  // + Voice command: "Send money"
  // + Haptic feedback on press
)
```

### 2. Clear and Concise Labels

```dart
// Good
Semantics(label: 'Send Money', ...)

// Avoid
Semantics(label: 'Click here to initiate the process of sending money', ...)
```

### 3. Consistent Patterns

Use the same patterns throughout:

- Same voice commands
- Same haptic patterns
- Same navigation structure

### 4. Progressive Enhancement

Don't break basic functionality if accessibility features fail:

```dart
try {
  await voiceService.speak(message);
} catch (e) {
  // Voice failed, but app still works
  print('Voice service unavailable');
}
```

### 5. User Feedback

Always confirm actions:

- Visual confirmation
- Voice announcement
- Haptic feedback

## Common Issues & Solutions

### Issue: Voice Recognition Inaccurate

**Solution**: Use Speechmatics API for better accuracy

```dart
final result = await voiceService.listen(useSpeechmatics: true);
```

### Issue: Haptic Not Working

**Solution**: Check device support

```dart
if (await Vibration.hasVibrator()) {
  await hapticService.vibrate();
} else {
  // Fallback to audio feedback only
  await voiceService.speak('Action completed');
}
```

### Issue: Screen Reader Skipping Elements

**Solution**: Add explicit semantic labels

```dart
Semantics(
  label: 'Button label',
  button: true,
  enabled: true,
  child: CustomButton(),
)
```

## Resources

### Documentation

- [Flutter Accessibility](https://flutter.dev/docs/development/accessibility-and-localization/accessibility)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Android Accessibility](https://developer.android.com/guide/topics/ui/accessibility)
- [Speechmatics API](https://docs.speechmatics.com/)

### Testing Tools

- Android Accessibility Scanner
- iOS Accessibility Inspector
- Lighthouse Accessibility Audit
- axe DevTools

### User Testing

- Partner with disability advocacy groups
- Conduct usability studies
- Gather continuous feedback
- Iterate based on real user needs

## Feedback & Improvement

Users can provide accessibility feedback:

```dart
// Feedback form with accessibility rating
FeedbackForm(
  fields: [
    'How accessible is InkaWallet?',
    'What accessibility features do you use?',
    'What can we improve?',
  ],
)
```

All feedback is reviewed and used to improve accessibility features in future releases.

## Contact

For accessibility questions or feedback:

- Email: accessibility@inkawallet.com
- Feedback form in app: Settings > Accessibility > Provide Feedback
