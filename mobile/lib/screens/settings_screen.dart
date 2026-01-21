import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      accessibility.announceScreen('Settings');
    });
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await accessibility.buttonPressFeedback();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      (authProvider.user?.firstName.substring(0, 1) ?? 'U').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${authProvider.user?.firstName ?? ''} ${authProvider.user?.lastName ?? ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.user?.email ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () async {
                      await accessibility.buttonPressFeedback();
                      Navigator.of(context).pushNamed('/profile');
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Accessibility Section
          _buildSectionHeader('Accessibility'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Inclusive Mode'),
                  subtitle: const Text('Enable voice and haptic features'),
                  value: accessibility.isInclusiveModeEnabled,
                  onChanged: (value) async {
                    await accessibility.buttonPressFeedback();
                    await accessibility.toggleInclusiveMode();
                    if (value) {
                      await accessibility.speak('Inclusive mode enabled');
                    } else {
                      await accessibility.speak('Inclusive mode disabled');
                    }
                  },
                  secondary: const Icon(Icons.accessibility_new),
                ),
                
                const Divider(height: 1),
                
                SwitchListTile(
                  title: const Text('Voice Commands'),
                  subtitle: const Text('Control app with voice'),
                  value: accessibility.isVoiceEnabled,
                  onChanged: accessibility.isInclusiveModeEnabled
                      ? (value) async {
                          await accessibility.buttonPressFeedback();
                          await accessibility.toggleVoice();
                          await accessibility.speak(
                            value ? 'Voice commands enabled' : 'Voice commands disabled',
                          );
                        }
                      : null,
                  secondary: const Icon(Icons.mic),
                ),
                
                const Divider(height: 1),
                
                SwitchListTile(
                  title: const Text('Haptic Feedback'),
                  subtitle: const Text('Vibration feedback'),
                  value: accessibility.isHapticEnabled,
                  onChanged: accessibility.isInclusiveModeEnabled
                      ? (value) async {
                          await accessibility.buttonPressFeedback();
                          await accessibility.toggleHaptic();
                          await accessibility.speak(
                            value ? 'Haptic feedback enabled' : 'Haptic feedback disabled',
                          );
                        }
                      : null,
                  secondary: const Icon(Icons.vibration),
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  title: const Text('Text Size'),
                  subtitle: Text('Current: ${_getTextSizeLabel(accessibility.textScaleFactor)}'),
                  leading: const Icon(Icons.text_fields),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await accessibility.buttonPressFeedback();
                    _showTextSizeDialog();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme'),
                  value: accessibility.isDarkMode,
                  onChanged: (value) async {
                    await accessibility.buttonPressFeedback();
                    await accessibility.toggleTheme();
                    await accessibility.speak(
                      value ? 'Dark mode enabled' : 'Light mode enabled',
                    );
                  },
                  secondary: Icon(
                    accessibility.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Security Section
          _buildSectionHeader('Security'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Change Password'),
                  leading: const Icon(Icons.lock),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await accessibility.buttonPressFeedback();
                    await accessibility.speak('Change password');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password - Coming soon')),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  title: const Text('Biometric Authentication'),
                  subtitle: const Text('Use fingerprint or face ID'),
                  leading: const Icon(Icons.fingerprint),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await accessibility.buttonPressFeedback();
                    await accessibility.speak('Biometric settings');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Biometric settings - Coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Feedback Section
          _buildSectionHeader('Feedback'),
          Card(
            child: ListTile(
              title: const Text('Send Feedback'),
              subtitle: const Text('Help us improve InkaWallet'),
              leading: const Icon(Icons.feedback),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await accessibility.buttonPressFeedback();
                await accessibility.speak('Send feedback');
                _showFeedbackDialog();
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                  leading: const Icon(Icons.info),
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  title: const Text('Terms & Conditions'),
                  leading: const Icon(Icons.description),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await accessibility.buttonPressFeedback();
                    await accessibility.speak('Terms and conditions');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms & Conditions - Coming soon')),
                    );
                  },
                ),
                
                const Divider(height: 1),
                
                ListTile(
                  title: const Text('Privacy Policy'),
                  leading: const Icon(Icons.privacy_tip),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await accessibility.buttonPressFeedback();
                    await accessibility.speak('Privacy policy');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy Policy - Coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button
          OutlinedButton(
            onPressed: () async {
              await accessibility.buttonPressFeedback();
              _showLogoutDialog();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Logout'),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  String _getTextSizeLabel(double scale) {
    if (scale <= 1.0) return 'Small';
    if (scale <= 1.2) return 'Medium';
    if (scale <= 1.4) return 'Large';
    return 'Extra Large';
  }

  void _showTextSizeDialog() {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Text Size'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Preview Text',
                style: TextStyle(
                  fontSize: 16 * accessibility.textScaleFactor,
                ),
              ),
              const SizedBox(height: 24),
              Slider(
                value: accessibility.textScaleFactor,
                min: 1.0,
                max: 1.6,
                divisions: 3,
                label: _getTextSizeLabel(accessibility.textScaleFactor),
                onChanged: (value) {
                  setDialogState(() {
                    accessibility.setTextScale(value);
                  });
                },
              ),
              Text(
                _getTextSizeLabel(accessibility.textScaleFactor),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    final feedbackController = TextEditingController();
    int rating = 3;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                decoration: const InputDecoration(
                  hintText: 'Tell us what you think...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await accessibility.successFeedback();
              await accessibility.speak('Thank you for your feedback');
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              await accessibility.speak('Logged out successfully');
              
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
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
