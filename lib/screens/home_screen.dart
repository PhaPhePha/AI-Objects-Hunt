import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_screen.dart';
import 'photo_gallery_screen.dart';
import 'package:ai_objects_hunt/language_state.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool isEnglish;
  final VoidCallback onToggleLanguage;

  const HomeScreen({
    super.key,
    required this.cameras,
    required this.isEnglish,
    required this.onToggleLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Wrap the entire content in a Stack so Positioned can work
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'AI Objects Hunt',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 80),

                  _HomeButton(
                    icon: Icons.camera_alt_rounded,
                    label: widget.isEnglish ? 'Capture' : 'Chụp ảnh',
                    onTap: () => _openCamera(context),
                    filled: true,
                  ),

                  const SizedBox(height: 20),

                  _HomeButton(
                    icon: Icons.photo_library_outlined,
                    label: widget.isEnglish
                        ? 'Gallery'
                        : 'Xem ảnh đã lưu',
                    onTap: () => _openGallery(context),
                    filled: false,
                  ),
                ],
              ),
            ),

            // LANGUAGE BUTTON
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: widget.onToggleLanguage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.language,
                        size: 19,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        widget.isEnglish
                            ? 'English'
                            : 'Tiếng Việt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ),
    );
  }

  void _openCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          cameras: widget.cameras,
          isEnglish: widget.isEnglish,
          onToggleLanguage: widget.onToggleLanguage,
        ),
      ),
    );
  }

  void _openGallery(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PhotoGalleryScreen(
        isEnglish: widget.isEnglish,
        onToggleLanguage: widget.onToggleLanguage,
      )),
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