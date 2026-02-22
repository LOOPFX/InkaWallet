import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for Speechmatics Real-time and Batch transcription
class SpeechmaticsService {
  static final SpeechmaticsService _instance = SpeechmaticsService._internal();
  factory SpeechmaticsService() => _instance;
  SpeechmaticsService._internal();

  // Speechmatics API configuration
  static const String _baseUrl = 'https://asr.api.speechmatics.com/v2';
  String? _apiKey;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Initialize with API key from secure storage
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('speechmatics_api_key');
    
    // For demo purposes, set a placeholder
    // In production, this should be fetched from environment or secure storage
    _apiKey ??= 'YOUR_SPEECHMATICS_API_KEY';
    
    _isInitialized = _apiKey != null && _apiKey!.isNotEmpty;
  }
  
  /// Set API key
  Future<void> setApiKey(String apiKey) async {
    _apiKey = apiKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('speechmatics_api_key', apiKey);
    _isInitialized = true;
  }
  
  /// Transcribe audio file (batch mode)
  Future<Map<String, dynamic>> transcribeAudio({
    required String audioFilePath,
    String language = 'en',
    bool enableDiarization = false,
    bool enableEntities = true,
  }) async {
    if (!_isInitialized || _apiKey == null) {
      throw Exception('Speechmatics API not initialized. Please set API key.');
    }
    
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/jobs'),
      );
      
      request.headers['Authorization'] = 'Bearer $_apiKey';
      
      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath('data_file', audioFilePath),
      );
      
      // Add configuration
      final config = {
        'type': 'transcription',
        'transcription_config': {
          'language': language,
          'operating_point': 'enhanced',
          'enable_partials': true,
          'max_delay': 3.0,
          'diarization': enableDiarization ? 'speaker' : 'none',
          'enable_entities': enableEntities,
        }
      };
      
      request.fields['config'] = jsonEncode(config);
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Transcription failed: $responseBody');
      }
    } catch (e) {
      throw Exception('Speechmatics transcription error: $e');
    }
  }
  
  /// Get job status and results
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    if (!_isInitialized || _apiKey == null) {
      throw Exception('Speechmatics API not initialized');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jobs/$jobId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get job status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching job status: $e');
    }
  }
  
  /// Get transcript from completed job
  Future<String> getTranscript(String jobId) async {
    if (!_isInitialized || _apiKey == null) {
      throw Exception('Speechmatics API not initialized');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/jobs/$jobId/transcript'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract text from transcript
        if (data['results'] != null) {
          final results = data['results'] as List;
          final transcriptParts = results
              .where((r) => r['type'] == 'word')
              .map((r) => r['alternatives']?[0]?['content'] ?? '')
              .toList();
          
          return transcriptParts.join(' ');
        }
        
        return '';
      } else {
        throw Exception('Failed to get transcript: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching transcript: $e');
    }
  }
  
  /// Real-time streaming configuration (for WebSocket implementation)
  Map<String, dynamic> getRealtimeConfig({
    String language = 'en',
    bool enablePartials = true,
    double maxDelay = 3.0,
  }) {
    return {
      'type': 'StartRecognition',
      'audio_format': {
        'type': 'raw',
        'encoding': 'pcm_s16le',
        'sample_rate': 16000,
      },
      'transcription_config': {
        'language': language,
        'operating_point': 'enhanced',
        'enable_partials': enablePartials,
        'max_delay': maxDelay,
        'enable_entities': true,
      }
    };
  }
  
  /// Process transcript for voice commands
  String cleanTranscript(String transcript) {
    return transcript
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }
  
  /// Extract intent from transcript
  Map<String, dynamic> extractIntent(String transcript) {
    final cleaned = cleanTranscript(transcript);
    
    // Send money patterns
    if (cleaned.contains('send') && (cleaned.contains('money') || cleaned.contains('cash'))) {
      return {
        'intent': 'send_money',
        'confidence': 0.9,
        'transcript': transcript,
      };
    }
    
    // Request money patterns
    if (cleaned.contains('request') && cleaned.contains('money')) {
      return {
        'intent': 'request_money',
        'confidence': 0.9,
        'transcript': transcript,
      };
    }
    
    // Check balance
    if (cleaned.contains('balance') || cleaned.contains('how much')) {
      return {
        'intent': 'check_balance',
        'confidence': 0.95,
        'transcript': transcript,
      };
    }
    
    // Login
    if (cleaned.contains('login') || cleaned.contains('log in') || cleaned.contains('sign in')) {
      return {
        'intent': 'login',
        'confidence': 0.9,
        'transcript': transcript,
      };
    }
    
    // Register
    if (cleaned.contains('register') || cleaned.contains('sign up') || cleaned.contains('create account')) {
      return {
        'intent': 'register',
        'confidence': 0.9,
        'transcript': transcript,
      };
    }
    
    // Buy airtime
    if (cleaned.contains('airtime') || (cleaned.contains('buy') && cleaned.contains('credit'))) {
      return {
        'intent': 'buy_airtime',
        'confidence': 0.85,
        'transcript': transcript,
      };
    }
    
    // Pay bills
    if (cleaned.contains('pay') && cleaned.contains('bill')) {
      return {
        'intent': 'pay_bills',
        'confidence': 0.85,
        'transcript': transcript,
      };
    }
    
    // QR code
    if (cleaned.contains('qr') || cleaned.contains('scan')) {
      return {
        'intent': 'scan_qr',
        'confidence': 0.8,
        'transcript': transcript,
      };
    }
    
    // Credit score
    if (cleaned.contains('credit score') || cleaned.contains('credit rating')) {
      return {
        'intent': 'check_credit',
        'confidence': 0.9,
        'transcript': transcript,
      };
    }
    
    // BNPL
    if (cleaned.contains('buy now pay later') || cleaned.contains('bnpl') || cleaned.contains('loan')) {
      return {
        'intent': 'bnpl',
        'confidence': 0.85,
        'transcript': transcript,
      };
    }
    
    // Settings
    if (cleaned.contains('settings') || cleaned.contains('preferences')) {
      return {
        'intent': 'settings',
        'confidence': 0.85,
        'transcript': transcript,
      };
    }
    
    // Go back / cancel
    if (cleaned.contains('back') || cleaned.contains('cancel') || cleaned.contains('return')) {
      return {
        'intent': 'go_back',
        'confidence': 0.9,
        'transcript': transcript,
      };
    }
    
    // Help
    if (cleaned.contains('help') || cleaned.contains('what can')) {
      return {
        'intent': 'help',
        'confidence': 0.95,
        'transcript': transcript,
      };
    }
    
    return {
      'intent': 'unknown',
      'confidence': 0.0,
      'transcript': transcript,
    };
  }
  
  /// Extract amount from transcript
  double? extractAmount(String transcript) {
    final cleaned = cleanTranscript(transcript);
    
    // Match patterns like "send 100", "5000 kwacha", "MKW 250"
    final patterns = [
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:kwacha|mkw|malawi\s*kwacha)?'),
      RegExp(r'(?:kwacha|mkw)\s*(\d+(?:\.\d+)?)'),
    ];
    
    for (var pattern in patterns) {
      final match = pattern.firstMatch(cleaned);
      if (match != null) {
        final amountStr = match.group(1);
        return double.tryParse(amountStr ?? '');
      }
    }
    
    return null;
  }
  
  /// Extract account/phone number from transcript
  String? extractRecipient(String transcript) {
    final cleaned = cleanTranscript(transcript);
    
    // Match phone numbers
    final phonePattern = RegExp(r'(\+?265\s*\d{3}\s*\d{3}\s*\d{3}|\d{10})');
    final phoneMatch = phonePattern.firstMatch(cleaned);
    if (phoneMatch != null) {
      return phoneMatch.group(0)?.replaceAll(RegExp(r'\s+'), '');
    }
    
    // Match account numbers (format: ACC-XXXXXXXX)
    final accountPattern = RegExp(r'ACC-\d{8}');
    final accountMatch = accountPattern.firstMatch(transcript);
    if (accountMatch != null) {
      return accountMatch.group(0);
    }
    
    return null;
  }
}
