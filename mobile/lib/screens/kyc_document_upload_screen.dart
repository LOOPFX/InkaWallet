import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../config/app_config.dart';
import '../services/notification_service.dart';
import 'package:http_parser/http_parser.dart';

class KycDocumentUploadScreen extends StatefulWidget {
  const KycDocumentUploadScreen({Key? key}) : super(key: key);

  @override
  _KycDocumentUploadScreenState createState() => _KycDocumentUploadScreenState();
}

class _KycDocumentUploadScreenState extends State<KycDocumentUploadScreen> {
  final NotificationService _notifications = NotificationService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Map<String, dynamic>> _uploadedDocuments = [];
  
  // Required document types
  final List<Map<String, String>> _documentTypes = [
    {'value': 'national_id_front', 'label': 'National ID (Front)'},
    {'value': 'national_id_back', 'label': 'National ID (Back)'},
    {'value': 'passport', 'label': 'Passport Photo Page'},
    {'value': 'drivers_license', 'label': 'Driver\'s License'},
    {'value': 'voters_id', 'label': 'Voter\'s ID'},
    {'value': 'proof_of_address', 'label': 'Proof of Address (Utility bill, etc.)'},
    {'value': 'selfie', 'label': 'Selfie (for verification)'},
    {'value': 'employment_letter', 'label': 'Employment Letter'},
    {'value': 'other', 'label': 'Other Document'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUploadedDocuments();
  }

  Future<void> _loadUploadedDocuments() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/kyc/documents'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> documents = json.decode(response.body);
        setState(() {
          _uploadedDocuments = documents.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error loading documents: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument(String documentType) async {
    // Show source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              subtitle: Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              subtitle: Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      // Voice guidance for camera
      if (source == ImageSource.camera) {
        await _notifications.addNotification(
          title: 'Camera Guidance',
          message: 'Position document in frame. Ensure good lighting and all text is visible.',
          type: 'info',
        );
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      // Upload to server
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.apiBaseUrl}/kyc/documents'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['document_type'] = documentType;
      
      // Add accessibility flags
      request.fields['is_audio_description'] = 'false';
      request.fields['has_sign_language_video'] = 'false';

      request.files.add(await http.MultipartFile.fromPath(
        'document',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        await _notifications.addNotification(
          title: 'Upload Successful',
          message: 'Document uploaded successfully',
          type: 'success',
        );
        
        // Reload documents
        await _loadUploadedDocuments();
      } else {
        final error = json.decode(response.body);
        await _notifications.addNotification(
          title: 'Upload Failed',
          message: error['message'] ?? 'Failed to upload document',
          type: 'error',
        );
      }
    } catch (e) {
      await _notifications.addNotification(
        title: 'Error',
        message: 'An error occurred during upload',
        type: 'error',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForVerification() async {
    // Check minimum documents
    if (_uploadedDocuments.length < 2) {
      await _notifications.addNotification(
        title: 'More Documents Required',
        message: 'Please upload at least 2 documents (ID and proof of address/selfie)',
        type: 'error',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/kyc/submit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _notifications.addNotification(
          title: 'KYC Submitted',
          message: 'Your KYC has been submitted for verification. We will review within 24-48 hours.',
          type: 'success',
        );
        
        Navigator.pushReplacementNamed(context, '/kyc-status');
      } else {
        final error = json.decode(response.body);
        await _notifications.addNotification(
          title: 'Submission Failed',
          message: error['message'] ?? 'Failed to submit KYC',
          type: 'error',
        );
      }
    } catch (e) {
      await _notifications.addNotification(
        title: 'Error',
        message: 'An error occurred during submission',
        type: 'error',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getDocumentLabel(String type) {
    final doc = _documentTypes.firstWhere(
      (d) => d['value'] == type,
      orElse: () => {'value': '', 'label': type},
    );
    return doc['label'] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Documents'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blue, size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Upload clear photos of your documents',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Ensure all text is readable\n• Good lighting\n• No glare or shadows\n• Full document in frame',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Voice Assistance Card
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.mic, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Voice guidance available when taking photos',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Uploaded Documents
                  Text(
                    'Uploaded Documents (${_uploadedDocuments.length})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  if (_uploadedDocuments.isEmpty)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No documents uploaded yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...(_uploadedDocuments.map((doc) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            doc['is_verified'] == 1
                                ? Icons.check_circle
                                : Icons.pending,
                            color: doc['is_verified'] == 1
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: Text(_getDocumentLabel(doc['document_type'])),
                          subtitle: Text(
                            doc['is_verified'] == 1 ? 'Verified' : 'Pending verification',
                          ),
                          trailing: Text(
                            '${(doc['file_size'] / 1024).toStringAsFixed(1)} KB',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    }).toList()),

                  SizedBox(height: 24),

                  // Upload Buttons
                  Text(
                    'Upload Documents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  // Required Documents
                  Text(
                    'Required Documents',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  SizedBox(height: 8),

                  _buildUploadButton('national_id_front', 'National ID (Front)', Icons.credit_card, true),
                  _buildUploadButton('national_id_back', 'National ID (Back)', Icons.credit_card, true),
                  _buildUploadButton('selfie', 'Selfie (for verification)', Icons.face, true),
                  _buildUploadButton('proof_of_address', 'Proof of Address', Icons.home, true),

                  SizedBox(height: 16),
                  Text(
                    'Optional Documents',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  _buildUploadButton('passport', 'Passport', Icons.flight, false),
                  _buildUploadButton('drivers_license', 'Driver\'s License', Icons.local_shipping, false),
                  _buildUploadButton('voters_id', 'Voter\'s ID', Icons.how_to_vote, false),
                  _buildUploadButton('employment_letter', 'Employment Letter', Icons.work, false),
                  _buildUploadButton('other', 'Other Document', Icons.attachment, false),

                  SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _uploadedDocuments.length >= 2 ? _submitForVerification : null,
                      icon: Icon(Icons.check_circle),
                      label: Text(
                        'Submit for Verification',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Requirements Info
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(height: 8),
                          Text(
                            'Minimum 2 documents required:\n• One ID document (National ID, Passport, etc.)\n• One proof of address or selfie',
                            style: TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUploadButton(String type, String label, IconData icon, bool required) {
    final isUploaded = _uploadedDocuments.any((doc) => doc['document_type'] == type);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: () => _uploadDocument(type),
        icon: Icon(
          isUploaded ? Icons.check_circle : icon,
          color: isUploaded ? Colors.green : null,
        ),
        label: Row(
          children: [
            Expanded(child: Text(label)),
            if (required)
              Chip(
                label: Text('Required', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.red[100],
                padding: EdgeInsets.zero,
              ),
            if (isUploaded)
              Chip(
                label: Text('Uploaded', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.green[100],
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
