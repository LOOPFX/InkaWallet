import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/accessibility_service.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accessibility = AccessibilityService();
  String _paymentMethod = 'inkawallet';
  
  @override
  void initState() {
    super.initState();
    _accessibility.speak('Send money screen');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendMoney() async {
    if (_formKey.currentState!.validate()) {
      final wallet = Provider.of<WalletProvider>(context, listen: false);
      final success = await wallet.sendMoney(
        receiverPhone: _phoneController.text.trim(),
        amount: double.parse(_amountController.text),
        description: _descriptionController.text.trim(),
        paymentMethod: _paymentMethod,
      );
      
      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Recipient Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+265888123456',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter phone number'
                    : null,
                onTap: () => _accessibility.speak('Recipient phone number field'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (MKW)',
                  prefixIcon: Icon(Icons.money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
                onTap: () => _accessibility.speak('Amount field'),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: const [
                  DropdownMenuItem(value: 'inkawallet', child: Text('InkaWallet')),
                  DropdownMenuItem(value: 'mpamba', child: Text('TNM Mpamba')),
                  DropdownMenuItem(value: 'airtel_money', child: Text('Airtel Money')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                ],
                onChanged: (value) {
                  setState(() => _paymentMethod = value!);
                  _accessibility.speak('Payment method: $value');
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                onTap: () => _accessibility.speak('Description field'),
              ),
              const SizedBox(height: 24),
              
              Consumer<WalletProvider>(
                builder: (context, wallet, _) {
                  if (wallet.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        wallet.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              Consumer<WalletProvider>(
                builder: (context, wallet, _) {
                  return ElevatedButton(
                    onPressed: wallet.isLoading ? null : _sendMoney,
                    child: wallet.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send Money'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
