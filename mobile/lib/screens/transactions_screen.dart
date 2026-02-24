import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/voice_enabled_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: "Transactions",
      onVoiceCommand: (command) async {
        // Basic navigation commands handled by VoiceEnabledScreen
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          if (wallet.transactions.isEmpty) {
            return const Center(
              child: Text('No transactions yet'),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wallet.transactions.length,
            itemBuilder: (context, index) {
              final tx = wallet.transactions[index];
              final isSent = tx['transaction_type'] == 'send';
              final amount = double.parse(tx['amount'].toString());
              final date = DateTime.parse(tx['created_at'].toString());
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSent ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(
                      isSent ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isSent ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(isSent ? 'Sent Money' : 'Received Money'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['description'] ?? 'No description'),
                      Text(
                        '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${isSent ? '-' : '+'}MKW ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isSent ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
