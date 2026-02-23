import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/auth_confirmation_dialog.dart';
import '../widgets/voice_enabled_screen.dart';
import '../widgets/voice_enabled_screen.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _apiService = ApiService();

  String _selectedSource = 'mpamba';
  bool _isLoading = false;

  final Map<String, IconData> _sourceIcons = {
    'mpamba': Icons.mobile_friendly,
    'airtel_money': Icons.phone_android,
    'bank': Icons.account_balance,
    'card': Icons.credit_card,
  };

  final Map<String, String> _sourceLabels = {
    'mpamba': 'MPamba',
    'airtel_money': 'Airtel Money',
    'bank': 'Bank Transfer',
    'card': 'Debit/Credit Card',
  };

  Future<void> _topUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Require authentication
    final authenticated = await AuthConfirmationDialog.show(
      context: context,
      title: 'Confirm Top-Up',
      message: 'Authenticate to add MKW ${_amountController.text} to your wallet',
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.topUpWallet(
        source: _selectedSource,
        amount: double.parse(_amountController.text),
        sourceReference: _referenceController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet topped up successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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

  String _getReferenceHint() {
    switch (_selectedSource) {
      case 'mpamba':
        return 'MPamba transaction reference';
      case 'airtel_money':
        return 'Airtel Money reference';
      case 'bank':
        return 'Bank transaction reference';
      case 'card':
        return 'Card transaction reference';
      default:
        return 'Transaction reference';
    }
  }

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: "Top Up",
      onVoiceCommand: (cmd) async {},
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Card(
                color: const Color(0xFFF3E8FF),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Color(0xFF7C3AED)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Add money to your InkaWallet from external sources',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Source Selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Source',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._sourceLabels.entries.map((entry) {
                        return RadioListTile<String>(
                          title: Row(
                            children: [
                              Icon(
                                _sourceIcons[entry.key],
                                color: _selectedSource == entry.key 
                                    ? const Color(0xFF7C3AED) 
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(entry.value),
                            ],
                          ),
                          value: entry.key,
                          groupValue: _selectedSource,
                          activeColor: const Color(0xFF7C3AED),
                          onChanged: (value) {
                            setState(() {
                              _selectedSource = value!;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
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
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                children: [1000, 5000, 10000, 20000, 50000].map((amount) {
                  return ActionChip(
                    label: Text('MKW ${amount ~/ 1000}K'),
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

              // Reference
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: 'Transaction Reference',
                  hintText: _getReferenceHint(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.receipt_long),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter transaction reference';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Instructions
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Instructions',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Complete the payment via ${_sourceLabels[_selectedSource]}\n'
                        '2. Copy the transaction reference\n'
                        '3. Enter the reference above\n'
                        '4. Submit to complete top-up',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _topUp,
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
                        'Complete Top-Up',
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
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}
