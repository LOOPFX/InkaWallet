import 'package:flutter/material.dart';
import '../services/voice_command_service.dart';
import '../services/accessibility_service.dart';
import '../services/wake_word_service.dart';

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
  final WakeWordService _wakeWord = WakeWordService();
  
  bool _isListening = false;
  bool _wakeWordActive = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVoiceControl();
  }
  
  @override
  void dispose() {
    _wakeWord.stopListening();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  Future<void> _initVoiceControl() async {
    if (_accessibility.isVoiceControlEnabled) {
      await _voiceCommand.initialize();
      
      // Initialize and start wake word detection
      final initialized = await _wakeWord.initialize();
      if (initialized) {
        _wakeWord.onWakeWordDetected = _handleWakeWordCommand;
        await _wakeWord.startListening();
        setState(() => _wakeWordActive = true);
      }
    }
  }
  
  Future<void> _handleWakeWordCommand(String command) async {
    debugPrint('Processing wake word command: $command');
    
    final commandMap = {
      'command': command,
      'intent': _extractIntent(command),
      'screen': widget.screenName,
    };
    
    if (widget.onVoiceCommand != null) {
      widget.onVoiceCommand!(commandMap);
    } else {
      await _handleDefaultCommand(commandMap);
    }
  }
  
  String _extractIntent(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Check balance
    if (lowerCommand.contains('balance') || lowerCommand.contains('how much')) {
      return 'check_balance';
    }
    
    // Send money
    if (lowerCommand.contains('send') || lowerCommand.contains('transfer')) {
      return 'send_money';
    }
    
    // Request money
    if (lowerCommand.contains('request') || lowerCommand.contains('receive')) {
      return 'request_money';
    }
    
    // Buy airtime
    if (lowerCommand.contains('airtime') || lowerCommand.contains('recharge')) {
      return 'buy_airtime';
    }
    
    // Pay bills
    if (lowerCommand.contains('bill') || lowerCommand.contains('pay bill')) {
      return 'pay_bills';
    }
    
    // Top up
    if (lowerCommand.contains('top up') || lowerCommand.contains('topup') || lowerCommand.contains('add money')) {
      return 'top_up';
    }
    
    // QR code
    if (lowerCommand.contains('my qr') || lowerCommand.contains('show qr') || lowerCommand.contains('my code')) {
      return 'show_qr';
    }
    
    // Scan QR
    if (lowerCommand.contains('scan')) {
      return 'scan_qr';
    }
    
    // Credit score
    if (lowerCommand.contains('credit') || lowerCommand.contains('score')) {
      return 'credit_score';
    }
    
    // BNPL
    if (lowerCommand.contains('bnpl') || lowerCommand.contains('buy now pay later') || lowerCommand.contains('loan')) {
      return 'bnpl';
    }
    
    // Transactions
    if (lowerCommand.contains('transaction') || lowerCommand.contains('history')) {
      return 'transactions';
    }
    
    // Settings
    if (lowerCommand.contains('setting')) {
      return 'settings';
    }
    
    // Go back
    if (lowerCommand.contains('back') || lowerCommand.contains('return') || lowerCommand.contains('previous')) {
      return 'go_back';
    }
    
    // Help
    if (lowerCommand.contains('help')) {
      return 'help';
    }
    
    return 'unknown';
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
        
        // Wake word status indicator (top right)
        if (_wakeWordActive && _accessibility.isVoiceControlEnabled)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.mic, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Say "Inka"',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Floating voice command button (for manual activation)
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
