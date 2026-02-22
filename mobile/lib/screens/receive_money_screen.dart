import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/accessibility_service.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payerController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accessibility = AccessibilityService();
  final _api = ApiService();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _accessibility.speak('Request money screen');
  }

  @override
  void dispose() {
    _payerController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null && fullContact.phones.isNotEmpty) {
            final phone = fullContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
            setState(() {
              _payerController.text = phone;
            });
            await _accessibility.speak('Contact selected: ${fullContact.displayName}');
          } else if (fullContact != null && fullContact.emails.isNotEmpty) {
            setState(() {
              _payerController.text = fullContact.emails.first.address;
            });
            await _accessibility.speak('Contact selected: ${fullContact.displayName}');
          }
        }
      }
    } catch (e) {
      await _accessibility.speak('Error accessing contacts');
    }
  }

  Future<void> _requestMoney() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final response = await _api.createMoneyRequest(
          payerIdentifier: _payerController.text.trim(),
          amount: double.parse(_amountController.text),
          description: _descriptionController.text.trim(),
        );
        
        await _accessibility.announceAndVibrate(
          'Money request sent successfully!',
          important: true,
        );

        if (mounted) {
          // Show payment link dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Request Sent'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request ID: ${response['request_id']}'),
                  const SizedBox(height: 8),
                  Text('Amount: MKW ${double.parse(_amountController.text).toLocaleString()}'),
                  const SizedBox(height: 16),
                  const Text('Payment Link:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[200],
                    child: SelectableText(
                      response['payment_link'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: response['payment_link']));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Link'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        await _accessibility.speak('Request failed: ${e.toString()}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Money'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.request_quote, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Account Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      Text('Account: ${user?['account_number'] ?? 'N/A'}'),
                      Text('Phone: ${user?['phone_number'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _payerController,
                decoration: InputDecoration(
                  labelText: 'From (Phone/Email/Account)',
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contacts),
                    onPressed: _pickContact,
                  ),
                  hintText: '+265888123456 or email',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter payer phone/email'
                    : null,
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
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _requestMoney,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send Request', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('How it works', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('1. Enter payer\'s phone, email, or account number', style: TextStyle(fontSize: 12)),
                      Text('2. Set the amount you want to request', style: TextStyle(fontSize: 12)),
                      Text('3. They\'ll receive a notification with a payment link', style: TextStyle(fontSize: 12)),
                      Text('4. Link expires in 7 days', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
