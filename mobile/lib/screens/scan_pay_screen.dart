import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/voice_enabled_screen.dart';
import '../widgets/voice_enabled_screen.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'send_money_screen.dart';

class ScanPayScreen extends StatefulWidget {
  const ScanPayScreen({Key? key}) : super(key: key);

  @override
  State<ScanPayScreen> createState() => _ScanPayScreenState();
}

class _ScanPayScreenState extends State<ScanPayScreen> {
  final _apiService = ApiService();
  MobileScannerController cameraController = MobileScannerController();
  final mlkit.BarcodeScanner _barcodeScanner = mlkit.BarcodeScanner();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _pickImageAndScan() async {
    try {
      // Request gallery permission
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery permission is required to scan QR from images'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Show processing indicator
        setState(() {
          _isProcessing = true;
        });

        try {
          // Decode QR code from image
          final inputImage = InputImage.fromFilePath(image.path);
          final List<mlkit.Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
          
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            await _processQRCode(barcodes.first.rawValue!);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No QR code found in the image'),
                  backgroundColor: Colors.orange,
                ),
              );
              setState(() {
                _isProcessing = false;
              });
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error scanning QR from image: $e'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Validate QR with backend
      final result = await _apiService.validateQRCode(qrData);

      if (result['valid'] == true && result['recipient'] != null) {
        final recipient = result['recipient'];
        
        if (mounted) {
          // Navigate to send money with pre-filled recipient
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SendMoneyScreen(
                prefilledRecipient: recipient['account_number'],
                recipientName: recipient['name'],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VoiceEnabledScreen(
      screenName: "Scan & Pay",
      onVoiceCommand: (cmd) async {},
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Pay'),
        backgroundColor: const Color(0xFF7C3AED),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImageAndScan,
            tooltip: 'Pick from Gallery',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _processQRCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Position QR code within the frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'The QR will be scanned automatically',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Validating QR code...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Draw semi-transparent overlay
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Cut out the scan area
    final Paint clearPaint = Paint()
      ..blendMode = BlendMode.clear;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(12),
      ),
      clearPaint,
    );

    // Draw corner brackets
    final Paint bracketPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double cornerLength = 40;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), bracketPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanAreaSize - cornerLength, top), 
                    Offset(left + scanAreaSize, top), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top), 
                    Offset(left + scanAreaSize, top + cornerLength), bracketPaint);

    // Bottom-left
    canvas.drawLine(Offset(left, top + scanAreaSize - cornerLength), 
                    Offset(left, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left, top + scanAreaSize), 
                    Offset(left + cornerLength, top + scanAreaSize), bracketPaint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanAreaSize - cornerLength, top + scanAreaSize), 
                    Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
    canvas.drawLine(Offset(left + scanAreaSize, top + scanAreaSize - cornerLength), 
                    Offset(left + scanAreaSize, top + scanAreaSize), bracketPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
