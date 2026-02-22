import 'package:flutter/material.dart';
import '../services/voice_command_service.dart';

/// Floating button to toggle conversation mode
/// 
/// Usage:
/// ```dart
/// Scaffold(
///   floatingActionButton: VoiceConversationButton(
///     onNavigate: (intent, data) {
///       // Handle navigation based on voice commands
///       switch (intent) {
///         case 'scan_qr':
///           Navigator.pushNamed(context, '/scan-qr');
///           break;
///         case 'check_credit':
///           Navigator.pushNamed(context, '/credit-score');
///           break;
///         // ... etc
///       }
///     },
///   ),
/// );
/// ```
class VoiceConversationButton extends StatefulWidget {
  final Function(String intent, Map<String, dynamic>? data)? onNavigate;
  
  const VoiceConversationButton({
    Key? key,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<VoiceConversationButton> createState() => _VoiceConversationButtonState();
}

class _VoiceConversationButtonState extends State<VoiceConversationButton>
    with SingleTickerProviderStateMixin {
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _isActive = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    // Setup navigation callback
    _voiceService.onCommandExecuted = widget.onNavigate;
    
    // Pulse animation for active state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleConversationMode() async {
    if (_isActive) {
      await _voiceService.stopConversationMode();
      _pulseController.stop();
      setState(() => _isActive = false);
    } else {
      await _voiceService.startConversationMode();
      _pulseController.repeat(reverse: true);
      setState(() => _isActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _toggleConversationMode,
      backgroundColor: _isActive ? Colors.red : Colors.blue,
      icon: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Icon(
            _isActive ? Icons.mic : Icons.mic_none,
            size: _isActive ? 24 + (_pulseController.value * 6) : 24,
          );
        },
      ),
      label: Text(
        _isActive ? 'Listening...' : 'Voice Control',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
