import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/accessibility_service.dart';
import '../services/biometric_service.dart';
import '../services/voice_command_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _accessibility = AccessibilityService();
  final _biometric = BiometricService();
  final _voiceCommand = VoiceCommandService();
  final _api = ApiService();
  
  bool _accessibilityEnabled = true;
  bool _voiceEnabled = true;
  bool _hapticsEnabled = true;
  bool _voiceControlEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _loadSettings();
    await _checkBiometrics();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _accessibilityEnabled = _accessibility.isAccessibilityEnabled;
      _voiceEnabled = _accessibility.isVoiceEnabled;
      _hapticsEnabled = _accessibility.isHapticsEnabled;
      _voiceControlEnabled = _accessibility.isVoiceControlEnabled;
      _biometricEnabled = _biometric.isEnabled;
    });
  }

  Future<void> _checkBiometrics() async {
    final available = await _biometric.checkAvailability();
    setState(() => _biometricAvailable = available);
  }

  Future<void> _updateSettings() async {
    await _accessibility.updateSettings(
      accessibilityEnabled: _accessibilityEnabled,
      voiceEnabled: _voiceEnabled,
      hapticsEnabled: _hapticsEnabled,
      voiceControlEnabled: _voiceControlEnabled,
    );
    
    try {
      await _api.updateAccessibilitySettings(
        accessibilityEnabled: _accessibilityEnabled,
        voiceEnabled: _voiceEnabled,
        hapticsEnabled: _hapticsEnabled,
        biometricEnabled: _biometricEnabled,
      );
      if (mounted) {
        await _voiceCommand.vibrateSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      debugPrint('Failed to update settings: $e');
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Accessibility Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Accessibility master switch
          SwitchListTile(
            title: const Text('Enable Accessibility'),
            subtitle: const Text('Master switch for all accessibility features'),
            value: _accessibilityEnabled,
            onChanged: (value) {
              setState(() => _accessibilityEnabled = value);
              _updateSettings();
              _accessibility.speak(
                value ? 'Accessibility enabled' : 'Accessibility disabled',
              );
            },
          ),
          
          // Voice guidance
          SwitchListTile(
            title: const Text('Voice Guidance'),
            subtitle: const Text('Text-to-speech announcements'),
            value: _voiceEnabled,
            onChanged: _accessibilityEnabled
                ? (value) {
                    setState(() => _voiceEnabled = value);
                    _updateSettings();
                    _accessibility.speak(
                      value ? 'Voice guidance enabled' : 'Voice guidance disabled',
                    );
                  }
                : null,
          ),
          
          // Haptic feedback
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibration for navigation and confirmations'),
            value: _hapticsEnabled,
            onChanged: _accessibilityEnabled
                ? (value) async {
                    setState(() => _hapticsEnabled = value);
                    _updateSettings();
                    if (value) await _voiceCommand.vibrateSuccess();
                  }
                : null,
          ),
          
          // Voice control
          SwitchListTile(
            title: const Text('Voice Control'),
            subtitle: const Text('Control app with voice commands (Siri-like)'),
            value: _voiceControlEnabled,
            onChanged: _accessibilityEnabled
                ? (value) {
                    setState(() => _voiceControlEnabled = value);
                    _updateSettings();
                    _accessibility.speak(
                      value ? 'Voice control enabled. You can now use voice commands' : 'Voice control disabled',
                    );
                  }
                : null,
          ),
          
          const Divider(height: 32),
          
          // Biometric authentication section
          if (_biometricAvailable)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fingerprint),
                    title: const Text('Biometric Authentication'),
                    subtitle: const Text('Fingerprint, Face ID, or Iris scan'),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Biometric Login'),
                    subtitle: const Text('Quick login with biometrics'),
                    value: _biometricEnabled,
                    onChanged: (value) async {
                      if (value) {
                        final enabled = await _biometric.enableBiometric();
                        if (enabled) {
                          setState(() => _biometricEnabled = true);
                          await _accessibility.speak('Biometric authentication enabled');
                          await _voiceCommand.vibrateConfirmation();
                          _updateSettings();
                        }
                      } else {
                        await _biometric.disableBiometric();
                        setState(() => _biometricEnabled = false);
                        await _accessibility.speak('Biometric authentication disabled');
                        _updateSettings();
                      }
                    },
                  ),
                ],
              ),
            ),
          
          if (!_biometricAvailable)
            const ListTile(
              leading: Icon(Icons.warning, color: Colors.orange),
              title: Text('Biometric Not Available'),
              subtitle: Text('Your device does not support biometric authentication'),
            ),
          
          const Divider(height: 32),
          
          // Theme section
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
              _accessibility.speak(
                value ? 'Dark mode enabled' : 'Dark mode disabled',
              );
            },
          ),
          
          const Divider(height: 32),
          
          // Help section
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Voice Commands Help'),
            subtitle: const Text('Learn available voice commands'),
            onTap: () async {
              await _voiceCommand.provideHelp();
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About InkaWallet'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () => _accessibility.speak('InkaWallet version 1.0.0'),
          ),
          
          const SizedBox(height: 24),
          
          // Logout button
          ElevatedButton.icon(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.all(16),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
