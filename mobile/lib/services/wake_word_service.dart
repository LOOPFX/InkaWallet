import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';
import 'accessibility_service.dart';

/// Wake word detection service for hands-free activation
/// 
/// Continuously listens for the wake word "Inka" to activate voice commands
/// This makes the app truly hands-free for blind users
class WakeWordService {
  static final WakeWordService _instance = WakeWordService._internal();
  factory WakeWordService() => _instance;
  WakeWordService._internal();

  final SpeechToText _stt = SpeechToText();
  final AccessibilityService _accessibility = AccessibilityService();
  
  bool _isListeningForWakeWord = false;
  bool _isProcessingCommand = false;
  Timer? _restartTimer;
  
  // Wake word configuration
  static const String wakeWord = 'inka';
  static const List<String> wakeWordVariants = [
    'inka',
    'inca',
    'inka wallet',
    'hey inka',
    'ok inka',
  ];
  
  // Callback when wake word is detected
  Function(String command)? onWakeWordDetected;
  
  bool get isActive => _isListeningForWakeWord;
  
  /// Initialize the wake word service
  Future<bool> initialize() async {
    try {
      final available = await _stt.initialize(
        onError: (error) {
          debugPrint('Wake word error: $error');
          _scheduleRestart();
        },
        onStatus: (status) {
          debugPrint('Wake word status: $status');
          if (status == 'notListening' && _isListeningForWakeWord && !_isProcessingCommand) {
            _scheduleRestart();
          }
        },
      );
      
      if (!available) {
        debugPrint('Speech recognition not available');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error initializing wake word service: $e');
      return false;
    }
  }
  
  /// Start listening for wake word continuously
  Future<void> startListening() async {
    if (_isListeningForWakeWord) {
      debugPrint('Already listening for wake word');
      return;
    }
    
    if (!_stt.isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        debugPrint('Failed to initialize wake word detection');
        return;
      }
    }
    
    _isListeningForWakeWord = true;
    await _startListeningSession();
    
    debugPrint('👂 Wake word detection started - Say "Inka" to activate');
    await _accessibility.speak('Voice control ready. Say Inka to give commands.');
    await _vibrate();
  }
  
  /// Stop listening for wake word
  Future<void> stopListening() async {
    _isListeningForWakeWord = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    
    if (_stt.isListening) {
      await _stt.stop();
    }
    
    debugPrint('🛑 Wake word detection stopped');
  }
  
  /// Start a listening session
  Future<void> _startListeningSession() async {
    if (!_isListeningForWakeWord || _isProcessingCommand) {
      return;
    }
    
    try {
      await _stt.listen(
        onResult: _handleSpeechResult,
        listenFor: const Duration(seconds: 30), // Listen for 30 seconds
        pauseFor: const Duration(seconds: 5),   // Pause detection after 5s of silence
        partialResults: true,
        listenMode: ListenMode.confirmation,
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error starting listening session: $e');
      _scheduleRestart();
    }
  }
  
  /// Handle speech recognition result
  void _handleSpeechResult(result) {
    if (!_isListeningForWakeWord || _isProcessingCommand) {
      return;
    }
    
    final text = result.recognizedWords.toLowerCase().trim();
    
    if (text.isEmpty) {
      return;
    }
    
    debugPrint('Heard: "$text"');
    
    // Check if wake word is detected
    if (_containsWakeWord(text)) {
      _onWakeWordDetected(text);
    }
  }
  
  /// Check if text contains wake word
  bool _containsWakeWord(String text) {
    final lowerText = text.toLowerCase();
    
    // Check for exact wake word or variants
    for (final variant in wakeWordVariants) {
      if (lowerText.contains(variant)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Handle wake word detection
  Future<void> _onWakeWordDetected(String fullText) async {
    debugPrint('✅ Wake word detected: "$fullText"');
    
    _isProcessingCommand = true;
    await _stt.stop();
    
    // Vibrate to confirm wake word detected
    await _vibrateSuccess();
    
    // Extract command after wake word
    String command = _extractCommand(fullText);
    
    if (command.isEmpty) {
      // No command after wake word, listen for command
      await _accessibility.speak('Yes? I\'m listening.');
      command = await _listenForCommand();
    } else {
      // Command was included after wake word
      await _accessibility.speak('Got it.');
    }
    
    // Execute command
    if (command.isNotEmpty && onWakeWordDetected != null) {
      onWakeWordDetected!(command);
    }
    
    // Resume listening for wake word
    _isProcessingCommand = false;
    
    // Restart listening after a short delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (_isListeningForWakeWord) {
      await _startListeningSession();
    }
  }
  
  /// Extract command from text after wake word
  String _extractCommand(String text) {
    final lowerText = text.toLowerCase();
    
    for (final variant in wakeWordVariants) {
      if (lowerText.contains(variant)) {
        // Get text after wake word
        final index = lowerText.indexOf(variant);
        final afterWakeWord = text.substring(index + variant.length).trim();
        
        // Remove common connecting words
        final command = afterWakeWord
            .replaceFirst(RegExp(r'^(please|could you|can you|i want to|i need to)\s+', caseSensitive: false), '')
            .trim();
        
        return command;
      }
    }
    
    return '';
  }
  
  /// Listen for command after wake word detected
  Future<String> _listenForCommand() async {
    String command = '';
    
    try {
      final completer = Completer<String>();
      
      await _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            command = result.recognizedWords.trim();
            completer.complete(command);
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
        cancelOnError: true,
      );
      
      // Wait for final result or timeout
      command = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => '',
      );
    } catch (e) {
      debugPrint('Error listening for command: $e');
    }
    
    return command;
  }
  
  /// Schedule restart of listening session
  void _scheduleRestart() {
    if (!_isListeningForWakeWord || _isProcessingCommand) {
      return;
    }
    
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 2), () {
      if (_isListeningForWakeWord && !_isProcessingCommand) {
        debugPrint('🔄 Restarting wake word detection...');
        _startListeningSession();
      }
    });
  }
  
  /// Vibrate for feedback
  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 100);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }
  
  /// Vibrate success pattern
  Future<void> _vibrateSuccess() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 50, 50, 50]);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }
}
