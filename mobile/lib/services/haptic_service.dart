import 'package:vibration/vibration.dart';
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
    _hasVibrator = await Vibration.hasVibrator() ?? false;
  }

  /// Enable or disable haptic feedback
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Short tap feedback
  Future<void> lightTap() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        duration: AppConstants.hapticShortDuration,
      );
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Medium tap feedback
  Future<void> mediumTap() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        duration: AppConstants.hapticMediumDuration,
      );
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Heavy tap feedback
  Future<void> heavyTap() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        duration: AppConstants.hapticLongDuration,
      );
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Success pattern (short-short-long)
  Future<void> success() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        pattern: [0, 50, 100, 50, 100, 200],
      );
      await _playSound('success');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Error pattern (long-long)
  Future<void> error() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        pattern: [0, 200, 100, 200],
      );
      await _playSound('error');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Warning pattern (medium-short-medium)
  Future<void> warning() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        pattern: [0, 100, 50, 50, 50, 100],
      );
      await _playSound('warning');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Transaction sent pattern
  Future<void> transactionSent() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        pattern: [0, 100, 50, 100, 50, 100],
      );
      await _playSound('send');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Transaction received pattern
  Future<void> transactionReceived() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        pattern: [0, 50, 50, 50, 50, 50],
      );
      await _playSound('receive');
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Button press feedback
  Future<void> buttonPress() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        duration: AppConstants.hapticShortDuration,
      );
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Navigation feedback
  Future<void> navigation() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        duration: AppConstants.hapticMediumDuration,
      );
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  /// Input feedback
  Future<void> input() async {
    if (!_isEnabled || !_hasVibrator) return;
    
    try {
      await Vibration.vibrate(
        duration: 30,
      );
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

  /// Cancel all vibrations
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      print('Haptic cancel error: $e');
    }
  }

  bool get isEnabled => _isEnabled;
  bool get hasVibrator => _hasVibrator;

  /// Dispose resources
  Future<void> dispose() async {
    await cancel();
    await _audioPlayer.dispose();
  }
}
