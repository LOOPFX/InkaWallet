import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../providers/wallet_provider.dart';
import '../services/accessibility_service.dart';
import '../services/voice_command_service.dart';
import '../widgets/voice_enabled_screen.dart';
import '../widgets/auth_confirmation_dialog.dart';

class SendMoneyScreen extends StatefulWidget {
  final String? prefilledRecipient;
  final String? recipientName;
  
  const SendMoneyScreen({
    super.key,
    this.prefilledRecipient,
    this.recipientName,
  });

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accessibility = AccessibilityService();
  final _voiceService = VoiceCommandService();
  String _paymentMethod = 'inkawallet';
  String? _selectedBank;
  bool _expectingPhoneInput = false;
  bool _expectingAmountInput = false;
  
  final List<String> _malawianBanks = [
    'National Bank of Malawi',
    'Standard Bank',
    'FDH Bank',
    'NBS Bank',
    'CDH Investment Bank',
    'Ecobank Malawi',
    'First Capital Bank',
    'Nedbank Malawi',
    'MyBucks Banking Corporation',
  ];
  
  @override
  void initState() {
    super.initState();
    _accessibility.speak('Send money screen');
    
    // Prefill recipient if provided (from QR scan)
    if (widget.prefilledRecipient != null) {
      _phoneController.text = widget.prefilledRecipient!;
      if (widget.recipientName != null) {
        _accessibility.speak('Sending to ${widget.recipientName}');
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {
      // Request permission
      if (await FlutterContacts.requestPermission()) {
        // Pick a contact
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null) {
          // Get full contact details
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact != null && fullContact.phones.isNotEmpty) {
            final phone = fullContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '');
            setState(() {
              _phoneController.text = phone;
            });
            await _accessibility.speak('Contact selected: ${fullContact.displayName}');
          } else {
            await _accessibility.speak('Selected contact has no phone number');
          }
        }
      } else {
        await _accessibility.speak('Contacts permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission is required')),
          );
        }
      }
    } catch (e) {
      await _accessibility.speak('Error accessing contacts');
    }
  }

  Future<void> _sendMoney() async {
    if (_formKey.currentState!.validate()) {
      // Require authentication
      final authenticated = await AuthConfirmationDialog.show(
        context: context,
        title: 'Confirm Transaction',
        message: 'Authenticate to send MKW ${_amountController.text} to ${_phoneController.text}',
      );

      if (!authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication required')),
        );
        return;
      }

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

  Future<void> _handleVoiceCommand(Map<String, dynamic> command) async {
    final commandText = command['command'] as String? ?? '';
    final lowerCommand = commandText.toLowerCase();
    
    // Extract phone number
    if (_expectingPhoneInput || lowerCommand.contains('phone') || lowerCommand.contains('number')) {
      final phoneMatch = RegExp(r'\d{10,15}').firstMatch(commandText);
      if (phoneMatch != null) {
        setState(() {
          _phoneController.text = phoneMatch.group(0)!;
          _expectingPhoneInput = false;
        });
        await _accessibility.speak('Phone number set. What amount would you like to send?');
        setState(() => _expectingAmountInput = true);
        return;
      }
      await _accessibility.speak('I could not detect a phone number. Please say the phone number again or type it manually');
      return;
    }
    
    // Extract amount
    if (_expectingAmountInput || lowerCommand.contains('amount') || lowerCommand.contains('send')) {
      final amountMatch = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(commandText);
      if (amountMatch != null) {
        final amount = amountMatch.group(1)!;
        setState(() {
          _amountController.text = amount;
          _expectingAmountInput = false;
        });
        await _accessibility.speak('Amount set to $amount kwacha. Say confirm to send or cancel to abort');
        return;
      }
      await _accessibility.speak('I could not detect an amount. Please say the amount again');
      return;
    }
    
    // Confirm transaction
    if (lowerCommand.contains('confirm') || lowerCommand.contains('yes') || lowerCommand.contains('send')) {
      if (_phoneController.text.isEmpty) {
        await _accessibility.speak('Please provide a phone number first');
        setState(() => _expectingPhoneInput = true);
        return;
      }
      if (_amountController.text.isEmpty) {
        await _accessibility.speak('Please provide an amount first');
        setState(() => _expectingAmountInput = true);
        return;
      }
      await _accessibility.speak('Sending money now');
      await _sendMoney();
      return;
    }
    
    // Cancel transaction
    if (lowerCommand.contains('cancel') || lowerCommand.contains('back') || lowerCommand.contains('no')) {
      await _accessibility.speak('Transaction cancelled');
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }
    
    // Payment method change
    if (lowerCommand.contains('payment') || lowerCommand.contains('method')) {
      if (lowerCommand.contains('mpamba') || lowerCommand.contains('tnm')) {
        setState(() => _paymentMethod = 'mpamba');
        await _accessibility.speak('Payment method set to TNM Mpamba');
      } else if (lowerCommand.contains('airtel')) {
        setState(() => _paymentMethod = 'airtel_money');
        await _accessibility.speak('Payment method set to Airtel Money');
      } else if (lowerCommand.contains('bank')) {
        setState(() => _paymentMethod = 'bank');
        await _accessibility.speak('Payment method set to Bank Transfer');
      } else {
        setState(() => _paymentMethod = 'inkawallet');
        await _accessibility.speak('Payment method set to InkaWallet');
      }
      return;
    }
    
    // Help
    await _accessibility.speak('You can say: phone number, amount, payment method, confirm, or cancel');
  }

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: 'Send Money',
      onVoiceCommand: _handleVoiceCommand,
      child: Scaffold(
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
                // Recipient field - changes label based on payment method
                TextFormField(
                  controller: _phoneController,
                  keyboardType: _paymentMethod == 'bank' || _paymentMethod == 'inkawallet'
                      ? TextInputType.text
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: _paymentMethod == 'bank' || _paymentMethod == 'inkawallet'
                        ? 'Account Number'
                        : 'Recipient Phone Number',
                    prefixIcon: Icon(
                      _paymentMethod == 'bank' || _paymentMethod == 'inkawallet'
                          ? Icons.account_balance
                          : Icons.phone,
                    ),
                    suffixIcon: _paymentMethod != 'bank' && _paymentMethod != 'inkawallet'
                        ? IconButton(
                            icon: const Icon(Icons.contacts),
                            onPressed: _pickContact,
                            tooltip: 'Pick from contacts',
                          )
                        : null,
                    hintText: _paymentMethod == 'bank' 
                        ? 'Enter bank account number'
                        : _paymentMethod == 'inkawallet'
                        ? 'Enter InkaWallet account number'
                        : '+265888123456',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter ${_paymentMethod == "bank" || _paymentMethod == "inkawallet" ? "account number" : "phone number"}'
                      : null,
                  onTap: () => _accessibility.speak(_paymentMethod == 'bank' || _paymentMethod == 'inkawallet' ? 'Account number field' : 'Recipient phone number field'),
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
                  setState(() {
                    _paymentMethod = value!;
                    _selectedBank = null; // Reset bank selection
                    _phoneController.clear(); // Clear recipient field
                  });
                  _accessibility.speak('Payment method: $value');
                },
              ),
              const SizedBox(height: 16),
              
              // Bank selection dropdown (only visible when bank transfer is selected)
              if (_paymentMethod == 'bank') ...[
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  decoration: const InputDecoration(
                    labelText: 'Select Bank',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  items: _malawianBanks.map((bank) {
                    return DropdownMenuItem(
                      value: bank,
                      child: Text(bank),
                    );
                  }).toList(),
                  validator: (value) => value == null ? 'Please select a bank' : null,
                  onChanged: (value) {
                    setState(() => _selectedBank = value);
                    _accessibility.speak('Bank selected: $value');
                  },
                ),
                const SizedBox(height: 16),
              ],
              
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
    ),
    );
  }
}
