//Tách các nút UI dùng lại nhiều (icon button, capture button, retake/send row)
// thành widget stateless riêng, nhận callback qua constructor:
import 'package:flutter/material.dart';

class CameraIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const CameraIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class CaptureButton extends StatelessWidget {
  final bool isCapturing;
  final VoidCallback onTap;
  const CaptureButton({super.key, required this.isCapturing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              color: isCapturing ? Colors.white54 : Colors.white,
            ),
            child: isCapturing
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                : null,
          ),
        ),
      ),
    );
  }
}

class RetakeAndSendRow extends StatelessWidget {
  final VoidCallback onRetake;
  final VoidCallback onSend;
  final bool isEnglish;

  const RetakeAndSendRow({
    super.key,
    required this.onRetake,
    required this.onSend,
    required this.isEnglish,
  });

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
            child: Icon(icon, color: filled ? Colors.black : Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionButton(icon: Icons.close, label: isEnglish ? 'Retake' : 'Chụp lại', onTap: onRetake),
        const SizedBox(width: 40),
        _actionButton(icon: Icons.check, label: isEnglish ? 'Send' : 'Gửi', onTap: onSend, filled: true),
      ],
    );
  }
}