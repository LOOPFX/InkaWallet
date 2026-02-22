import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/accessibility_service.dart';
import 'package:intl/intl.dart';

class CreditScoreScreen extends StatefulWidget {
  const CreditScoreScreen({Key? key}) : super(key: key);

  @override
  State<CreditScoreScreen> createState() => _CreditScoreScreenState();
}

class _CreditScoreScreenState extends State<CreditScoreScreen> {
  final _api = ApiService();
  final _accessibility = AccessibilityService();
  
  bool _isLoading = true;
  Map<String, dynamic>? _creditData;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadCreditScore();
  }

  Future<void> _loadCreditScore() async {
    setState(() => _isLoading = true);
    
    try {
      final score = await _api.getCreditScore();
      final history = await _api.getCreditHistory();
      
      setState(() {
        _creditData = score;
        _history = history['history'] ?? [];
        _isLoading = false;
      });
      
      _accessibility.speak('Credit score loaded: ${score['score']}');
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading credit score: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recalculateScore() async {
    try {
      _accessibility.speak('Recalculating credit score');
      
      final result = await _api.recalculateCreditScore();
      
      setState(() {
        _creditData = result;
      });
      
      if (mounted) {
        final change = result['score_change'] ?? 0;
        final message = change >= 0 
            ? 'Score increased by $change points!' 
            : 'Score decreased by ${change.abs()} points';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: change >= 0 ? Colors.green : Colors.orange,
          ),
        );
        
        _accessibility.speak(message);
      }
      
      await _loadCreditScore(); // Reload history
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recalculating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 750) return Colors.green;
    if (score >= 650) return Colors.lightGreen;
    if (score >= 550) return Colors.orange;
    if (score >= 450) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Score'),
        backgroundColor: const Color(0xFF7C3AED),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recalculateScore,
            tooltip: 'Recalculate Score',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCreditScore,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Credit Score Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getScoreColor(_creditData?['score'] ?? 500),
                              _getScoreColor(_creditData?['score'] ?? 500).withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Your Credit Score',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_creditData?['score'] ?? 500}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _creditData?['rating'] ?? 'Fair',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '300 - 850 Range',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // BNPL Eligibility
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _creditData?['eligible_for_bnpl'] == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _creditData?['eligible_for_bnpl'] == true
                                  ? Colors.green
                                  : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Buy Now Pay Later',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _creditData?['eligible_for_bnpl'] == true
                                        ? 'You are eligible!'
                                        : 'Not eligible (minimum score: 400)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (_creditData?['eligible_for_bnpl'] == true) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Max Loan: MKW ${NumberFormat('#,###').format(_creditData?['max_loan_amount'] ?? 0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Score Breakdown
                    const Text(
                      'Score Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildScoreComponent(
                      'Payment History',
                      _creditData?['payment_history_score'] ?? 0,
                      Icons.payment,
                    ),
                    const SizedBox(height: 12),
                    _buildScoreComponent(
                      'Transaction Volume',
                      _creditData?['transaction_volume_score'] ?? 0,
                      Icons.trending_up,
                    ),
                    const SizedBox(height: 12),
                    _buildScoreComponent(
                      'Account Age',
                      _creditData?['account_age_score'] ?? 0,
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 24),

                    // Statistics
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Borrowed',
                            'MKW ${NumberFormat('#,###').format(_creditData?['total_borrowed'] ?? 0)}',
                            Icons.arrow_upward,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Total Repaid',
                            'MKW ${NumberFormat('#,###').format(_creditData?['total_repaid'] ?? 0)}',
                            Icons.arrow_downward,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Defaults',
                            '${_creditData?['defaults_count'] ?? 0}',
                            Icons.warning,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Last Updated',
                            _formatDate(_creditData?['last_calculated']),
                            Icons.update,
                            const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),

                    if (_history.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Credit History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._history.take(5).map((event) => _buildHistoryItem(event)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildScoreComponent(String title, int score, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$score/100',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> event) {
    final eventType = event['event_type'] ?? '';
    final description = event['description'] ?? '';
    final scoreChange = event['score_change'] ?? 0;
    final date = event['created_at'] ?? '';

    IconData icon;
    Color iconColor;

    switch (eventType) {
      case 'loan_approved':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'payment_made':
        icon = Icons.payment;
        iconColor = Colors.blue;
        break;
      case 'loan_completed':
        icon = Icons.celebration;
        iconColor = Colors.green;
        break;
      case 'payment_missed':
        icon = Icons.warning;
        iconColor = Colors.orange;
        break;
      case 'loan_defaulted':
        icon = Icons.error;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          eventType.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: scoreChange != 0
            ? Text(
                '${scoreChange > 0 ? '+' : ''}$scoreChange',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scoreChange > 0 ? Colors.green : Colors.red,
                ),
              )
            : null,
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
