import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

/// Service for Speechmatics Real-time conversational voice AI
/// Based on Speechmatics Voice SDK concepts adapted for Flutter
/// 
/// Features:
/// - Real-time WebSocket streaming
/// - Automatic turn detection (knows when user finished speaking)
/// - Intelligent segmentation (groups words into meaningful chunks)
/// - Low-latency transcription for conversational AI
/// - Speaker diarization support
class SpeechmaticsService {
  static final SpeechmaticsService _instance = SpeechmaticsService._internal();
  factory SpeechmaticsService() => _instance;
  SpeechmaticsService._internal();

  // Speechmatics WebSocket endpoint for real-time transcription
  static const String _realtimeUrl = 'wss://eu2.rt.speechmatics.com/v2';
  static const String _batchUrl = 'https://asr.api.speechmatics.com/v2';
  String? _apiKey;
  
  // WebSocket connection state
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isInitialized = false;
  
  // Audio streaming state
  bool _isStreaming = false;
  int _sequenceNumber = 0;
  
  // Transcript state
  final StreamController<String> _partialTranscriptController = 
      StreamController<String>.broadcast();
  final StreamController<String> _finalTranscriptController = 
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _segmentController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Conversation state for turn detection
  String _currentUtterance = '';
  DateTime? _lastWordTime;
  Timer? _turnDetectionTimer;
  static const Duration _turnDetectionDelay = Duration(milliseconds: 800);
  
  // Public getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get isStreaming => _isStreaming;
  
  // Streams for listening to transcription results
  Stream<String> get partialTranscripts => _partialTranscriptController.stream;
  Stream<String> get finalTranscripts => _finalTranscriptController.stream;
  Stream<Map<String, dynamic>> get segments => _segmentController.stream;
  
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
  
