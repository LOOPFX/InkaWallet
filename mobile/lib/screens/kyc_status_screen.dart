import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({Key? key}) : super(key: key);

  @override
  _KycStatusScreenState createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  final NotificationService _notifications = NotificationService();
  bool _isLoading = false;
  Map<String, dynamic>? _kycStatus;

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/kyc/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final status = json.decode(response.body);
        setState(() {
          _kycStatus = status;
        });
      }
    } catch (e) {
      print('Error loading KYC status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'not_started':
        return 'Not Started';
      case 'incomplete':
        return 'Profile Incomplete';
      case 'pending_verification':
        return 'Pending Verification';
      case 'verified':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'not_started':
      case 'incomplete':
        return Colors.orange;
      case 'pending_verification':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      case 'rejected':
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'not_started':
      case 'incomplete':
        return Icons.warning;
      case 'pending_verification':
        return Icons.pending;
      case 'verified':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  String _getTierLabel(String? tier) {
    if (tier == null) return 'Not Verified';
    
    switch (tier) {
      case 'tier1':
        return 'Tier 1 - Basic';
      case 'tier2':
        return 'Tier 2 - Enhanced';
      case 'tier3':
        return 'Tier 3 - Full';
      default:
        return tier;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Verification Status'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadKycStatus,
            tooltip: 'Refresh status',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _kycStatus == null
              ? Center(child: Text('Unable to load KYC status'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                _getStatusIcon(_kycStatus!['kyc_status'] ?? 'not_started'),
                                size: 64,
                                color: _getStatusColor(_kycStatus!['kyc_status'] ?? 'not_started'),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'KYC Status',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _getStatusText(_kycStatus!['kyc_status'] ?? 'not_started'),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_kycStatus!['kyc_status'] ?? 'not_started'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Status-specific messages
                      if (_kycStatus!['kyc_status'] == 'not_started') ...[
                        _buildInfoCard(
                          Icons.info,
                          Colors.blue,
                          'Start KYC Verification',
                          'Complete your KYC verification to unlock full wallet features and higher transaction limits.',
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/kyc-profile'),
                            icon: Icon(Icons.start),
                            label: Text('Start KYC Process', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],

                      if (_kycStatus!['kyc_status'] == 'incomplete') ...[
                        _buildInfoCard(
                          Icons.warning,
                          Colors.orange,
                          'Complete Your Profile',
                          _kycStatus!['message'] ?? 'Please complete your KYC profile to continue',
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/kyc-profile'),
                            icon: Icon(Icons.edit),
                            label: Text('Complete Profile', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],

                      if (_kycStatus!['kyc_status'] == 'pending_verification') ...[
                        _buildInfoCard(
                          Icons.pending,
                          Colors.blue,
                          'Under Review',
                          'Your KYC documents are being reviewed by our team. This typically takes 24-48 hours. We\'ll notify you once completed.',
                        ),
                        SizedBox(height: 16),
                        LinearProgressIndicator(),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Verification in progress...',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                      ],

                      if (_kycStatus!['kyc_status'] == 'verified') ...[
                        _buildInfoCard(
                          Icons.check_circle,
                          Colors.green,
                          'Verification Complete!',
                          'Your KYC has been verified. You now have full access to all wallet features.',
                        ),
                        SizedBox(height: 24),

                        // Verification Details
                        Text(
                          'Verification Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),

                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.verified, color: Colors.green),
                                title: Text('Verification Level'),
                                subtitle: Text(_getTierLabel(_kycStatus!['verification_level'])),
                              ),
                              Divider(height: 1),
                              ListTile(
                                leading: Icon(Icons.calendar_today),
                                title: Text('Verified On'),
                                subtitle: Text(
                                  _kycStatus!['verified_at'] != null
                                      ? DateTime.parse(_kycStatus!['verified_at']).toLocal().toString().split('.')[0]
                                      : 'N/A',
                                ),
                              ),
                              Divider(height: 1),
                              ListTile(
                                leading: Icon(Icons.shield, color: Colors.blue),
                                title: Text('Risk Rating'),
                                subtitle: Text(_kycStatus!['risk_rating']?.toUpperCase() ?? 'N/A'),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Transaction Limits
                        Text(
                          'Transaction Limits',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),

                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.today, color: Colors.orange),
                                title: Text('Daily Limit'),
                                trailing: Text(
                                  'MKW ${_kycStatus!['daily_transaction_limit']?.toStringAsFixed(0) ?? '0'}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Divider(height: 1),
                              ListTile(
                                leading: Icon(Icons.date_range, color: Colors.blue),
                                title: Text('Monthly Limit'),
                                trailing: Text(
                                  'MKW ${_kycStatus!['monthly_transaction_limit']?.toStringAsFixed(0) ?? '0'}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Tier Upgrade Info
                        if (_kycStatus!['verification_level'] != 'tier3')
                          Card(
                            color: Colors.purple[50],
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(Icons.upgrade, color: Colors.purple, size: 32),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upgrade to Higher Tier',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Contact support to upgrade your verification level for higher transaction limits.',
                                    style: TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      // Navigate to support
                                    },
                                    child: Text('Contact Support'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],

                      if (_kycStatus!['kyc_status'] == 'rejected') ...[
                        _buildInfoCard(
                          Icons.cancel,
                          Colors.red,
                          'Verification Rejected',
                          _kycStatus!['rejection_reason'] ?? 'Your KYC verification was rejected. Please review the reason below and resubmit.',
                        ),
                        SizedBox(height: 24),

                        if (_kycStatus!['rejection_reason'] != null) ...[
                          Text(
                            'Rejection Reason',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          Card(
                            color: Colors.red[50],
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                _kycStatus!['rejection_reason'],
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                        ],

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/kyc-profile'),
                            icon: Icon(Icons.refresh),
                            label: Text('Resubmit KYC', style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],

                      // Benefits Card
                      SizedBox(height: 24),
                      Text(
                        'KYC Benefits',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildBenefitItem(Icons.lock_open, 'Full wallet access'),
                              _buildBenefitItem(Icons.account_balance, 'BNPL & Credit services'),
                              _buildBenefitItem(Icons.trending_up, 'Higher transaction limits'),
                              _buildBenefitItem(Icons.security, 'Enhanced security'),
                              _buildBenefitItem(Icons.verified_user, 'Regulatory compliance'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(IconData icon, Color color, String title, String message) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
