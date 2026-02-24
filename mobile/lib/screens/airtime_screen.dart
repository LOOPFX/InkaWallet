import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/voice_enabled_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class AirtimeScreen extends StatefulWidget {
  const AirtimeScreen({Key? key}) : super(key: key);

  @override
  State<AirtimeScreen> createState() => _AirtimeScreenState();
}

class _AirtimeScreenState extends State<AirtimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _notifications = NotificationService();
  
  String _selectedProvider = 'airtel';
  bool _isLoading = false;

  Future<void> _pickContact() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      try {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact?.phones.isNotEmpty == true) {
            setState(() {
              _phoneController.text = fullContact!.phones.first.number;
            });
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking contact: $e')),
        );
      }
    }
  }

  Future<void> _buyAirtime() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.buyAirtime(
        phoneNumber: _phoneController.text.trim(),
        provider: _selectedProvider,
        amount: double.parse(_amountController.text),
        password: _passwordController.text,
      );

      if (mounted) {
        // Add notification
        await _notifications.addNotification(
          title: 'Airtime Purchase',
          message: 'Successfully purchased MKW ${_amountController.text} ${_selectedProvider.toUpperCase()} airtime for ${_phoneController.text}',
          type: 'transaction',
          data: {
            'type': 'airtime',
            'amount': double.parse(_amountController.text),
            'phone': _phoneController.text,
            'provider': _selectedProvider,
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Airtime purchased successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to refresh balance
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    final lowerCommand = command.toLowerCase();
    
    // Extract amount from command like "buy airtime for 500" or "500 kwacha airtime"
    final amountMatch = RegExp(r'(\d+)').firstMatch(lowerCommand);
    if (amountMatch != null) {
      _amountController.text = amountMatch.group(1)!;
    }
    
    // Detect provider
    if (lowerCommand.contains('airtel')) {
      setState(() => _selectedProvider = 'airtel');
    } else if (lowerCommand.contains('tnm')) {
      setState(() => _selectedProvider = 'tnm');
    }
  }

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: "Buy Airtime",
      onVoiceCommand: (cmd) async { await _handleVoiceCommand(cmd["text"] ?? ""); },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Buy Airtime'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Provider Selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Provider',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Airtel'),
                              value: 'airtel',
                              groupValue: _selectedProvider,
                              activeColor: const Color(0xFF7C3AED),
                              onChanged: (value) {
                                setState(() {
                                  _selectedProvider = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('TNM'),
                              value: 'tnm',
                              groupValue: _selectedProvider,
                              activeColor: const Color(0xFF7C3AED),
                              onChanged: (value) {
                                setState(() {
                                  _selectedProvider = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: _selectedProvider == 'airtel' 
                      ? '099 123 4567' 
                      : '088 123 4567',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contacts),
                    onPressed: _pickContact,
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  final cleaned = value.replaceAll(RegExp(r'\s+'), '');
                  if (_selectedProvider == 'airtel' &&
                      !RegExp(r'^(\+2659|09|099|0999)\d{6,7}$').hasMatch(cleaned)) {
                    return 'Invalid Airtel number';
                  }
                  if (_selectedProvider == 'tnm' &&
                      !RegExp(r'^(\+2658|08|088|0888)\d{6,7}$').hasMatch(cleaned)) {
                    return 'Invalid TNM number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (MKW)',
                  hintText: 'Minimum MKW 100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 100) {
                    return 'Minimum amount is MKW 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quick amounts
              Wrap(
                spacing: 10,
                children: [100, 500, 1000, 2000, 5000].map((amount) {
                  return ActionChip(
                    label: Text('MKW $amount'),
                    backgroundColor: const Color(0xFFF3E8FF),
                    onPressed: () {
                      setState(() {
                        _amountController.text = amount.toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _buyAirtime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Purchase Airtime',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
