import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../domain/scan_history_notifier.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../models/scan_result.dart';
import 'scan_result_screen.dart';
import '../services/scan_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _flashOn = false;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  File? _pickedImage;
/// Maps the model's English label to the correct local asset path.
/// Falls back to empty string (shows icon placeholder) for unknown labels.
static String _labelToAssetPath(String label) {
  const map = {
    'Ajwa':       'assets/images/ajwa.png',
    'Medjool':    'assets/images/medjool.png',
    'Sokari':     'assets/images/sukari.png',   // note: file is sukari.png
    'Khalas':     'assets/images/khalas.png',
    'Barhi':      'assets/images/barhi.png',
    'Sugaey':     'assets/images/sagai.png',    // note: file is sagai.png
    'Galaxy':     'assets/images/ajwa.png',     // fallback to closest visual
    'Meneifi':    'assets/images/sukari.png',
    'Nabtat Ali': 'assets/images/ajwa.png',
    'Rutab':      'assets/images/medjool.png',
    'Shaishe':    'assets/images/sukari.png',
  };
  return map[label] ?? '';
}
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _picker = ImagePicker();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController = controller;
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        _cameraController = null;
        return;
      }
      setState(() => _isCameraInitialized = true);
    } catch (e) {
      await _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) status = await Permission.storage.request();

      if (status.isPermanentlyDenied) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Gallery access was permanently denied. Please enable it in Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery permission is required'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null) return;

      setState(() {
        _pickedImage = File(picked.path);
        _isAnalyzing = false;
      });

      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.imagePicked),
            backgroundColor: const Color(0xFF5C3A1E),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open gallery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onCaptureTap() async {
    if (_pickedImage != null) {
      await _analyzeImage(_pickedImage!);
    } else if (_isCameraInitialized && _cameraController != null) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        await _analyzeImage(File(photo.path));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
        }
      }
    }
  }

  Future<void> _analyzeImage(File image) async {
    setState(() => _isAnalyzing = true);

    try {
      // Call the real API
      final apiResult = await ScanService.classify(image);

      if (!mounted) return;

      // Map API response → existing ScanResult model (no screen changes needed)
      final result = ScanResult(
        nameEn: apiResult.label,
        nameAr: apiResult.nameAr,
        originEn: apiResult.originEn,
        originAr: apiResult.originAr,
        confidence: apiResult.confidence,
        calories: apiResult.calories,
        carbs: apiResult.carbs,
        fiber: apiResult.fiber,
        potassium: apiResult.potassium,
      );

      // Save to local history
      scanHistoryNotifier.add(
        ScanHistoryEntry(
          id: _uuid.v4(),
          nameEn: result.nameEn,
          nameAr: result.nameAr,
          originEn: result.originEn,
          originAr: result.originAr,
          confidence: result.confidence,
          calories: result.calories,
          carbs: result.carbs,
          fiber: result.fiber,
          potassium: result.potassium,
         imagePath: _labelToAssetPath(result.nameEn),
          scannedAt: DateTime.now(),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScanResultScreen(result: result)),
      );
    } on ScanServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isAr = localeProvider.isArabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            l.scanDateFruit,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: Color(0xFFD4A017),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'NAKHLAH AI LIVE',
                                style: TextStyle(
                                  color: Color(0xFFD4A017),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _CircleButton(
                      icon: _pickedImage != null
                          ? Icons.close
                          : Icons.help_outline,
                      onTap: () {
                        if (_pickedImage != null) {
                          setState(() => _pickedImage = null);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(
                            0xFFD4A017,
                          ).withValues(alpha: _pulseAnimation.value),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFD4A017,
                            ).withValues(alpha: _pulseAnimation.value * 0.5),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _buildFrameContent(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  _isAnalyzing
                      ? l.analyzing
                      : _pickedImage != null
                      ? l.imagePicked
                      : l.alignDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _CircleButton(
                          icon: Icons.photo_library_outlined,
                          size: 52,
                          onTap: _pickFromGallery,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.gallery,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _isAnalyzing ? null : _onCaptureTap,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAnalyzing
                              ? Colors.grey.shade700
                              : const Color(0xFF5C3A1E),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD4A017,
                              ).withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isAnalyzing
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD4A017),
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.filter_center_focus,
                                color: Colors.white,
                                size: 36,
                              ),
                      ),
                    ),
                    Column(
                      children: [
                        _CircleButton(
                          icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                          size: 52,
                          onTap: () async {
                            if (_cameraController == null) return;
                            try {
                              await _cameraController!.setFlashMode(
                                _flashOn ? FlashMode.off : FlashMode.torch,
                              );
                              setState(() => _flashOn = !_flashOn);
                            } catch (_) {}
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.flash,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFD4A017),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isAnalyzing ? l.analyzing : l.optimizing,
                        style: const TextStyle(
                          color: Color(0xFFD4A017),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: null,
                        backgroundColor: Colors.white12,
                        color: const Color(0xFF7D5A3C),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrameContent() {
    if (_pickedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_pickedImage!, fit: BoxFit.cover),
          if (_isAnalyzing)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4A017)),
              ),
            ),
        ],
      );
    }
    if (_isCameraInitialized && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A017)),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white12,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
