// import 'package:vibration/vibration.dart'; // Removed due to v1 embedding issues
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/constants.dart';

/// HapticService provides tactile feedback for accessibility
/// Different vibration patterns for different actions
class HapticService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isEnabled = true;
  bool _hasVibrator = false;

  HapticService() {
    _checkVibrationSupport();
  }

  Future<void> _checkVibrationSupport() async {
    // _hasVibrator = await Vibration.hasVibrator() ?? false;
    _hasVibrator = false; // Vibration disabled
  }

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Short tap feedback
  Future<void> lightTap() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Medium tap feedback
  Future<void> mediumTap() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Heavy tap feedback
  Future<void> heavyTap() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Success pattern (short-short-long)
  Future<void> success() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
      await _playSound('success');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Error pattern (long-long)
  Future<void> error() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.heavyImpact();
      await _playSound('error');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Warning pattern (medium-short-medium)
  Future<void> warning() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.mediumImpact();
      await _playSound('warning');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Transaction sent pattern
  Future<void> transactionSent() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
      await _playSound('send');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Transaction received pattern
  Future<void> transactionReceived() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
      await _playSound('receive');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Button press feedback
  Future<void> buttonPress() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Navigation feedback
  Future<void> navigation() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Input feedback
  Future<void> input() async {
    if (!_isEnabled) return;
    
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Play sound feedback
  Future<void> _playSound(String soundName) async {
    if (!_isEnabled) return;
    
    try {
      // Sounds should be placed in assets/sounds/
      await _audioPlayer.play(
        AssetSource('sounds/$soundName.mp3'),
        volume: 0.5,
      );
    } catch (e) {
      print('Audio playback error: $e');
    }
  }

  /// Cancel all vibrations (no-op for HapticFeedback)
  Future<void> cancel() async {
    // HapticFeedback doesn't need explicit cancellation
  }

  bool get isEnabled => _isEnabled;
  bool get hasVibrator => _hasVibrator;

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
