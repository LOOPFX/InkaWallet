import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService {
  static final AccessibilityService _instance = AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  
  bool _accessibilityEnabled = true;
  bool _voiceEnabled = true;
  bool _hapticsEnabled = true;
  bool _isListening = false;
  
  bool get isAccessibilityEnabled => _accessibilityEnabled;
  bool get isVoiceEnabled => _voiceEnabled;
  bool get isHapticsEnabled => _hapticsEnabled;
  bool get isListening => _isListening;
  
  Future<void> initialize() async {
    await _loadSettings();
    await _configureTTS();
    await _initializeSpeech();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _accessibilityEnabled = prefs.getBool('accessibility_enabled') ?? true;
    _voiceEnabled = prefs.getBool('voice_enabled') ?? true;
    _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
  }
  
  Future<void> _configureTTS() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }
  
  Future<void> _initializeSpeech() async {
    await _stt.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
  }
  
  Future<void> speak(String text) async {
    if (_accessibilityEnabled && _voiceEnabled) {
      await _tts.speak(text);
    }
  }
  
  Future<void> stop() async {
    await _tts.stop();
  }
  
  Future<void> vibrate({int duration = 200}) async {
    if (_accessibilityEnabled && _hapticsEnabled) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: duration);
      }
    }
  }
  
  Future<void> vibratePattern() async {
    if (_accessibilityEnabled && _hapticsEnabled) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(pattern: [0, 100, 100, 100]);
      }
    }
  }
  
  Future<String?> listen() async {
    if (!_accessibilityEnabled || !_voiceEnabled) return null;
    
    if (!_stt.isAvailable) {
      await _initializeSpeech();
    }
    
    String? result;
    _isListening = true;
    
    await _stt.listen(
      onResult: (speechResult) {
        result = speechResult.recognizedWords;
        _isListening = false;
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
    );
    
    await Future.delayed(const Duration(seconds: 6));
    return result;
  }
  
  Future<void> stopListening() async {
    await _stt.stop();
    _isListening = false;
  }
  
  Future<void> updateSettings({
    required bool accessibilityEnabled,
    required bool voiceEnabled,
    required bool hapticsEnabled,
  }) async {
    _accessibilityEnabled = accessibilityEnabled;
    _voiceEnabled = voiceEnabled;
    _hapticsEnabled = hapticsEnabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accessibility_enabled', accessibilityEnabled);
    await prefs.setBool('voice_enabled', voiceEnabled);
    await prefs.setBool('haptics_enabled', hapticsEnabled);
  }
  
  Future<void> announceAndVibrate(String message, {bool important = false}) async {
    await speak(message);
    if (important) {
      await vibratePattern();
    } else {
      await vibrate();
    }
  }
}
