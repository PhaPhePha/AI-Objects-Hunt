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
  const CameraScreen({super.key, required this.cameras});

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

  @override
  void initState() {
    super.initState();
    _detector.init();
    _initBackCamera();
  }

  void _initBackCamera() {
    final backCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
    _controller = CameraController(backCamera, ResolutionPreset.high, enableAudio: false);
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _detector.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);
    try {
      final XFile file = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(file.path);
        _detections = [];
      });
      final results = await _detector.detect(_capturedImage!, threshold: _confidenceThreshold);
      if (!mounted) return;
      setState(() => _detections = results);
    } catch (e) {
      debugPrint('Lỗi khi chụp ảnh: $e');
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
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhotoGalleryScreen()));
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }

  Future<void> _saveImageLocally() async {
    if (_capturedImage == null) return;
    try {
      if (_detections.isNotEmpty) {
        await _storage.saveWithDetections(_capturedImage!, _detections, _detector);
      } else {
        await _storage.saveOriginal(_capturedImage!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ảnh'), duration: Duration(seconds: 1)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi lưu ảnh: $e')));
    } finally {
      setState(() {
        _capturedImage = null;
        _detections = [];
      });
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
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
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
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                      BoxShadow(color: Colors.black45, blurRadius: 24, offset: const Offset(0, 10)),
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
                    icon: _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                    onTap: _toggleFlash,
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 16,
                  child: CameraIconButton(icon: Icons.photo_library_outlined, onTap: _openGallery),
                ),
              ],
              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: _capturedImage == null
                      ? CaptureButton(isCapturing: _isCapturing, onTap: _capturePhoto)
                      : RetakeAndSendRow(onRetake: _retakePhoto, onSend: _saveImageLocally),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}