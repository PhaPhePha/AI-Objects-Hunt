import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'photo_gallery_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  void _openCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CameraScreen(cameras: cameras)),
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoGalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tên app
              const Text(
                'AI Objects Hunt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 80),

              // Nút vào Camera
              _HomeButton(
                icon: Icons.camera_alt_rounded,
                label: 'Chụp ảnh',
                onTap: () => _openCamera(context),
                filled: true,
              ),
              const SizedBox(height: 20),

              // Nút vào Gallery
              _HomeButton(
                icon: Icons.photo_library_outlined,
                label: 'Xem ảnh đã lưu',
                onTap: () => _openGallery(context),
                filled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? Colors.white : Colors.black,
          foregroundColor: filled ? Colors.black : Colors.white,
          side: filled ? BorderSide.none : const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}