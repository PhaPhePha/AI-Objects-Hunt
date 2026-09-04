//state + điều phối
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:ai_objects_hunt/screens/photo_gallery_screen.dart';
import 'package:ai_objects_hunt/services/object_detector_service.dart';
import 'package:ai_objects_hunt/services/photo_storage_service.dart';
import 'package:ai_objects_hunt/widgets/detection_painter.dart';
import 'package:ai_objects_hunt/widgets/capture_controls.dart';
import 'package:ai_objects_hunt/models/detection.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isEnglish;
  final VoidCallback onToggleLanguage;

  const CameraScreen({
    super.key,
    required this.cameras,
    required this.isEnglish,
    required this.onToggleLanguage,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

  static const double _frameSize = 385;
  static const double _frameRadius = 48;
  static const double _confidenceThreshold = 0.48;

  final _detector = ObjectDetectorService();
  final _storage = PhotoStorageService();

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  FlashMode _flashMode = FlashMode.off;
  File? _capturedImage;
  bool _isCapturing = false;
  List<Detection> _detections = [];
  bool _isModelLoading = true;
  String? _modelError;
  

  @override
  void initState() {
    super.initState();
    _initDetector();
    _initializeControllerFuture = _initBackCamera();
  }

  Future<void> _initDetector() async {
    setState(() {
      _isModelLoading = true;
      _modelError = null;
    });
    final didLoad = await _detector.init();
    if (!mounted) return;
    setState(() {
      _isModelLoading = false;
      _modelError = didLoad ? null : _detector.errorMessage;
    });
  }

  Future<void> _initBackCamera() async {
    final backCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  @override
  void dispose() {
    _detector.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }
    if (_isModelLoading) {
      _showMessage(
        widget.isEnglish
            ? 'Loading detection model, please wait.'
            : 'Đang tải mô hình nhận diện, vui lòng đợi.',
      );
      return;
    }

    if (!_detector.isReady) {
      _showMessage(
        _modelError ??
            (widget.isEnglish
                ? 'Detection model is not ready.'
                : 'Mô hình nhận diện chưa sẵn sàng.'),
      );
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final XFile file = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(file.path);
        _detections = [];
      });
      final results = await _detector.detect(
        _capturedImage!,
        threshold: _confidenceThreshold,
      );
      if (!mounted) return;
      setState(() => _detections = results);
    } on CameraException catch (e) {
      _showMessage(_cameraErrorMessage(e));
    } catch (e) {
      debugPrint(widget.isEnglish ? 'Error capturing image: $e' : 'Lỗi khi chụp ảnh: $e');
      _showMessage(widget.isEnglish ? 'Failed to capture image. Please try again.' : 'Không thể chụp ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _detections = [];
    });
  }

  void _openGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoGalleryScreen(
          isEnglish: widget.isEnglish,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      final newMode = _flashMode == FlashMode.off
          ? FlashMode.torch
          : FlashMode.off;
      await _controller!.setFlashMode(newMode);
      if (mounted) setState(() => _flashMode = newMode);
    } on CameraException catch (e) {
      _showMessage(_cameraErrorMessage(e));
    }
  }

  String _cameraErrorMessage(CameraException error) {
    if (error.code.startsWith('CameraAccess')) {
      return widget.isEnglish
          ? 'Camera permission is not granted. Please allow camera access in Settings.'
          : 'Ứng dụng chưa được cấp quyền dùng camera. Hãy cấp quyền trong Cài đặt.';
    }

    return widget.isEnglish
        ? 'Camera error. Please try again.'
        : 'Camera gặp sự cố. Vui lòng thử lại.';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveImageLocally() async {
    if (_capturedImage == null) return;
    try {
      if (_detections.isNotEmpty) {
        await _storage.saveWithDetections(
          _capturedImage!,
          _detections,
          _detector,
        );
      } else {
        await _storage.saveOriginal(_capturedImage!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEnglish ? 'Capture saved' : 'Đã lưu ảnh'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.isEnglish ? 'Error saving image: $e' : 'Lỗi khi lưu ảnh: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _capturedImage = null;
          _detections = [];
        });
      }
    }
  }

  Widget _buildCoveredCameraPreview() {
    final controller = _controller!;
    final rawAspectRatio = controller.value.aspectRatio;
    final portraitWidthOverHeight = 1 / rawAspectRatio;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _frameSize,
        height: _frameSize / portraitWidthOverHeight,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _detectionOverlay() {
    if (_detections.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: DetectionPainter(_detections, _frameSize),
      size: const Size(_frameSize, _frameSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CameraErrorView(
              isEnglish: widget.isEnglish,
              onBack: () => Navigator.of(context).pop(),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: Container(color: Colors.black)),
              const Positioned(
                top: 55,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'AI Objects Hunt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 150,
                left: 0,
                right: 0,
                child: Container(
                  width: _frameSize,
                  height: _frameSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_frameRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_frameRadius),
                    child: SizedBox(
                      width: _frameSize,
                      height: _frameSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _capturedImage == null
                              ? _buildCoveredCameraPreview()
                              : Image.file(_capturedImage!, fit: BoxFit.cover),
                          _detectionOverlay(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_capturedImage == null) ...[
                Positioned(
                  top: 50,
                  left: 16,
                  child: CameraIconButton(
                    icon: Icons.home_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 175,
                  left: 20,
                  child: CameraIconButton(
                    icon: _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : Icons.flash_on,
                    onTap: _toggleFlash,
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 16,
                  child: CameraIconButton(
                    icon: Icons.photo_library_outlined,
                    onTap: _openGallery,
                  ),
                ),
              ],
              if (_capturedImage == null &&
                  (_isModelLoading || _modelError != null))
                Positioned(
                  top: 555,
                  left: 24,
                  right: 24,
                  child: _ModelStatusBanner(
                    isLoading: _isModelLoading,
                    error: _modelError,
                    onRetry: _initDetector,
                    isEnglish: widget.isEnglish,
                  ),
                ),
              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: _capturedImage == null
                      ? CaptureButton(
                          isCapturing: _isCapturing,
                          onTap: _capturePhoto,
                        )
                      : RetakeAndSendRow(
                          onRetake: _retakePhoto,
                          onSend: _saveImageLocally,
                          isEnglish: widget.isEnglish,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final bool isEnglish;
  final VoidCallback onBack;

  const _CameraErrorView({required this.isEnglish, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isEnglish
              ? 'Failed to initialize camera. Please check camera permissions and try again.' 
              : 'Không thể khởi tạo camera. Hãy kiểm tra quyền camera rồi thử mở lại ứng dụng.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onBack,
              child: Text(isEnglish ? 'Back' : 'Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelStatusBanner extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final bool isEnglish;

  const _ModelStatusBanner({
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  isEnglish
                      ? 'Loading model...'
                      : 'Đang tải mô hình...',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(onPressed: onRetry, child: Text(isEnglish ? 'Retry' : 'Thử lại'),),
              ],
            ),
    );
  }
}
