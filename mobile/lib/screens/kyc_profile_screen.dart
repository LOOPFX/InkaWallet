import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/notification_service.dart';

class KycProfileScreen extends StatefulWidget {
  const KycProfileScreen({Key? key}) : super(key: key);

  @override
  _KycProfileScreenState createState() => _KycProfileScreenState();
}

class _KycProfileScreenState extends State<KycProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final NotificationService _notifications = NotificationService();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  
  DateTime? _dateOfBirth;
  String _gender = 'male';
  String _region = 'Central';
  String _sourceOfFunds = 'salary';
  bool _hasDisability = false;
  String _disabilityType = 'none';
  String _preferredCommunication = 'voice';

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      await _notifications.addNotification(
        title: 'Form Incomplete',
        message: 'Please fill in all required fields',
        type: 'error',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/kyc/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'date_of_birth': _dateOfBirth?.toIso8601String().split('T')[0],
          'gender': _gender,
          'national_id': _nationalIdController.text,
          'residential_address': _addressController.text,
          'city': _cityController.text,
          'district': _districtController.text,
          'region': _region,
          'source_of_funds': _sourceOfFunds,
          'has_disability': _hasDisability,
          'disability_type': _disabilityType,
          'preferred_communication': _preferredCommunication,
        }),
      );

      if (response.statusCode == 200) {
        await _notifications.addNotification(
          title: 'Profile Saved',
          message: 'Next, upload your documents.',
          type: 'success',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      await _notifications.addNotification(
        title: 'Error',
        message: 'Failed to save profile',
        type: 'error',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KYC Profile'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(labelText: 'First Name *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(labelText: 'Last Name *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _nationalIdController,
                      decoration: InputDecoration(labelText: 'National ID *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Address *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(labelText: 'City *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _districtController,
                      decoration: InputDecoration(labelText: 'District *'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: Text('Save & Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
