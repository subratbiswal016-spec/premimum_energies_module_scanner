import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' as mlkit;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart' as ocr;
import 'package:path_provider/path_provider.dart';
import 'form_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isScanned = false;
  DateTime? _cameraStartTime;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = MobileScannerController(
      returnImage: true,
      detectionSpeed: DetectionSpeed.unrestricted,
    );
    _cameraStartTime = DateTime.now();
  }

  Future<void> _restartScanner() async {
    if (_controller != null) {
      try {
        await _controller!.stop();
      } catch (e) {
        debugPrint('Error stopping controller: $e');
      }
      _controller!.dispose();
    }
    setState(() {
      _controller = null;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      setState(() {
        _initController();
        isScanned = false;
      });
    }
  }

  Map<String, String> parseLabelData(List<String> rawTexts) {
    String moduleId = '';
    String jobCard = '';
    
    final RegExp moduleRegExp = RegExp(r'\b(NSM[A-Z0-9]+)\b', caseSensitive: false);
    final RegExp jobCardRegExp = RegExp(r'\b(L\d+-\d+)\b', caseSensitive: false);
    
    for (var text in rawTexts) {
      final lines = text.split('\n');
      for (var line in lines) {
        final cleanLine = line.replaceAll(RegExp(r'\s+'), '');
        
        final jobMatch = jobCardRegExp.firstMatch(cleanLine);
        if (jobMatch != null && jobCard.isEmpty) {
          jobCard = jobMatch.group(1)!.toUpperCase();
        }
        
        final modMatch = moduleRegExp.firstMatch(cleanLine);
        if (modMatch != null && moduleId.isEmpty) {
          moduleId = modMatch.group(1)!.toUpperCase();
        }
        
        if (moduleId.isEmpty || jobCard.isEmpty) {
          final words = line.split(RegExp(r'\s+'));
          for (var word in words) {
            final cleanWord = word.trim().replaceAll(RegExp(r'[^\w\-]'), '');
            if (moduleRegExp.hasMatch(cleanWord) && moduleId.isEmpty) {
              moduleId = cleanWord.toUpperCase();
            } else if (jobCardRegExp.hasMatch(cleanWord) && jobCard.isEmpty) {
              jobCard = cleanWord.toUpperCase();
            }
          }
        }
      }
    }
    
    return {
      'moduleId': moduleId,
      'jobCard': jobCard,
    };
  }

  void _showConfirmationSheet(String scannedModuleId, String scannedJobCard) {
    final TextEditingController moduleIdController = TextEditingController(text: scannedModuleId);
    final TextEditingController jobCardController = TextEditingController(text: scannedJobCard);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6C63FF), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Confirm Scanned Data',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify or adjust the scanned values before saving.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: moduleIdController,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'MODULE ID',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: jobCardController,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: 'JOB CARD',
                    labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFF03DAC6)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF03DAC6)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _restartScanner();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('RESCAN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF03DAC6)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FormScreen(
                                  scannedData: moduleIdController.text,
                                  initialJobCard: jobCardController.text,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (isScanned) {
        _restartScanner();
      }
    });
  }

  Future<void> _pickFromGallery() async {
    setState(() {
      isScanned = true;
    });
    if (_controller != null) {
      try {
        await _controller!.stop();
      } catch (e) {}
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        final mlkit.InputImage inputImage = mlkit.InputImage.fromFilePath(image.path);
        
        // 1. Barcode scanning
        final mlkit.BarcodeScanner barcodeScanner = mlkit.BarcodeScanner();
        final List<mlkit.Barcode> barcodes = await barcodeScanner.processImage(inputImage);
        barcodeScanner.close();
        
        // 2. OCR text recognition
        final textRecognizer = ocr.TextRecognizer(script: ocr.TextRecognitionScript.latin);
        final ocr.RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        textRecognizer.close();
        
        final List<String> rawTexts = [];
        for (var barcode in barcodes) {
          if (barcode.rawValue != null) rawTexts.add(barcode.rawValue!);
        }
        rawTexts.add(recognizedText.text);
        
        final parsed = parseLabelData(rawTexts);
        
        String moduleId = parsed['moduleId'] ?? '';
        String jobCard = parsed['jobCard'] ?? '';
        
        if (moduleId.isEmpty && barcodes.isNotEmpty) {
          moduleId = barcodes.first.rawValue ?? '';
        }
        
        if (moduleId.isNotEmpty || jobCard.isNotEmpty) {
          if (!mounted) return;
          _showConfirmationSheet(moduleId, jobCard);
          return;
        }
      } catch (e) {
        debugPrint('Scanning error: $e');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid module data or job card found in the image.')),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        isScanned = false;
      });
      if (_controller != null) {
        try {
          await _controller!.start();
        } catch (e) {}
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double scanWindowWidth = 280.0;
    final double scanWindowHeight = 180.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
            tooltip: 'Pick from Gallery',
            onPressed: _pickFromGallery,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: scanWindowWidth,
            height: scanWindowHeight,
          );

          return Stack(
            children: [
              _controller == null
                  ? const Center(child: CircularProgressIndicator())
                  : MobileScanner(
                      controller: _controller!,
                      scanWindow: scanWindow,
                      onDetect: (capture) async {
                        if (isScanned) return;
                        if (_cameraStartTime != null &&
                            DateTime.now().difference(_cameraStartTime!).inMilliseconds < 1200) {
                          return;
                        }
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final List<String> codes = barcodes.map((b) => b.rawValue ?? '').where((s) => s.isNotEmpty).toList();
                          if (codes.isNotEmpty) {
                            isScanned = true;
                            setState(() {});
                            if (_controller != null) {
                              try {
                                await _controller!.stop();
                              } catch (e) {}
                            }
                            
                            String moduleId = codes.firstWhere((c) => c.startsWith('NSM') || c.length > 10, orElse: () => codes[0]);
                            String jobCard = '';
                            
                            if (capture.image != null) {
                              try {
                                final tempDir = await getTemporaryDirectory();
                                final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                await tempFile.writeAsBytes(capture.image!);
                                
                                final inputImage = mlkit.InputImage.fromFilePath(tempFile.path);
                                final textRecognizer = ocr.TextRecognizer(script: ocr.TextRecognitionScript.latin);
                                final recognizedText = await textRecognizer.processImage(inputImage);
                                textRecognizer.close();
                                
                                final parsed = parseLabelData([recognizedText.text]);
                                // ALWAYS prefer OCR module ID over barcode scanner value
                                // because mobile_scanner has a native caching bug
                                if (parsed['moduleId'] != null && parsed['moduleId']!.isNotEmpty) {
                                  moduleId = parsed['moduleId']!;
                                }
                                if (parsed['jobCard'] != null && parsed['jobCard']!.isNotEmpty) {
                                  jobCard = parsed['jobCard']!;
                                }
                                
                                if (await tempFile.exists()) {
                                  await tempFile.delete();
                                }
                              } catch (e) {
                                debugPrint('Live OCR error: $e');
                              }
                            }
                            
                            if (!mounted) return;
                            _showConfirmationSheet(moduleId, jobCard);
                          }
                        }
                      },
                    ),
              MobileScannerOverlay(scanWindow: scanWindow),
            ],
          );
        },
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  ScannerOverlayPainter({
    required this.scanWindow,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;
    
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          Radius.circular(borderRadius),
        ),
      );
    
    final path = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(path, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(scanWindow, Radius.circular(borderRadius));
    canvas.drawRRect(rrect, borderPaint);
    
    final cornerPaint = Paint()
      ..color = const Color(0xFF03DAC6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final cornerLength = 24.0;
    final left = scanWindow.left;
    final right = scanWindow.right;
    final top = scanWindow.top;
    final bottom = scanWindow.bottom;

    // Top-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Top-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right, top)
        ..lineTo(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-Left corner
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom)
        ..lineTo(left + cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-Right corner
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}

class MobileScannerOverlay extends StatefulWidget {
  final Rect scanWindow;
  const MobileScannerOverlay({Key? key, required this.scanWindow}) : super(key: key);

  @override
  State<MobileScannerOverlay> createState() => _MobileScannerOverlayState();
}

class _MobileScannerOverlayState extends State<MobileScannerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: ScannerOverlayPainter(scanWindow: widget.scanWindow),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double currentTop = widget.scanWindow.top + 
                (widget.scanWindow.height * _animation.value);
            return Positioned(
              left: widget.scanWindow.left + 10,
              top: currentTop,
              width: widget.scanWindow.width - 20,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF03DAC6).withOpacity(0.8),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: const LinearGradient(
                    colors: [
                      Colors.transparent,
                      Color(0xFF03DAC6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: widget.scanWindow.bottom + 24,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.center_focus_weak_rounded, color: Color(0xFF03DAC6), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Align barcode inside the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
