import 'package:flutter/material.dart';
import '../services/biometric_service.dart';

class AuthConfirmationDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    final biometric = BiometricService();
    final canUseBiometric = await biometric.checkAvailability() && biometric.isEnabled;

    if (canUseBiometric) {
      // Try biometric first
      final authenticated = await biometric.authenticate(
        reason: message,
      );
      if (authenticated) return true;
      
      // If biometric fails, fall back to password
      return await _showPasswordDialog(context, title, message) ?? false;
    } else {
      // Use password only
      return await _showPasswordDialog(context, title, message) ?? false;
    }
  }

  static Future<bool?> _showPasswordDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  // In production, verify password with backend
                  // For now, accept any non-empty password
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your password')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
