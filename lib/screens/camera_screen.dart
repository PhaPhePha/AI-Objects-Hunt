import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ai_objects_hunt/screens/photo_gallery_screen.dart';
import 'package:ai_objects_hunt/screens/home_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  FlashMode _flashMode = FlashMode.off;
  File? _capturedImage;
  bool _isCapturing = false;

  //Kích thước khung vuông bo góc
  static const double _frameSize = 385;
  static const double _frameRadius = 48;

  @override
  void initState() {
    super.initState();
    _initBackCamera();
  }

  void _initBackCamera() {
    final backCamera = widget.cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

   Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;
 
    setState(() => _isCapturing = true);
 
    try {
      final XFile file = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(file.path);
      });
    } catch (e) {
      debugPrint('Lỗi khi chụp ảnh: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

   void _retakePhoto() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _openGallery() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoGalleryScreen()),
    );
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    final newMode =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(newMode);
    setState(() => _flashMode = newMode);
  }
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
 
          return Stack(
            children: [
              // Nền đen phủ toàn màn hình (thay vì camera full-screen)
              Positioned.fill(child: Container(color: Colors.black)),

              //Tên app
              Positioned(
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
 
              // 1. Khung vuông bo góc ở giữa - chứa camera preview hoặc ảnh vừa chụp
              Positioned(
                top: 150, // khoảng cách từ mép trên màn hình
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
                      child: _capturedImage == null
                          ? _buildCoveredCameraPreview()
                          : Image.file(_capturedImage!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
 
              // 2.nút flash
              //nut flash
              if (_capturedImage == null) ...[
                // Nút trở về Home - đặt giữa trên cùng
                Positioned(
                  top: 50,
                  left: 16,
                    child: _iconButton(
                      Icons.home_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                Positioned(
                  top: 175,
                  left: 20,
                  child: _iconButton(
                    _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : Icons.flash_on,
                    onTap: _toggleFlash,
                  ),
                ),
                //nút Xem thưu viện
                Positioned(
                  top: 50,
                  right: 16,
                  child: _iconButton(
                    Icons.photo_library_outlined,
                    onTap: _openGallery,
                  ),
                ),
              ],
 
              // 3. Nút dưới cùng: chụp ảnh hoặc gửi/chụp lại
              Positioned(
                bottom: 140,
                left: 0,
                right: 0,
                child: Center(
                  child: _capturedImage == null
                      ? _captureButton()
                      : _retakeAndSendRow(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Chống méo hình: camera preview có tỉ lệ riêng, không khớp khung vuông.
  // Bọc AspectRatio đúng tỉ lệ gốc, rồi FittedBox.cover để crop vừa khung
  // vuông mà không kéo dãn hình.
  Widget _buildCoveredCameraPreview() {
    final controller = _controller!;
    // controller.value.aspectRatio trả về theo chiều NGANG gốc của cảm biến
    // (ví dụ 16:9 ≈ 1.78, luôn > 1), KHÔNG phải tỉ lệ hiển thị dọc màn hình.
    // Phải nghịch đảo (1 / aspectRatio) để ra đúng tỉ lệ width/height khi
    // hiển thị dọc — đây là công thức chuẩn theo tài liệu camera plugin.
    final rawAspectRatio = controller.value.aspectRatio;
    final portraitWidthOverHeight = 1 / rawAspectRatio;
 
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        // Đặt chiều rộng cố định, chiều cao suy ra từ tỉ lệ camera thật
        // để không bị kéo dãn khi FittedBox scale lên khung vuông.
        width: _frameSize,
        height: _frameSize / portraitWidthOverHeight,
        child: CameraPreview(controller),
      ),
    );
  }


  Widget _captureButton() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isCapturing ? Colors.white54 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImageLocally() async {
    if (_capturedImage == null) return;
 
    try {
      // Lưu vào thư mục riêng của app (application documents directory)
      final appDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${appDir.path}/captured_photos');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }
 
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${savedDir.path}/$fileName';
      await _capturedImage!.copy(savedPath);
 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu ảnh'),
          duration: Duration(seconds: 1),
        ),
      );
 
      // Quay lại màn hình chụp sau khi lưu xong
      setState(() {
        _capturedImage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu ảnh: $e')),
      );
    }
  }
 
  Widget _retakeAndSendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionButton(
          icon: Icons.close,
          label: 'Chụp lại',
          onTap: _retakePhoto,
        ),
        const SizedBox(width: 40),
        _actionButton(
          icon: Icons.check,
          label: 'Gửi',
          onTap: _saveImageLocally,
          filled: true,
        ),
      ],
    );
  }
 
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? Colors.white : Colors.black45,
              border: filled ? null : Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              icon,
              color: filled ? Colors.black : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
 
  Widget _iconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
