import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({Key? key}) : super(key: key);

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedProvider = 'InkaWallet';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      accessibility.announceScreen('Send Money. Enter recipient details.');
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSendMoney() async {
    if (!_formKey.currentState!.validate()) {
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      await accessibility.speak('Please fix the errors in the form');
      return;
    }

    final amount = double.parse(_amountController.text);
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
    // Check balance
    if (walletProvider.wallet != null && amount > walletProvider.wallet!.balance) {
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      await accessibility.speak('Insufficient balance');
      await accessibility.errorFeedback();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirm transaction
    final confirm = await _showConfirmationDialog(amount);
    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);

    final success = await transactionProvider.sendMoney(
      recipientPhone: _phoneController.text.trim(),
      amount: amount,
      walletProvider: _selectedProvider,
      description: _descriptionController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      await accessibility.speak('Money sent successfully');
      await accessibility.transactionSentFeedback();
      
      // Refresh wallet balance
      await walletProvider.loadWallet();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction successful'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await accessibility.speak('Transaction failed. ${transactionProvider.error}');
      await accessibility.errorFeedback();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(transactionProvider.error ?? 'Transaction failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool?> _showConfirmationDialog(double amount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmationRow('Recipient', _phoneController.text),
            const SizedBox(height: 8),
            _buildConfirmationRow('Amount', 'MWK ${amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildConfirmationRow('Provider', _selectedProvider),
            if (_descriptionController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildConfirmationRow('Note', _descriptionController.text),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await accessibility.buttonPressFeedback();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Balance:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      walletProvider.wallet?.formattedBalance ?? 'MWK 0.00',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Wallet Provider Selection
              Text(
                'Wallet Provider',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AppConstants.externalWalletProviders.map((provider) {
                  final isSelected = _selectedProvider == provider;
                  return ChoiceChip(
                    label: Text(provider),
                    selected: isSelected,
                    onSelected: (selected) async {
                      await accessibility.buttonPressFeedback();
                      if (selected) {
                        setState(() {
                          _selectedProvider = provider;
                        });
                        await accessibility.speak('Selected $provider');
                      }
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Recipient Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Recipient Phone Number',
                  hintText: '+265999000002',
                  prefixIcon: const Icon(Icons.phone),
                  helperText: 'Enter phone number in format +265...',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (!AppConstants.phoneRegex.hasMatch(value)) {
                    return 'Please enter a valid phone number (+265...)';
                  }
                  return null;
                },
                onTap: () async {
                  await accessibility.buttonPressFeedback();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Amount
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (MWK)',
                  hintText: '1000.00',
                  prefixIcon: const Icon(Icons.money),
                  helperText: 'Min: ${AppConstants.minTransactionAmount}, Max: ${AppConstants.maxTransactionAmount}',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid amount';
                  }
                  if (amount < AppConstants.minTransactionAmount) {
                    return 'Minimum amount is MWK ${AppConstants.minTransactionAmount}';
                  }
                  if (amount > AppConstants.maxTransactionAmount) {
                    return 'Maximum amount is MWK ${AppConstants.maxTransactionAmount}';
                  }
                  return null;
                },
                onTap: () async {
                  await accessibility.buttonPressFeedback();
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g., Payment for services',
                  prefixIcon: Icon(Icons.note),
                ),
                textInputAction: TextInputAction.done,
                maxLength: 100,
                onTap: () async {
                  await accessibility.buttonPressFeedback();
                },
                onFieldSubmitted: (_) => _handleSendMoney(),
              ),
              
              const SizedBox(height: 32),
              
              // Quick Amount Buttons
              Text(
                'Quick Amounts',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAmountButton(context, 500, accessibility),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickAmountButton(context, 1000, accessibility),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickAmountButton(context, 2000, accessibility),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildQuickAmountButton(context, 5000, accessibility),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Send Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSendMoney,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text(
                            'Send Money',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(
    BuildContext context,
    int amount,
    AccessibilityProvider accessibility,
  ) {
    return OutlinedButton(
      onPressed: () async {
        await accessibility.buttonPressFeedback();
        _amountController.text = amount.toString();
        await accessibility.speak('$amount Kwacha');
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        '$amount',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