  /// Connect to Speechmatics real-time WebSocket API
  /// 
  /// Presets available (from Voice SDK):
  /// - 'fast': low latency, fast responses
  /// - 'adaptive': general conversation (recommended for InkaWallet)
  /// - 'smart_turn': complex conversation with ML turn detection
  /// - 'scribe': note-taking
  /// - 'captions': live captioning
  Future<bool> connect({
    String language = 'en',
    String preset = 'adaptive', // Best for conversational AI
    bool enableDiarization = true,
    bool enablePartials = true,
    double maxDelay = 0.7, // Low latency for interactive conversation
  }) async {
    if (!_isInitialized || _apiKey == null) {
      throw Exception('Speechmatics API not initialized. Please set API key.');
    }
    
    if (_isConnected) {
      print('Already connected to Speechmatics');
      return true;
    }
    
    try {
      // Connect to WebSocket with authentication
      final uri = Uri.parse('$_realtimeUrl?jwt=$_apiKey');
      _channel = WebSocketChannel.connect(uri);
      
      // Wait for connection to open
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Send StartRecognition message with conversational config
      final startMessage = {
        'message': 'StartRecognition',
        'audio_format': {
          'type': 'raw',
          'encoding': 'pcm_s16le', // 16-bit PCM (standard for mobile)
          'sample_rate': 16000, // 16kHz for voice
        },
        'transcription_config': {
          'language': language,
          'operating_point': 'enhanced', // Best accuracy
          'enable_partials': enablePartials, // Get word-by-word updates
          'max_delay': maxDelay, // Low latency for conversation
          'diarization': enableDiarization ? 'speaker' : 'none',
          'enable_entities': true, // Extract numbers, amounts, etc.
          'punctuation_overrides': {
            'permitted_marks': ['.', ',', '?', '!']
          },
        }
      };
      
      _channel!.sink.add(jsonEncode(startMessage));
      
      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
        cancelOnError: false,
      );
      
      _isConnected = true;
      _sequenceNumber = 0;
      print('Connected to Speechmatics real-time API (preset: $preset)');
      return true;
      
    } catch (e) {
      print('Failed to connect to Speechmatics: $e');
      _isConnected = false;
      return false;
    }
  }
  
  /// Send audio chunk for real-time transcription
  /// 
  /// Audio must be:
  /// - 16-bit PCM (signed little-endian)
  /// - 16kHz sample rate
  /// - Mono channel
  /// 
  /// Recommended chunk size: 160-320 samples (10-20ms at 16kHz)
  Future<void> sendAudio(Uint8List audioData) async {
    if (!_isConnected || _channel == null) {
      throw Exception('Not connected to Speechmatics. Call connect() first.');
    }
    
    if (!_isStreaming) {
      _isStreaming = true;
    }
    
    // Send binary audio data
    _channel!.sink.add(audioData);
    _sequenceNumber++;
  }
  
  /// Signal end of audio stream (end of turn)
  Future<void> endStream() async {
    if (!_isConnected || _channel == null) {
      return;
    }
    
    final endMessage = {
      'message': 'EndOfStream',
      'last_seq_no': _sequenceNumber,
    };
    
    _channel!.sink.add(jsonEncode(endMessage));
    _isStreaming = false;
    print('Sent EndOfStream to Speechmatics');
  }
  
  /// Handle incoming WebSocket messages from Speechmatics
  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final messageType = data['message'];
      
      switch (messageType) {
        case 'RecognitionStarted':
          print('Speechmatics recognition started');
          break;
          
        case 'AddPartialTranscript':
          // Partial results - low latency, word-by-word updates
          final transcript = _extractTranscript(data);
          if (transcript.isNotEmpty) {
            _partialTranscriptController.add(transcript);
            _currentUtterance = transcript;
            _lastWordTime = DateTime.now();
            _resetTurnDetectionTimer();
          }
          break;
          
        case 'AddTranscript':
          // Final transcript for a segment
          final transcript = _extractTranscript(data);
          if (transcript.isNotEmpty) {
            _finalTranscriptController.add(transcript);
            
            // Create segment with speaker info (Voice SDK style)
            final segment = {
              'text': transcript,
              'speaker_id': data['results']?[0]?['speaker'] ?? 'S1',
              'start_time': data['start_time'],
              'end_time': data['end_time'],
              'is_final': true,
              'confidence': data['results']?[0]?['confidence'] ?? 0.0,
            };
            
            _segmentController.add(segment);
            _currentUtterance = '';
          }
          break;
          
        case 'EndOfTranscript':
          print('Speechmatics: End of transcript');
          break;
          
        case 'Warning':
          print('Speechmatics warning: ${data['reason']}');
          break;
          
        case 'Error':
          print('Speechmatics error: ${data['reason']}');
          _handleWebSocketError(data['reason']);
          break;
          
        case 'Info':
          print('Speechmatics info: ${data['message_detail']}');
          break;
          
        default:
          print('Unknown Speechmatics message type: $messageType');
      }
    } catch (e) {
      print('Error parsing Speechmatics message: $e');
    }
  }
  
  /// Extract transcript text from Speechmatics result
  String _extractTranscript(Map<String, dynamic> data) {
    try {
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        return '';
      }
      
      final words = results
          .where((r) => r['type'] == 'word')
          .map((r) => r['alternatives']?[0]?['content'] ?? '')
          .where((word) => word.isNotEmpty)
          .toList();
      
      return words.join(' ');
    } catch (e) {
      return '';
    }
  }
  
  /// Reset turn detection timer (automatic "user finished speaking" detection)
  void _resetTurnDetectionTimer() {
    _turnDetectionTimer?.cancel();
    _turnDetectionTimer = Timer(_turnDetectionDelay, () {
      if (_currentUtterance.isNotEmpty) {
        // User has stopped speaking - emit final segment
        final segment = {
          'text': _currentUtterance,
          'speaker_id': 'USER',
          'is_final': true,
          'turn_ended': true,
        };
        _segmentController.add(segment);
        _currentUtterance = '';
      }
    });
  }
  
  /// Handle WebSocket errors
  void _handleWebSocketError(dynamic error) {
    print('Speechmatics WebSocket error: $error');
    _isConnected = false;
    _isStreaming = false;
  }
  
  /// Handle WebSocket connection closed
  void _handleWebSocketDone() {
    print('Speechmatics WebSocket connection closed');
    _isConnected = false;
    _isStreaming = false;
  }
  
  /// Disconnect from Speechmatics
  Future<void> disconnect() async {
    _turnDetectionTimer?.cancel();
    
    if (_isConnected && _isStreaming) {
      await endStream();
    }
    
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    _isConnected = false;
    _isStreaming = false;
    _sequenceNumber = 0;
    _currentUtterance = '';
    print('Disconnected from Speechmatics');
  }
  
  /// Cleanup resources
  void dispose() {
    disconnect();
    _partialTranscriptController.close();
    _finalTranscriptController.close();
    _segmentController.close();
  }
  
  //
  // ========== BATCH TRANSCRIPTION (for file uploads) ==========
  //
  
  /// Transcribe audio file (batch mode) - for recorded files only
  /// For real-time conversation, use connect() + sendAudio() instead
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
        Uri.parse('$_batchUrl/jobs'),
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
  
  /// Get batch job status
  Future<Map<String, dynamic>> getJobStatus(String jobId) async {
    if (!_isInitialized || _apiKey == null) {
      throw Exception('Speechmatics API not initialized');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$_batchUrl/jobs/$jobId'),
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
  
  //
  // ========== CONVERSATION & INTENT EXTRACTION ==========
  //
  
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
