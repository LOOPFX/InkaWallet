import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart' as models;

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  models.TransactionType? _filterType;
  models.TransactionStatus? _filterStatus;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);
      accessibility.announceScreen('Transaction History');
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final accessibility = Provider.of<AccessibilityProvider>(context, listen: false);

    await transactionProvider.loadTransactions();
    await accessibility.speak('Transactions refreshed');
    await accessibility.successFeedback();

    setState(() {
      _isRefreshing = false;
    });
  }

  List<models.Transaction> _getFilteredTransactions(List<models.Transaction> transactions) {
    var filtered = transactions;

    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    if (_filterStatus != null) {
      filtered = filtered.where((t) => t.status == _filterStatus).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final accessibility = Provider.of<AccessibilityProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final filteredTransactions = _getFilteredTransactions(transactionProvider.transactions);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await accessibility.buttonPressFeedback();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          // Refresh Button
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _handleRefresh,
            tooltip: 'Refresh transactions',
          ),
          
          // Filter Button
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_filterType != null || _filterStatus != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await accessibility.buttonPressFeedback();
              _showFilterDialog();
            },
            tooltip: 'Filter transactions',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: transactionProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(
                        context,
                        transaction,
                        accessibility,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _filterType != null || _filterStatus != null
                  ? 'No transactions match the filters'
                  : 'No transactions yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _filterType != null || _filterStatus != null
                  ? 'Try adjusting your filters'
                  : 'Your transaction history will appear here',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (_filterType != null || _filterStatus != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _filterType = null;
                    _filterStatus = null;
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    models.Transaction transaction,
    AccessibilityProvider accessibility,
  ) {
    final isCredit = transaction.type == models.TransactionType.received;
    final color = isCredit ? Colors.green : Colors.red;
    final icon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          await accessibility.buttonPressFeedback();
          _showTransactionDetails(transaction);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description ?? 
                              (isCredit ? 'Money Received' : 'Money Sent'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ref: ${transaction.referenceNumber}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? '+' : '-'}${transaction.formattedAmount}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          transaction.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(transaction.status),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(models.Transaction transaction) {
    final isCredit = transaction.type == models.TransactionType.received;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Title
              Text(
                'Transaction Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Amount
              Center(
                child: Column(
                  children: [
                    Text(
                      '${isCredit ? '+' : '-'}${transaction.formattedAmount}',
                      style: TextStyle(
                        color: isCredit ? Colors.green : Colors.red,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        transaction.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(transaction.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Divider(),
              const SizedBox(height: 16),
              
              // Details
              _buildDetailRow('Type', isCredit ? 'Money Received' : 'Money Sent'),
              _buildDetailRow('Reference', transaction.referenceNumber ?? 'N/A'),
              _buildDetailRow('Date', transaction.formattedDate),
              if (transaction.description != null && transaction.description!.isNotEmpty)
                _buildDetailRow('Description', transaction.description!),
              
              const SizedBox(height: 32),
              
              // Close Button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type Filter
              const Text(
                'Type',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterType == null,
                    onSelected: (selected) {
                      setDialogState(() {
                        _filterType = null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Sent'),
                    selected: _filterType == models.TransactionType.sent,
                    onSelected: (selected) {
                      setDialogState(() {
                        _filterType = selected ? models.TransactionType.sent : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Received'),
                    selected: _filterType == models.TransactionType.received,
                    onSelected: (selected) {
                      setDialogState(() {
                        _filterType = selected ? models.TransactionType.received : null;
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Status Filter
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterStatus == null,
                    onSelected: (selected) {
                      setDialogState(() {
                        _filterStatus = null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: _filterStatus == models.TransactionStatus.completed,
                    onSelected: (selected) {
                      setDialogState(() {
                        _filterStatus = selected ? models.TransactionStatus.completed : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: _filterStatus == models.TransactionStatus.pending,
                    onSelected: (selected) {
                      setDialogState(() {
                        _filterStatus = selected ? models.TransactionStatus.pending : null;
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('Failed'),
                    selected: _filterStatus == models.TransactionStatus.failed,
                    onSelected: (selected) {
                      setDialogState(() {
                        _filterStatus = selected ? models.TransactionStatus.failed : null;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterStatus = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear All'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(models.TransactionStatus status) {
    switch (status) {
      case models.TransactionStatus.completed:
        return Colors.green;
      case models.TransactionStatus.pending:
        return Colors.orange;
      case models.TransactionStatus.failed:
        return Colors.red;
      case models.TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}
