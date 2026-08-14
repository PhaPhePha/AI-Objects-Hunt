//lưu ảnh (thường + có box vẽ sẵn).
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/detection.dart';
import 'object_detector_service.dart';

class PhotoStorageService {
  Future<Directory> _capturedPhotosDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/captured_photos');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> saveOriginal(File source) async {
    final dir = await _capturedPhotosDir();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return source.copy('${dir.path}/$fileName');
  }

  Future<File> saveWithDetections(
    File source,
    List<Detection> detections,
    ObjectDetectorService detector,
  ) async {
    var image = img.decodeImage(await source.readAsBytes())!;
    image = img.bakeOrientation(image);

    // `BoxFit.cover` in the preview shows the centered square portion of the
    // captured image. Recreate that crop before drawing so the saved file
    // matches exactly what the user saw in the square frame.
    final cropSize = image.width < image.height ? image.width : image.height;
    final cropX = (image.width - cropSize) ~/ 2;
    final cropY = (image.height - cropSize) ~/ 2;

    for (var det in detections) {
      final boxX1 = det.xmin * ObjectDetectorService.inputSize;
      final boxY1 = det.ymin * ObjectDetectorService.inputSize;
      final boxX2 = det.xmax * ObjectDetectorService.inputSize;
      final boxY2 = det.ymax * ObjectDetectorService.inputSize;

      final origX1 =
          (boxX1 - detector.letterboxOffsetX) / detector.letterboxScale;
      final origY1 =
          (boxY1 - detector.letterboxOffsetY) / detector.letterboxScale;
      final origX2 =
          (boxX2 - detector.letterboxOffsetX) / detector.letterboxScale;
      final origY2 =
          (boxY2 - detector.letterboxOffsetY) / detector.letterboxScale;

      // Convert from original-image coordinates into the centered square crop.
      final x1 = (origX1 - cropX).clamp(0, cropSize.toDouble());
      final y1 = (origY1 - cropY).clamp(0, cropSize.toDouble());
      final x2 = (origX2 - cropX).clamp(0, cropSize.toDouble());
      final y2 = (origY2 - cropY).clamp(0, cropSize.toDouble());

      // Do not draw detections that lie entirely outside the visible square.
      if (x2 <= x1 || y2 <= y1) continue;

      img.drawRect(
        image,
        x1: x1.round() + cropX,
        y1: y1.round() + cropY,
        x2: x2.round() + cropX,
        y2: y2.round() + cropY,
        color: img.ColorRgb8(255, 235, 59),
        thickness: 4,
      );
      img.drawString(
        image,
        '${det.label} ${det.confidence.toStringAsFixed(2)}',
        font: img.arial24,
        x: x1.round() + cropX,
        y: (y1 - 26).clamp(0, cropSize.toDouble()).round() + cropY,
        color: img.ColorRgb8(255, 255, 255),
      );
    }

    image = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropSize,
      height: cropSize,
    );

    final dir = await _capturedPhotosDir();
    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outFile = File('${dir.path}/$fileName');
    await outFile.writeAsBytes(img.encodeJpg(image));
    return outFile;
  }
}
