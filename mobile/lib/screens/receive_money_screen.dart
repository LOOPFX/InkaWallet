import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../services/accessibility_service.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accessibility = AccessibilityService();
  String _paymentMethod = 'mpamba';
  
  @override
  void initState() {
    super.initState();
    _accessibility.speak('Receive money screen. Simulate incoming payment');
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _receiveMoney() async {
    if (_formKey.currentState!.validate()) {
      final wallet = Provider.of<WalletProvider>(context, listen: false);
      final success = await wallet.receiveMoney(
        amount: double.parse(_amountController.text),
        paymentMethod: _paymentMethod,
        description: 'Incoming transfer from $_paymentMethod',
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
        title: const Text('Receive Money'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.blue),
                      SizedBox(height: 16),
                      Text(
                        'Simulate Incoming Payment',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'This is a mock feature to demonstrate receiving money from external payment providers.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
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
                  labelText: 'From Payment Method',
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: const [
                  DropdownMenuItem(value: 'mpamba', child: Text('TNM Mpamba')),
                  DropdownMenuItem(value: 'airtel_money', child: Text('Airtel Money')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
                ],
                onChanged: (value) {
                  setState(() => _paymentMethod = value!);
                  _accessibility.speak('From: $value');
                },
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _receiveMoney,
                child: const Text('Simulate Receive'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
