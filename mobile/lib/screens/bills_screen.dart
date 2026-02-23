import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/voice_enabled_screen.dart';
import '../widgets/voice_enabled_screen.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({Key? key}) : super(key: key);

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  String _selectedBillType = 'tv';
  String? _selectedProvider;
  List<String> _providers = [];
  bool _isLoadingProviders = false;
  bool _isLoading = false;

  final Map<String, IconData> _billIcons = {
    'tv': Icons.tv,
    'water': Icons.water_drop,
    'electricity': Icons.bolt,
    'government': Icons.account_balance,
    'insurance': Icons.shield,
    'fees': Icons.school,
    'betting': Icons.sports_soccer,
  };

  final Map<String, String> _billLabels = {
    'tv': 'TV Subscription',
    'water': 'Water Bill',
    'electricity': 'Electricity',
    'government': 'Government',
    'insurance': 'Insurance',
    'fees': 'School/Exam Fees',
    'betting': 'Betting',
  };

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoadingProviders = true;
      _selectedProvider = null;
    });

    try {
      final providers = await _apiService.getBillProviders(_selectedBillType);
      setState(() {
        _providers = providers;
        if (providers.isNotEmpty) {
          _selectedProvider = providers.first;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading providers: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingProviders = false;
      });
    }
  }

  Future<void> _payBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a provider')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.payBill(
        billType: _selectedBillType,
        provider: _selectedProvider!,
        accountNumber: _accountController.text.trim(),
        amount: double.parse(_amountController.text),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill payment successful!'),
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

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: "Pay Bills",
      onVoiceCommand: (cmd) async {},
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Pay Bills'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bill Type Selection
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Bill Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _billLabels.entries.map((entry) {
                          final isSelected = _selectedBillType == entry.key;
                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _billIcons[entry.key],
                                  size: 18,
                                  color: isSelected ? Colors.white : Colors.purple,
                                ),
                                const SizedBox(width: 4),
                                Text(entry.value),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF7C3AED),
                            backgroundColor: const Color(0xFFF3E8FF),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedBillType = entry.key;
                                });
                                _loadProviders();
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Provider Dropdown
              if (_isLoadingProviders)
                const Center(child: CircularProgressIndicator())
              else if (_providers.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: _providers.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Text(provider),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedProvider = value;
                    });
                  },
                ),
              const SizedBox(height: 20),

              // Account Number
              TextFormField(
                controller: _accountController,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Enter account/reference number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account number';
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
                  if (amount == null || amount <= 0) {
                    return 'Invalid amount';
                  }
                  return null;
                },
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
                onPressed: _isLoading ? null : _payBill,
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
                        'Pay Bill',
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
    _accountController.dispose();
    _amountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
