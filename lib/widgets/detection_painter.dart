import 'dart:math';
import 'package:flutter/material.dart';
import '../models/detection.dart';

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final double frameSize;
  DetectionPainter(this.detections, this.frameSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
    );

    for (var det in detections) {
      final x1 = det.xmin * frameSize;
      final y1 = det.ymin * frameSize;
      final x2 = det.xmax * frameSize;
      final y2 = det.ymax * frameSize;

      canvas.drawRect(Rect.fromLTWH(x1, y1, x2 - x1, y2 - y1), paint);

      textPainter.text = TextSpan(
        text: '${det.label} ${det.confidence.toStringAsFixed(2)}',
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x1, max(0, y1 - 25)));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionPainter old) => old.detections != detections;
}