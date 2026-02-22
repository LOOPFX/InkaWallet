import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _accessibility = AccessibilityService();
  final _api = ApiService();
  final LocalAuthentication _auth = LocalAuthentication();
  
  bool _accessibilityEnabled = true;
  bool _voiceEnabled = true;
  bool _hapticsEnabled = true;
  bool _biometricEnabled = false;
  bool _canCheckBiometrics = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBiometrics();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _accessibilityEnabled = _accessibility.isAccessibilityEnabled;
      _voiceEnabled = _accessibility.isVoiceEnabled;
      _hapticsEnabled = _accessibility.isHapticsEnabled;
    });
  }

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await _auth.canCheckBiometrics;
      setState(() {});
    } catch (e) {
      debugPrint('Biometrics error: $e');
    }
  }

  Future<void> _updateSettings() async {
    await _accessibility.updateSettings(
      accessibilityEnabled: _accessibilityEnabled,
      voiceEnabled: _voiceEnabled,
      hapticsEnabled: _hapticsEnabled,
    );
    
    try {
      await _api.updateAccessibilitySettings(
        accessibilityEnabled: _accessibilityEnabled,
        voiceEnabled: _voiceEnabled,
        hapticsEnabled: _hapticsEnabled,
        biometricEnabled: _biometricEnabled,
      );
      if (mounted) {
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
          
          SwitchListTile(
            title: const Text('Enable Accessibility'),
            subtitle: const Text('Voice guidance and haptic feedback'),
            value: _accessibilityEnabled,
            onChanged: (value) {
              setState(() => _accessibilityEnabled = value);
              _updateSettings();
              _accessibility.speak(
                value ? 'Accessibility enabled' : 'Accessibility disabled',
              );
            },
          ),
          
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
          
          SwitchListTile(
            title: const Text('Haptic Feedback'),
            subtitle: const Text('Vibration for confirmations'),
            value: _hapticsEnabled,
            onChanged: _accessibilityEnabled
                ? (value) {
                    setState(() => _hapticsEnabled = value);
                    _updateSettings();
                    if (value) _accessibility.vibrate();
                  }
                : null,
          ),
          
          const Divider(height: 32),
          
          const Text(
            'Security',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          if (_canCheckBiometrics)
            SwitchListTile(
              title: const Text('Biometric Authentication'),
              subtitle: const Text('Fingerprint or face unlock'),
              value: _biometricEnabled,
              onChanged: (value) async {
                if (value) {
                  try {
                    final authenticated = await _auth.authenticate(
                      localizedReason: 'Enable biometric authentication',
                    );
                    if (authenticated) {
                      setState(() => _biometricEnabled = true);
                      _updateSettings();
                    }
                  } catch (e) {
                    debugPrint('Biometric error: $e');
                  }
                } else {
                  setState(() => _biometricEnabled = false);
                  _updateSettings();
                }
              },
            ),
          
          const Divider(height: 32),
          
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => SwitchListTile(
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
          ),
          
          const Divider(height: 32),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About InkaWallet'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () => _accessibility.speak('InkaWallet version 1.0.0'),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
