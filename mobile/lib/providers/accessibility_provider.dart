import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/haptic_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// AccessibilityProvider manages inclusive features
/// Controls voice commands, haptic feedback, and accessibility settings
class AccessibilityProvider with ChangeNotifier {
  final VoiceService voiceService;
  final HapticService hapticService;

  bool _isInclusiveModeEnabled = true;
  bool _isVoiceEnabled = true;
  bool _isHapticEnabled = true;
  bool _isDarkMode = false;
  double _textScale = AppConstants.defaultTextScale;
  bool _boldText = false;
  String? _lastSpokenText;

  AccessibilityProvider({
    required this.voiceService,
    required this.hapticService,
  });

  // Getters
  bool get isInclusiveModeEnabled => _isInclusiveModeEnabled;
  bool get isVoiceEnabled => _isVoiceEnabled;
  bool get isHapticEnabled => _isHapticEnabled;
  bool get isDarkMode => _isDarkMode;
  double get textScale => _textScale;
  bool get boldText => _boldText;
  String? get lastSpokenText => _lastSpokenText;

  /// Initialize settings from storage
  Future<void> initialize() async {
    _isInclusiveModeEnabled = StorageService.isInclusiveModeEnabled();
    _isVoiceEnabled = StorageService.getSetting('voice_enabled', defaultValue: true);
    _isHapticEnabled = StorageService.getSetting('haptic_enabled', defaultValue: true);
    _isDarkMode = StorageService.getSetting('dark_mode', defaultValue: false);
    _textScale = StorageService.getSetting('text_scale', defaultValue: AppConstants.defaultTextScale);
    _boldText = StorageService.getSetting('bold_text', defaultValue: false);

    hapticService.setEnabled(_isHapticEnabled);
    notifyListeners();
  }

  /// Toggle inclusive mode
  Future<void> toggleInclusiveMode(bool enabled) async {
    _isInclusiveModeEnabled = enabled;
    await StorageService.setInclusiveMode(enabled);
    
    if (!enabled) {
      // Disable voice and haptic when inclusive mode is off
      _isVoiceEnabled = false;
      _isHapticEnabled = false;
    }
    
    hapticService.setEnabled(_isHapticEnabled);
    notifyListeners();
    
    if (_isVoiceEnabled) {
      await speak(enabled ? 
        'Inclusive mode enabled. Voice commands and haptic feedback are active.' :
        'Inclusive mode disabled.');
    }
  }

  /// Toggle voice commands
  Future<void> toggleVoice(bool enabled) async {
    _isVoiceEnabled = enabled;
    await StorageService.saveSetting('voice_enabled', enabled);
    notifyListeners();
    
    if (enabled) {
      await speak('Voice feedback enabled');
    }
  }

  /// Toggle haptic feedback
  Future<void> toggleHaptic(bool enabled) async {
    _isHapticEnabled = enabled;
    await StorageService.saveSetting('haptic_enabled', enabled);
    hapticService.setEnabled(enabled);
    notifyListeners();
    
    if (_isVoiceEnabled) {
      await speak(enabled ? 'Haptic feedback enabled' : 'Haptic feedback disabled');
    }
    
    if (enabled) {
      await hapticService.mediumTap();
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode(bool enabled) async {
    _isDarkMode = enabled;
    await StorageService.saveSetting('dark_mode', enabled);
    notifyListeners();
    
    if (_isVoiceEnabled) {
      await speak(enabled ? 'Dark mode enabled' : 'Light mode enabled');
    }
  }

  /// Set text scale
  Future<void> setTextScale(double scale) async {
    if (scale < AppConstants.minTextScale || scale > AppConstants.maxTextScale) {
      return;
    }
    
    _textScale = scale;
    await StorageService.saveSetting('text_scale', scale);
    notifyListeners();
  }

  /// Toggle bold text
  Future<void> toggleBoldText(bool enabled) async {
    _boldText = enabled;
    await StorageService.saveSetting('bold_text', enabled);
    notifyListeners();
    
    if (_isVoiceEnabled) {
      await speak(enabled ? 'Bold text enabled' : 'Bold text disabled');
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_isVoiceEnabled) return;
    
    _lastSpokenText = text;
    await voiceService.speak(text, interrupt: interrupt);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await voiceService.stop();
  }

  /// Listen for voice command
  Future<String?> listenForCommand() async {
    if (!_isVoiceEnabled) return null;
    
    await speak('Listening...');
    await hapticService.lightTap();
    
    final command = await voiceService.listen();
    
    if (command != null) {
      await hapticService.mediumTap();
    } else {
      await hapticService.error();
    }
    
    return command;
  }

  /// Process voice command
  String? processCommand(String command) {
    return voiceService.processVoiceCommand(command);
  }

  /// Announce screen
  Future<void> announceScreen(String screenName) async {
    if (!_isVoiceEnabled) return;
    await voiceService.announceScreen(screenName);
    await hapticService.navigation();
  }

  /// Announce action
  Future<void> announceAction(String action) async {
    if (!_isVoiceEnabled) return;
    await voiceService.announceAction(action);
  }

  /// Announce balance
  Future<void> announceBalance(double balance) async {
    if (!_isVoiceEnabled) return;
    await voiceService.announceBalance(balance);
  }

  /// Announce transaction
  Future<void> announceTransaction(String type, double amount, String recipient) async {
    if (!_isVoiceEnabled) return;
    await voiceService.announceTransaction(type, amount, recipient);
  }

  /// Haptic feedback for button press
  Future<void> buttonTap() async {
    if (!_isHapticEnabled) return;
    await hapticService.buttonPress();
  }

  /// Haptic feedback for input
  Future<void> inputFeedback() async {
    if (!_isHapticEnabled) return;
    await hapticService.input();
  }

  /// Haptic feedback for success
  Future<void> successFeedback() async {
    if (!_isHapticEnabled) return;
    await hapticService.success();
  }

  /// Haptic feedback for error
  Future<void> errorFeedback() async {
    if (!_isHapticEnabled) return;
    await hapticService.error();
  }

  /// Haptic feedback for warning
  Future<void> warningFeedback() async {
    if (!_isHapticEnabled) return;
    await hapticService.warning();
  }

  /// Haptic feedback for transaction sent
  Future<void> transactionSentFeedback() async {
    if (!_isHapticEnabled) return;
    await hapticService.transactionSent();
  }

  /// Haptic feedback for transaction received
  Future<void> transactionReceivedFeedback() async {
    if (!_isHapticEnabled) return;
    await hapticService.transactionReceived();
  }

  /// Repeat last spoken text
  Future<void> repeatLast() async {
    if (_lastSpokenText != null) {
      await speak(_lastSpokenText!);
    }
  }

  @override
  void dispose() {
    voiceService.dispose();
    hapticService.dispose();
    super.dispose();
  }
}
