import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'accessibility_service.dart';
import 'speechmatics_service.dart';

/// Comprehensive voice command service for hands-free navigation
class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final AccessibilityService _accessibility = AccessibilityService();
  final SpeechmaticsService _speechmatics = SpeechmaticsService();
  
  bool _isActive = false;
  bool _isListening = false;
  
  bool get isActive => _isActive;
  bool get isListening => _isListening;
  
  // Voice command state
  Map<String, dynamic>? _currentContext;
  List<String> _commandHistory = [];
  
  /// Initialize voice command service
  Future<void> initialize() async {
    await _accessibility.initialize();
    await _speechmatics.initialize();
  }
  
  /// Activate voice command mode
  Future<void> activate() async {
    _isActive = true;
    await _accessibility.speak('Voice command mode activated. Say help for available commands.');
    await _vibrateSuccess();
  }
  
  /// Deactivate voice command mode
  Future<void> deactivate() async {
    _isActive = false;
    _isListening = false;
    await _accessibility.speak('Voice command mode deactivated.');
    await _vibrateDouble();
  }
  
  /// Start listening for voice command
  Future<Map<String, dynamic>?> listenForCommand({
    Map<String, dynamic>? context,
    int timeoutSeconds = 5,
  }) async {
    if (!_isActive) {
      await activate();
    }
    
    _currentContext = context;
    _isListening = true;
    
    await _vibrateShort();
    await _accessibility.speak('Listening...');
    
    try {
      final transcript = await _accessibility.listen();
      
      if (transcript != null && transcript.isNotEmpty) {
        _commandHistory.add(transcript);
        final intent = _speechmatics.extractIntent(transcript);
        
        await _vibrateSuccess();
        return await _processCommand(intent);
      } else {
        await _accessibility.speak('No command detected. Please try again.');
        await _vibrateError();
        return null;
      }
    } catch (e) {
      await _accessibility.speak('Error processing command: ${e.toString()}');
      await _vibrateError();
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
  Future<void> _vibrateShort() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(duration: 50);
    }
  }
  
  Future<void> _vibrateDouble() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(pattern: [0, 100, 100, 100]);
    }
  }
  
  Future<void> _vibrateSuccess() async {
    if (await Vibration.hasVibrator() == true) {
      await Vibration.vibrate(pattern: [0, 50, 50, 50, 50, 50]);
    }
  }
  
  Future<void> _vibrateError() async {
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
