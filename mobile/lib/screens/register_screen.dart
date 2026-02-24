import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/accessibility_service.dart';
import '../widgets/voice_enabled_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accessibility = AccessibilityService();
  bool _accessibilityEnabled = true;
  bool _obscurePassword = true;
  
  @override
  void initState() {
    super.initState();
    _accessibility.speak('Registration screen. Create your InkaWallet account');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceCommand(Map<String, dynamic> command) async {
    final commandText = command['command'] as String? ?? '';
    final lowerCommand = commandText.toLowerCase();
    
    // Extract information from voice command
    if (lowerCommand.contains('name') || lowerCommand.contains('called')) {
      // Extract name: "my name is John Doe" or "I'm called Jane Smith"
      final nameMatch = RegExp(r'(?:name is|called|i am) ([a-z ]+)', caseSensitive: false).firstMatch(commandText);
      if (nameMatch != null) {
        final name = nameMatch.group(1)?.trim();
        if (name != null && name.isNotEmpty) {
          setState(() => _fullNameController.text = name);
          await _accessibility.speak('Name set to $name');
        }
      }
    }
    
    if (lowerCommand.contains('email')) {
      final emailMatch = RegExp(r'([a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,})', caseSensitive: false).firstMatch(commandText);
      if (emailMatch != null) {
        final email = emailMatch.group(1);
        if (email != null) {
          setState(() => _emailController.text = email);
          await _accessibility.speak('Email set to $email');
        }
      }
    }
    
    if (lowerCommand.contains('phone') || lowerCommand.contains('number')) {
      final phoneMatch = RegExp(r'(\+?\d{10,15})').firstMatch(commandText);
      if (phoneMatch != null) {
        final phone = phoneMatch.group(1);
        if (phone != null) {
          setState(() => _phoneController.text = phone);
          await _accessibility.speak('Phone number set to $phone');
        }
      }
    }
    
    if (lowerCommand.contains('password')) {
      final passwordMatch = RegExp(r'password (?:is )?([a-z0-9]+)', caseSensitive: false).firstMatch(commandText);
      if (passwordMatch != null) {
        final password = passwordMatch.group(1);
        if (password != null) {
          setState(() => _passwordController.text = password);
          await _accessibility.speak('Password set');
        }
      }
    }
    
    if (lowerCommand.contains('register') || lowerCommand.contains('create account') || lowerCommand.contains('sign up')) {
      await _register();
    }
    
    if (lowerCommand.contains('help')) {
      await _accessibility.speak('You can say: my name is, followed by your name. My email is, followed by email. My phone is, followed by number. Password is, followed by password. Then say create account to register.');
    }
  }
  
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        accessibilityEnabled: _accessibilityEnabled,
      );
      
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: 'registration',
      onVoiceCommand: _handleVoiceCommand,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your full name'
                      : null,
                  onTap: () => _accessibility.speak('Full name field'),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onTap: () => _accessibility.speak('Email field'),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (e.g., +265888123456)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your phone number'
                      : null,
                  onTap: () => _accessibility.speak('Phone number field'),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onTap: () => _accessibility.speak('Password field'),
                ),
                const SizedBox(height: 24),
                
                SwitchListTile(
                  title: const Text('Enable Accessibility Features'),
                  subtitle: const Text('Voice guidance, haptic feedback, and more'),
                  value: _accessibilityEnabled,
                  onChanged: (value) {
                    setState(() => _accessibilityEnabled = value);
                    _accessibility.speak(
                      value ? 'Accessibility enabled' : 'Accessibility disabled',
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          auth.error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Account'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
