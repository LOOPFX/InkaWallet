import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

/// VoiceService handles voice commands and text-to-speech functionality
/// Integrates with Speechmatics API for enhanced voice recognition
class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  // final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;

  VoiceService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5); // Slower for accessibility
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });
      
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        print('TTS Error: $msg');
      });
      
      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize TTS: $e');
    }
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_isInitialized) {
      await _initializeTts();
    }
    
    try {
      if (interrupt && _isSpeaking) {
        await stop();
      }
      
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  /// Initialize speech recognition (disabled - speech_to_text removed)
  Future<bool> initializeSpeechRecognition() async {
    // if (!_speech.isAvailable) {
    //   return await _speech.initialize(
    //     onError: (error) {
    //       print('Speech recognition error: $error');
    //       _isListening = false;
    //     },
    //     onStatus: (status) {
    //       print('Speech recognition status: $status');
    //       if (status == 'done' || status == 'notListening') {
    //         _isListening = false;
    //       }
    //     },
    //   );
    // }
    return false; // Speech recognition disabled
  }

  /// Start listening for voice commands
  Future<String?> listen({
    Duration timeout = const Duration(seconds: 30),
    bool useSpeechmatics = false,
  }) async {
    if (!await initializeSpeechRecognition()) {
      return null;
    }

    String? result;
    
    try {
      _isListening = true;
      
      if (useSpeechmatics) {
        // Use Speechmatics API for better accuracy
        result = await _listenWithSpeechmatics(timeout);
      } else {
        // Use built-in speech recognition
        result = await _listenWithBuiltIn(timeout);
      }
    } catch (e) {
      print('Error during listening: $e');
    } finally {
      _isListening = false;
    }

    return result;
  }

  /// Listen using built-in speech recognition (disabled)
  Future<String?> _listenWithBuiltIn(Duration timeout) async {
    // String? recognizedText;
    // 
    // await _speech.listen(
    //   onResult: (result) {
    //     recognizedText = result.recognizedWords;
    //   },
    //   listenFor: timeout,
    //   pauseFor: const Duration(seconds: 3),
    //   partialResults: false,
    // );
    //
    // // Wait for result or timeout
    // int elapsed = 0;
    // while (elapsed < timeout.inSeconds && recognizedText == null && _isListening) {
    //   await Future.delayed(const Duration(milliseconds: 100));
    //   elapsed++;
    // }
    //
    // await _speech.stop();
    // return recognizedText;
    return null; // Speech recognition disabled
  }

  /// Listen using Speechmatics API for better accuracy
  Future<String?> _listenWithSpeechmatics(Duration timeout) async {
    // Note: This is a simplified example
    // Full implementation would use Speechmatics WebSocket API
    // For production, implement proper Speechmatics integration
    
    try {
      // First, record audio using the device
      // Then send to Speechmatics API
      // This is a placeholder for the actual implementation
      
      final response = await http.post(
        Uri.parse('https://api.speechmatics.com/v2/jobs'),
        headers: {
          'Authorization': 'Bearer ${AppConstants.speechmaticsApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'type': 'transcription',
          'transcription_config': {
            'language': AppConstants.speechmaticsLanguage,
          },
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['transcript'] as String?;
      }
    } catch (e) {
      print('Speechmatics API error: $e');
      // Fallback to built-in recognition
      return _listenWithBuiltIn(timeout);
    }

    return null;
  }

  /// Process voice command and return action
  String? processVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase().trim();
    
    // Check balance
    if (lowerCommand.contains('balance') || 
        lowerCommand.contains('check balance') ||
        lowerCommand.contains('my balance')) {
      return 'check_balance';
    }
    
    // Send money
    if (lowerCommand.contains('send money') || 
        lowerCommand.contains('transfer') ||
        lowerCommand.contains('send')) {
      return 'send_money';
    }
    
    // View transactions
    if (lowerCommand.contains('history') || 
        lowerCommand.contains('transactions') ||
        lowerCommand.contains('view transactions')) {
      return 'view_history';
    }
    
    // Navigation
    if (lowerCommand.contains('go back') || lowerCommand.contains('back')) {
      return 'go_back';
    }
    
    if (lowerCommand.contains('go home') || lowerCommand.contains('home')) {
      return 'go_home';
    }
    
    // Help
    if (lowerCommand.contains('help')) {
      return 'help';
    }
    
    // Repeat
    if (lowerCommand.contains('repeat') || lowerCommand.contains('say again')) {
      return 'repeat';
    }

    return null;
  }

  /// Announce screen or action for blind users
  Future<void> announceScreen(String screenName) async {
    await speak('You are now on $screenName screen');
  }

  /// Announce button or action
  Future<void> announceAction(String action) async {
    await speak(action);
  }

  /// Provide voice feedback for transaction
  Future<void> announceTransaction(String type, double amount, String recipient) async {
    final message = '$type of ${AppConstants.currencySymbol} ${amount.toStringAsFixed(2)} '
                   'to $recipient';
    await speak(message);
  }

  /// Provide voice feedback for balance
  Future<void> announceBalance(double balance) async {
    final message = 'Your balance is ${AppConstants.currencySymbol} '
                   '${balance.toStringAsFixed(2)}';
    await speak(message);
  }

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    // if (_speech.isListening) {
    //   await _speech.stop();
    // }
  }
}
