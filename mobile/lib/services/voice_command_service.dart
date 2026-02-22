import 'dart:async';
import 'package:vibration/vibration.dart';
import 'accessibility_service.dart';
import 'speechmatics_service.dart';

/// Comprehensive voice command service for hands-free conversation
/// 
/// Supports two modes:
/// 1. Basic mode: Uses device speech_to_text (button-triggered)
/// 2. Conversation mode: Uses Speechmatics real-time streaming (Siri-like)
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final AccessibilityService _accessibility = AccessibilityService();
  final SpeechmaticsService _speechmatics = SpeechmaticsService();
  
  bool _isActive = false;
  bool _isListening = false;
  bool _isConversationMode = false;
  
  bool get isActive => _isActive;
  bool get isListening => _isListening;
  bool get isConversationMode => _isConversationMode;
  
  // Voice command state
  Map<String, dynamic>? _currentContext;
  List<String> _commandHistory = [];
  
  // Conversation state for multi-turn interactions
  String? _pendingAction;
  Map<String, dynamic> _conversationData = {};
  StreamSubscription? _segmentSubscription;
  
  /// Initialize voice command service
  Future<void> initialize() async {
    await _accessibility.initialize();
    await _speechmatics.initialize();
  }
  
  /// Start continuous conversation mode (Siri-like hands-free)
  /// 
  /// This mode:
  /// - Connects to Speechmatics WebSocket for real-time transcription
  /// - Listens continuously with automatic turn detection
  /// - Executes commands and provides voice feedback
  /// - Handles multi-turn conversations (asks for missing info, confirms actions)
  Future<void> startConversationMode() async {
    if (_isConversationMode) {
      print('Already in conversation mode');
      return;
    }
    
    try {
      // Connect to Speechmatics real-time API
      final connected = await _speechmatics.connect(
        language: 'en',
        preset: 'adaptive', // Best for conversational AI
        enableDiarization: true,
        enablePartials: true,
        maxDelay: 0.7, // Low latency
      );
      
      if (!connected) {
        await _accessibility.speak('Failed to start conversation mode. Check your internet connection.');
        await vibrateError();
        return;
      }
      
      _isConversationMode = true;
      _isActive = true;
      
      // Listen to finalized speech segments
      _segmentSubscription = _speechmatics.segments.listen((segment) {
        if (segment['is_final'] == true) {
          _handleConversationSegment(segment);
        }
      });
      
      // Start microphone streaming
      await _accessibility.speak('Conversation mode activated. I\'m listening continuously. Say help for commands.');
      await vibrateSuccess();
      
      // Start streaming audio to Speechmatics
      _startAudioStreaming();
      
    } catch (e) {
      print('Error starting conversation mode: $e');
      await _accessibility.speak('Error starting conversation mode: ${e.toString()}');
      await vibrateError();
    }
  }
  
  /// Stop continuous conversation mode
  Future<void> stopConversationMode() async {
    if (!_isConversationMode) {
      return;
    }
    
    _isConversationMode = false;
    _isActive = false;
    _isListening = false;
    
    await _segmentSubscription?.cancel();
    _segmentSubscription = null;
    
    await _speechmatics.disconnect();
    await _accessibility.speak('Conversation mode deactivated.');
    await vibrateDouble();
    
    _pendingAction = null;
    _conversationData.clear();
  }
  
  /// Start streaming audio from microphone to Speechmatics
  /// NOTE: This is a placeholder - actual implementation needs to capture
  /// microphone audio and stream it via _speechmatics.sendAudio()
  Future<void> _startAudioStreaming() async {
    // TODO: Integrate with audio recording plugin
    // 1. Start microphone recording (16-bit PCM, 16kHz, mono)
    // 2. Capture audio chunks (160-320 samples = 10-20ms)
    // 3. Send to Speechmatics: await _speechmatics.sendAudio(audioBytes);
    // 4. Continue until conversation mode stopped
    
    print('Audio streaming not yet implemented - needs microphone capture integration');
  }
  
  /// Handle incoming speech segment from conversation
  Future<void> _handleConversationSegment(Map<String, dynamic> segment) async {
    final text = segment['text'] as String? ?? '';
    if (text.trim().isEmpty) return;
    
    print('User said: $text');
    _commandHistory.add(text);
    
    // Extract intent from speech
    final intent = _speechmatics.extractIntent(text);
    final intentType = intent['intent'] as String;
    final confidence = intent['confidence'] as double;
    
    if (confidence < 0.5) {
      await _accessibility.speak('I didn\'t quite catch that. Could you repeat?');
      await vibrateError();
      return;
    }
    
    // Process the command in conversation context
    await _processConversationalCommand(intentType, text, intent);
  }
  
  /// Process command in conversational context with multi-turn support
  Future<void> _processConversationalCommand(
    String intentType,
    String transcript,
    Map<String, dynamic> intent,
  ) async {
    // Handle confirmation/cancellation of pending actions
    if (_pendingAction != null) {
      if (transcript.toLowerCase().contains('confirm') || 
          transcript.toLowerCase().contains('yes')) {
        await _executePendingAction();
        return;
      } else if (transcript.toLowerCase().contains('cancel') || 
                 transcript.toLowerCase().contains('no')) {
        await _accessibility.speak('Action cancelled.');
        await vibrateDouble();
        _pendingAction = null;
        _conversationData.clear();
        return;
      }
    }
    
    // Route to specific handlers based on intent
    switch (intentType) {
      case 'send_money':
        await _handleSendMoneyConversation(transcript);
        break;
        
      case 'request_money':
        await _handleRequestMoneyConversation(transcript);
        break;
        
      case 'check_balance':
        await _handleCheckBalance();
        break;
        
      case 'buy_airtime':
        await _handleBuyAirtimeConversation(transcript);
        break;
        
      case 'pay_bills':
        await _handlePayBillsConversation(transcript);
        break;
        
      case 'scan_qr':
        await _handleScanQR();
        break;
        
      case 'check_credit':
        await _handleCheckCredit();
        break;
        
      case 'bnpl':
        await _handleBNPL();
        break;
        
      case 'help':
        await provideHelp();
        break;
        
      case 'go_back':
        await _accessibility.speak('Going back.');
        await vibrateNavigation();
        // Navigation will be handled by listening screens
        break;
        
      default:
        await _accessibility.speak('I\'m not sure how to help with that. Say help for available commands.');
        await vibrateError();
    }
  }
  
  /// Handle send money conversation with smart data extraction
  Future<void> _handleSendMoneyConversation(String transcript) async {
    final amount = _speechmatics.extractAmount(transcript);
    final recipient = _speechmatics.extractRecipient(transcript);
    
    // Store extracted data
    if (amount != null) _conversationData['amount'] = amount;
    if (recipient != null) _conversationData['recipient'] = recipient;
    
    // Check what's missing and ask for it
    if (_conversationData['amount'] == null) {
      await _accessibility.speak('How much would you like to send?');
      await vibrateShort();
      _pendingAction = 'send_money_need_amount';
      return;
    }
    
    if (_conversationData['recipient'] == null) {
      await _accessibility.speak('Who would you like to send ${_conversationData['amount']} kwacha to?');
      await vibrateShort();
      _pendingAction = 'send_money_need_recipient';
      return;
    }
    
    // Have all info - ask for confirmation
    await _accessibility.speak(
      'Sending ${_conversationData['amount']} kwacha to ${_conversationData['recipient']}. Say confirm to proceed or cancel to abort.'
    );
    await vibrateConfirmation();
    _pendingAction = 'send_money_confirm';
  }
  
  /// Execute the pending action after confirmation
  Future<void> _executePendingAction() async {
    if (_pendingAction == null) return;
    
    switch (_pendingAction) {
      case 'send_money_confirm':
        // TODO: Actually execute the transaction via API
        await _accessibility.speak(
          'Transaction confirmed. Sending ${_conversationData['amount']} kwacha to ${_conversationData['recipient']}.'
        );
        await vibrateSuccess();
        // Here you would call: await TransactionService().sendMoney(...)
        break;
        
      case 'request_money_confirm':
        await _accessibility.speak(
          'Money request sent to ${_conversationData['payer']} for ${_conversationData['amount']} kwacha.'
        );
        await vibrateSuccess();
        break;
        
      case 'buy_airtime_confirm':
        await _accessibility.speak(
          'Purchasing ${_conversationData['amount']} kwacha airtime for ${_conversationData['phone']}.'
        );
        await vibrateSuccess();
        break;
        
      case 'pay_bill_confirm':
        await _accessibility.speak(
          'Paying ${_conversationData['amount']} kwacha to ${_conversationData['biller']}.'
        );
        await vibrateSuccess();
        break;
    }
    
    _pendingAction = null;
    _conversationData.clear();
  }
  
  /// Handle request money conversation
  Future<void> _handleRequestMoneyConversation(String transcript) async {
    final amount = _speechmatics.extractAmount(transcript);
    final payer = _speechmatics.extractRecipient(transcript);
    
    if (amount != null) _conversationData['amount'] = amount;
    if (payer != null) _conversationData['payer'] = payer;
    
    if (_conversationData['amount'] == null) {
      await _accessibility.speak('How much would you like to request?');
      await vibrateShort();
      return;
    }
    
    if (_conversationData['payer'] == null) {
      await _accessibility.speak('Who would you like to request ${_conversationData['amount']} kwacha from?');
      await vibrateShort();
      return;
    }
    
    await _accessibility.speak(
      'Requesting ${_conversationData['amount']} kwacha from ${_conversationData['payer']}. Say confirm to proceed.'
    );
    await vibrateConfirmation();
    _pendingAction = 'request_money_confirm';
  }
  
  /// Handle buy airtime conversation
  Future<void> _handleBuyAirtimeConversation(String transcript) async {
    final amount = _speechmatics.extractAmount(transcript);
    final phone = _speechmatics.extractRecipient(transcript);
    
    if (amount != null) _conversationData['amount'] = amount;
    if (phone != null) _conversationData['phone'] = phone;
    
    if (_conversationData['amount'] == null) {
      await _accessibility.speak('How much airtime would you like to buy?');
      await vibrateShort();
      return;
    }
    
    if (_conversationData['phone'] == null) {
      await _accessibility.speak('What phone number?');
      await vibrateShort();
      return;
    }
    
    await _accessibility.speak(
      'Buying ${_conversationData['amount']} kwacha airtime for ${_conversationData['phone']}. Say confirm.'
    );
    await vibrateConfirmation();
    _pendingAction = 'buy_airtime_confirm';
  }
  
  /// Handle pay bills conversation
  Future<void> _handlePayBillsConversation(String transcript) async {
    final amount = _speechmatics.extractAmount(transcript);
    // TODO: Extract biller name from transcript
    
    if (amount != null) _conversationData['amount'] = amount;
    
    if (_conversationData['biller'] == null) {
      await _accessibility.speak('Which bill would you like to pay? For example, electricity, water, or internet.');
      await vibrateShort();
      return;
    }
    
    if (_conversationData['amount'] == null) {
      await _accessibility.speak('How much would you like to pay?');
      await vibrateShort();
      return;
    }
    
    await _accessibility.speak(
      'Paying ${_conversationData['amount']} kwacha for ${_conversationData['biller']}. Say confirm.'
    );
    await vibrateConfirmation();
    _pendingAction = 'pay_bill_confirm';
  }
  
  /// Handle check balance
  Future<void> _handleCheckBalance() async {
    // TODO: Fetch actual balance from API
    await _accessibility.speak('Your current balance is 25,000 kwacha.');
    await vibrateSuccess();
  }
  
  /// Handle scan QR
  Future<void> _handleScanQR() async {
    await _accessibility.speak('Opening QR scanner.');
    await vibrateNavigation();
    // Screen will handle navigation
  }
  
  /// Handle check credit score
  Future<void> _handleCheckCredit() async {
    await _accessibility.speak('Opening credit score.');
    await vibrateNavigation();
  }
  
  /// Handle BNPL
  Future<void> _handleBNPL() async {
    await _accessibility.speak('Opening buy now pay later options.');
    await vibrateNavigation();
  }
  
  /// Activate basic voice command mode (button-triggered)
  Future<void> activate() async {
    if (_isConversationMode) {
      print('Already in conversation mode');
      return;
    }
    
    _isActive = true;
    await _accessibility.speak('Voice command mode activated. Say help for available commands.');
    await vibrateSuccess();
  }
  
  /// Deactivate basic voice command mode
  Future<void> deactivate() async {
    if (_isConversationMode) {
      await stopConversationMode();
      return;
    }
    
    _isActive = false;
    _isListening = false;
    await _accessibility.speak('Voice command mode deactivated.');
    await vibrateDouble();
  }
  
  /// Start listening for voice command (basic mode - single command)
  Future<Map<String, dynamic>?> listenForCommand({
    Map<String, dynamic>? context,
    int timeoutSeconds = 5,
  }) async {
    if (_isConversationMode) {
      print('Cannot use listenForCommand in conversation mode. Commands are handled automatically.');
      return null;
    }
    
    if (!_isActive) {
      await activate();
    }
    
    _currentContext = context;
    _isListening = true;
    
    await vibrateShort();
    await _accessibility.speak('Listening...');
    
    try {
      final transcript = await _accessibility.listen();
      
      if (transcript != null && transcript.isNotEmpty) {
        _commandHistory.add(transcript);
        final intent = _speechmatics.extractIntent(transcript);
        
        await vibrateSuccess();
        return await _processCommand(intent);
      } else {
        await _accessibility.speak('No command detected. Please try again.');
        await vibrateError();
        return null;
      }
    } catch (e) {
      await _accessibility.speak('Error processing command: ${e.toString()}');
      await vibrateError();
      return null;
    } finally {
      _isListening = false;
    }
  }
  
  /// Process voice command based on intent
  Future<Map<String, dynamic>?> _processCommand(Map<String, dynamic> intent) async {
    final intentType = intent['intent'] as String;
    final confidence = intent['confidence'] as double;
    final transcript = intent['transcript'] as String;
    
    if (confidence < 0.6) {
      await _accessibility.speak('I\'m not sure I understood that. Please repeat your command.');
      return null;
    }
    
    await _accessibility.speak('Processing: $intentType');
    
    return {
      'intent': intentType,
      'confidence': confidence,
      'transcript': transcript,
      'context': _currentContext,
    };
  }
  
  /// Handle send money command
  Future<Map<String, dynamic>?> handleSendMoneyCommand(String transcript) async {
    final amount = _speechmatics.extractAmount(transcript);
    final recipient = _speechmatics.extractRecipient(transcript);
    
    if (amount == null) {
      await _accessibility.speak('How much would you like to send?');
      final amountResponse = await _accessibility.listen();
      if (amountResponse != null) {
        final extractedAmount = _speechmatics.extractAmount(amountResponse);
        if (extractedAmount != null) {
          return await _handleSendMoneyWithDetails(extractedAmount, recipient);
        }
      }
      await _accessibility.speak('Amount not recognized. Please try again.');
      return null;
    }
    
    return await _handleSendMoneyWithDetails(amount, recipient);
  }
  
  Future<Map<String, dynamic>?> _handleSendMoneyWithDetails(double amount, String? recipient) async {
    if (recipient == null) {
      await _accessibility.speak('Who would you like to send $amount kwacha to?');
      final recipientResponse = await _accessibility.listen();
      if (recipientResponse != null) {
        final extractedRecipient = _speechmatics.extractRecipient(recipientResponse);
        if (extractedRecipient != null) {
          return {
            'action': 'send_money',
            'amount': amount,
            'recipient': extractedRecipient,
          };
        }
      }
      await _accessibility.speak('Recipient not recognized. Please try again.');
      return null;
    }
    
    await _accessibility.speak('Sending $amount kwacha to $recipient. Say confirm to proceed or cancel to abort.');
    return {
      'action': 'send_money_confirm',
      'amount': amount,
      'recipient': recipient,
    };
  }
  
  /// Handle login command
  Future<Map<String, dynamic>?> handleLoginCommand() async {
    await _accessibility.speak('Please say your email address');
    final emailResponse = await _accessibility.listen();
    
    if (emailResponse == null || emailResponse.isEmpty) {
      await _accessibility.speak('Email not recognized. Please try again.');
      return null;
    }
    
    // Convert speech to email format
    final email = _convertSpeechToEmail(emailResponse);
    
    await _accessibility.speak('Please say your password');
    final passwordResponse = await _accessibility.listen();
    
    if (passwordResponse == null || passwordResponse.isEmpty) {
      await _accessibility.speak('Password not recognized. Please try again.');
      return null;
    }
    
    return {
      'action': 'login',
      'email': email,
      'password': passwordResponse.toLowerCase().replaceAll(' ', ''),
    };
  }
  
  /// Convert speech to email (e.g., "john at example dot com" -> "john@example.com")
  String _convertSpeechToEmail(String speech) {
    return speech
        .toLowerCase()
        .replaceAll(' at ', '@')
        .replaceAll(' dot ', '.')
        .replaceAll(' ', '');
  }
  
  /// Handle registration command
  Future<Map<String, dynamic>?> handleRegisterCommand() async {
    await _accessibility.speak('Let\'s create your account. Please say your full name');
    final nameResponse = await _accessibility.listen();
    
    if (nameResponse == null || nameResponse.isEmpty) {
      await _accessibility.speak('Name not recognized. Please try again.');
      return null;
    }
    
    await _accessibility.speak('Please say your email address');
    final emailResponse = await _accessibility.listen();
    
    if (emailResponse == null || emailResponse.isEmpty) {
      await _accessibility.speak('Email not recognized. Please try again.');
      return null;
    }
    
    await _accessibility.speak('Please say your phone number');
    final phoneResponse = await _accessibility.listen();
    
    if (phoneResponse == null || phoneResponse.isEmpty) {
      await _accessibility.speak('Phone number not recognized. Please try again.');
      return null;
    }
    
    await _accessibility.speak('Please create a password');
    final passwordResponse = await _accessibility.listen();
    
    if (passwordResponse == null || passwordResponse.isEmpty) {
      await _accessibility.speak('Password not recognized. Please try again.');
      return null;
    }
    
    return {
      'action': 'register',
      'name': nameResponse.trim(),
      'email': _convertSpeechToEmail(emailResponse),
      'phone': phoneResponse.replaceAll(RegExp(r'[^\d+]'), ''),
      'password': passwordResponse.toLowerCase().replaceAll(' ', ''),
    };
  }
  
  /// Get help information
  Future<void> provideHelp({String? screen}) async {
    final commands = _getAvailableCommands(screen);
    
    await _accessibility.speak('Available commands:');
    await Future.delayed(const Duration(milliseconds: 500));
    
    for (var i = 0; i < commands.length; i++) {
      await _accessibility.speak('${i + 1}. ${commands[i]}');
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }
  
  List<String> _getAvailableCommands(String? screen) {
    final commonCommands = [
      'Help - Get list of commands',
      'Go back - Return to previous screen',
      'Settings - Open settings',
      'Balance - Check your balance',
    ];
    
    final screenCommands = {
      'home': [
        'Send money - Send money to someone',
        'Request money - Request money from someone',
        'Scan QR - Scan QR code to pay',
        'My QR - Show your QR code',
        'Buy airtime - Purchase mobile airtime',
        'Pay bills - Pay utility bills',
        'Credit score - Check your credit score',
        'BNPL - Buy now pay later options',
      ],
      'login': [
        'Login - Log in to your account',
        'Register - Create new account',
      ],
      'send_money': [
        'Send amount to number - e.g., Send 100 to 0888123456',
        'Confirm - Confirm transaction',
        'Cancel - Cancel transaction',
      ],
    };
    
    final commands = [...commonCommands];
    if (screen != null && screenCommands.containsKey(screen)) {
      commands.addAll(screenCommands[screen]!);
    }
    
    return commands;
  }
  
  /// Vibration patterns
  Future<void> vibrateShort() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(duration: 50);
    }
  }
  
  Future<void> vibrateDouble() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(pattern: [0, 100, 100, 100]);
    }
  }
  
  Future<void> vibrateSuccess() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(pattern: [0, 50, 50, 50, 50, 50]);
    }
  }
  
  Future<void> vibrateError() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }
  }
  
  Future<void> vibrateNavigation() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(duration: 30);
    }
  }
  
  Future<void> vibrateAction() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(duration: 100);
    }
  }
  
  Future<void> vibrateConfirmation() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 100]);
    }
  }
  
  /// Get command history
  List<String> getCommandHistory() => _commandHistory;
  
  /// Clear command history
  void clearHistory() => _commandHistory.clear();
}
