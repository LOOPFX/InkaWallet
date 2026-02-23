import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/accessibility_service.dart';
import 'package:intl/intl.dart';

class BNPLScreen extends StatefulWidget {
  const BNPLScreen({Key? key}) : super(key: key);

  @override
  State<BNPLScreen> createState() => _BNPLScreenState();
}

class _BNPLScreenState extends State<BNPLScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _accessibility = AccessibilityService();
  
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _loans = [];

  // Helper to safely convert dynamic values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper to safely convert dynamic values to int
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLoans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _api.getBNPLLoans();
      setState(() {
        _loans = result['loans'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading loans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get _activeLoans => _loans.where((l) => l['status'] == 'active').toList();
  List<dynamic> get _completedLoans => _loans.where((l) => l['status'] == 'completed').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Now Pay Later'),
        backgroundColor: const Color(0xFF7C3AED),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active Loans'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLoansList(_activeLoans, isActive: true),
                _buildLoansList(_completedLoans, isActive: false),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplyDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Apply for BNPL'),
        backgroundColor: const Color(0xFF7C3AED),
      ),
    );
  }

  Widget _buildLoansList(List<dynamic> loans, {required bool isActive}) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.shopping_bag_outlined : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active loans' : 'No completed loans',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: loans.length,
        itemBuilder: (context, index) => _buildLoanCard(loans[index], isActive),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan, bool isActive) {
    final principalAmount = _toDouble(loan['principal_amount']);
    final totalAmount = _toDouble(loan['total_amount']);
    final amountPaid = _toDouble(loan['amount_paid']);
    final installmentsPaid = _toInt(loan['installments_paid']);
    final installmentsTotal = _toInt(loan['installments_total']);
    final progress = installmentsTotal > 0 ? installmentsPaid / installmentsTotal : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showLoanDetails(loan),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan['merchant_name'] ?? 'Unknown Merchant',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (loan['item_description'] != null && loan['item_description'].toString().isNotEmpty)
                          Text(
                            loan['item_description'],
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Completed',
                      style: TextStyle(
                        color: isActive ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'MKW ${NumberFormat('#,###').format(principalAmount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total with Interest',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        'MKW ${NumberFormat('#,###').format(totalAmount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Installments: $installmentsPaid / $installmentsTotal',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'MKW ${NumberFormat('#,###').format(amountPaid)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? const Color(0xFF7C3AED) : Colors.green,
                    ),
                  ),
                ],
              ),
              
              if (isActive && loan['next_payment_date'] != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Next Payment: ${_formatDate(loan['next_payment_date'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLoanDetails(Map<String, dynamic> loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BNPLLoanDetails(loan: loan, onPayment: _loadLoans),
    );
  }

  void _showApplyDialog() {
    final merchantController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    int selectedInstallments = 4;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Apply for BNPL'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: merchantController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant Name *',
                    hintText: 'e.g., Amazon, Game Store',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Item Description',
                    hintText: 'e.g., Laptop, Phone',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (MKW) *',
                    hintText: '1000 - 1,000,000',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedInstallments,
                  decoration: const InputDecoration(
                    labelText: 'Installments',
                  ),
                  items: const [
                    DropdownMenuItem(value: 4, child: Text('4 months')),
                    DropdownMenuItem(value: 6, child: Text('6 months')),
                    DropdownMenuItem(value: 12, child: Text('12 months')),
                  ],
                  onChanged: (value) {
                    setDialogState(() => selectedInstallments = value!);
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Interest Rate: 5% per loan',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final merchant = merchantController.text.trim();
                final description = descriptionController.text.trim();
                final amount = amountController.text.trim();

                if (merchant.isEmpty || amount.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill required fields')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  final result = await _api.applyForBNPL(
                    merchantName: merchant,
                    itemDescription: description,
                    amount: double.parse(amount),
                    installments: selectedInstallments,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('BNPL application approved!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _accessibility.speak('BNPL loan approved');
                    _loadLoans();
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
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('MMM d, y').format(dt);
    } catch (e) {
      return 'N/A';
    }
  }
}

// Loan Details Bottom Sheet
class BNPLLoanDetails extends StatelessWidget {
  final Map<String, dynamic> loan;
  final VoidCallback onPayment;

  const BNPLLoanDetails({
    Key? key,
    required this.loan,
    required this.onPayment,
  }) : super(key: key);

  // Helper to safely convert dynamic values to double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isActive = loan['status'] == 'active';
    final installmentAmount = _toDouble(loan['installment_amount']);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loan['merchant_name'] ?? 'Loan Details',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (loan['item_description'] != null)
              Text(
                loan['item_description'],
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            const SizedBox(height: 24),
            
            _buildDetailRow('Loan ID', loan['loan_id'] ?? 'N/A'),
            _buildDetailRow('Principal Amount', 'MKW ${NumberFormat('#,###').format(_toDouble(loan['principal_amount']))}'),
            _buildDetailRow('Interest Rate', '${_toDouble(loan['interest_rate'])}%'),
            _buildDetailRow('Total Amount', 'MKW ${NumberFormat('#,###').format(_toDouble(loan['total_amount']))}'),
            _buildDetailRow('Amount Paid', 'MKW ${NumberFormat('#,###').format(_toDouble(loan['amount_paid']))}'),
            _buildDetailRow('Installment Amount', 'MKW ${NumberFormat('#,###').format(installmentAmount)}'),
            _buildDetailRow('Installments', '${_toDouble(loan['installments_paid']).toInt()} / ${_toDouble(loan['installments_total']).toInt()}'),
            
            if (isActive) ...[
              _buildDetailRow('Next Payment', _formatDate(loan['next_payment_date'])),
              _buildDetailRow('Final Payment', _formatDate(loan['final_payment_date'])),
            ],
            
            const SizedBox(height: 24),
            
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _makePayment(context),
                  icon: const Icon(Icons.payment),
                  label: Text('Pay MKW ${NumberFormat('#,###').format(installmentAmount)}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _makePayment(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: 'Enter Password',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;

              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password required')),
                );
                return;
              }

              Navigator.pop(context); // Close password dialog
              Navigator.pop(context); // Close details sheet

              try {
                final result = await ApiService().payBNPL(
                  loanId: loan['loan_id'],
                  password: password,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Payment successful'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  onPayment();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('MMM d, y').format(dt);
    } catch (e) {
      return 'N/A';
    }
  }
}
