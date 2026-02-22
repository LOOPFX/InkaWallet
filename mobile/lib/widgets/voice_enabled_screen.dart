import 'package:flutter/material.dart';
import '../services/voice_command_service.dart';
import '../services/accessibility_service.dart';

/// Widget wrapper that enables voice control for any screen
class VoiceEnabledScreen extends StatefulWidget {
  final Widget child;
  final String screenName;
  final Function(Map<String, dynamic>)? onVoiceCommand;
  final bool enableFloatingMic;
  
  const VoiceEnabledScreen({
    super.key,
    required this.child,
    required this.screenName,
    this.onVoiceCommand,
    this.enableFloatingMic = true,
  });

  @override
  State<VoiceEnabledScreen> createState() => _VoiceEnabledScreenState();
}

class _VoiceEnabledScreenState extends State<VoiceEnabledScreen> with WidgetsBindingObserver {
  final VoiceCommandService _voiceCommand = VoiceCommandService();
  final AccessibilityService _accessibility = AccessibilityService();
  
  bool _isListening = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVoiceControl();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  Future<void> _initVoiceControl() async {
    if (_accessibility.isVoiceControlEnabled) {
      await _voiceCommand.initialize();
    }
  }
  
  Future<void> _startListening() async {
    if (_isListening) return;
    
    setState(() => _isListening = true);
    
    try {
      final command = await _voiceCommand.listenForCommand(
        context: {'screen': widget.screenName},
      );
      
      if (command != null && widget.onVoiceCommand != null) {
        widget.onVoiceCommand!(command);
      } else if (command != null) {
        await _handleDefaultCommand(command);
      }
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }
  
  Future<void> _handleDefaultCommand(Map<String, dynamic> command) async {
    final intent = command['intent'] as String;
    
    switch (intent) {
      case 'go_back':
        if (Navigator.of(context).canPop()) {
          await _voiceCommand.vibrateNavigation();
          Navigator.of(context).pop();
        } else {
          await _accessibility.speak('Already at the main screen');
        }
        break;
        
      case 'help':
        await _voiceCommand.provideHelp(screen: widget.screenName);
        break;
        
      default:
        await _accessibility.speak('Command not supported on this screen');
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Floating voice command button
        if (widget.enableFloatingMic && _accessibility.isVoiceControlEnabled)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _startListening,
              backgroundColor: _isListening 
                  ? Colors.red 
                  : Theme.of(context).colorScheme.primary,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
              ),
            ),
          ),
        
        // Listening overlay
        if (_isListening)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mic,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Listening...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Say a command or "help" for options',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Quick voice command button for toolbars
class VoiceCommandButton extends StatefulWidget {
  final Function(Map<String, dynamic>)? onCommand;
  final String? screenContext;
  
  const VoiceCommandButton({
    super.key,
    this.onCommand,
    this.screenContext,
  });

  @override
  State<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton> {
  final VoiceCommandService _voiceCommand = VoiceCommandService();
  final AccessibilityService _accessibility = AccessibilityService();
  bool _isListening = false;
  
  Future<void> _listen() async {
    if (_isListening) return;
    
    setState(() => _isListening = true);
    
    try {
      final command = await _voiceCommand.listenForCommand(
        context: {'screen': widget.screenContext},
      );
      
      if (command != null && widget.onCommand != null) {
        widget.onCommand!(command);
      }
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_accessibility.isVoiceControlEnabled) {
      return const SizedBox.shrink();
    }
    
    return IconButton(
      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
      color: _isListening ? Colors.red : null,
      tooltip: 'Voice Command',
      onPressed: _listen,
    );
  }
}
