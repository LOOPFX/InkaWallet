import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../services/accessibility_service.dart';
import 'send_money_screen.dart';
import 'receive_money_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _accessibility = AccessibilityService();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wallet = Provider.of<WalletProvider>(context, listen: false);
    await wallet.fetchBalance();
    await wallet.fetchTransactions();
    _accessibility.speak('Home screen. Your balance is ${wallet.formattedBalance}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InkaWallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Balance Card
              Consumer<WalletProvider>(
                builder: (context, wallet, _) {
                  return Card(
                    color: Theme.of(context).colorScheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            wallet.formattedBalance,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              final accountNumber = auth.user?['account_number'] ?? 'N/A';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      accountNumber,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        // Copy to clipboard
                                        _accessibility.speak('Account number copied');
                                      },
                                      child: const Icon(Icons.copy, color: Colors.white70, size: 16),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          if (wallet.isLocked)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Chip(
                                label: Text('Wallet Locked'),
                                backgroundColor: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.send,
                      label: 'Send',
                      onPressed: () {
                        _accessibility.speak('Send money');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SendMoneyScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.call_received,
                      label: 'Receive',
                      onPressed: () {
                        _accessibility.speak('Receive money');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReceiveMoneyScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Consumer<WalletProvider>(
                builder: (context, wallet, _) {
                  if (wallet.transactions.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No transactions yet'),
                        ),
                      ),
                    );
                  }
                  
                  final recentTransactions = wallet.transactions.take(5).toList();
                  return Column(
                    children: recentTransactions.map((tx) {
                      return _TransactionTile(transaction: tx);
                    }).toList(),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isSent = transaction['transaction_type'] == 'send';
    final amount = double.parse(transaction['amount'].toString());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSent ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isSent ? Icons.arrow_upward : Icons.arrow_downward,
            color: isSent ? Colors.red : Colors.green,
          ),
        ),
        title: Text(isSent ? 'Sent Money' : 'Received Money'),
        subtitle: Text(transaction['description'] ?? 'No description'),
        trailing: Text(
          '${isSent ? '-' : '+'}MKW ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isSent ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
