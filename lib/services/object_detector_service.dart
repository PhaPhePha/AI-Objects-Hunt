//Gói toàn bộ logic TFLite: load model, letterbox resize, chạy inference,
//trả List<Detection>.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection.dart';

class ObjectDetectorService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  String? _errorMessage;
  static const int inputSize = 320;

  // Thông tin letterbox của lần detect gần nhất, dùng để quy đổi tọa độ ra ảnh gốc
  double letterboxScale = 1.0;
  int letterboxOffsetX = 0;
  int letterboxOffsetY = 0;

  bool get isReady => _interpreter != null;
  String? get errorMessage => _errorMessage;

  Future<bool> init({
    String modelPath = 'assets/models/efficientdet_lite0.tflite',
    String labelsPath = 'assets/models/labels.txt',
  }) async {
    try {
      close();
      _errorMessage = null;
      _interpreter = await Interpreter.fromAsset(modelPath);
      final raw = await rootBundle.loadString(labelsPath);
      _labels = raw.split('\n').where((e) => e.trim().isNotEmpty).toList();
      if (_labels.isEmpty) {
        throw StateError('Danh sách nhãn của model đang trống.');
      }
      debugPrint(
        '>>> ObjectDetectorService: load OK, ${_labels.length} labels',
      );
      return true;
    } catch (e, st) {
      close();
      _errorMessage = 'Không thể tải mô hình nhận diện. Vui lòng thử lại.';
      debugPrint('>>> ObjectDetectorService LỖI load model: $e');
      debugPrint('$st');
      return false;
    }
  }

  img.Image _letterboxResize(img.Image src, int size) {
    final scale = size / (src.width > src.height ? src.width : src.height);
    final newW = (src.width * scale).round().clamp(1, size);
    final newH = (src.height * scale).round().clamp(1, size);
    final resized = img.copyResize(src, width: newW, height: newH);

    final canvas = img.Image(width: size, height: size, numChannels: 3);
    final offsetX = (size - newW) ~/ 2;
    final offsetY = (size - newH) ~/ 2;

    letterboxScale = scale;
    letterboxOffsetX = offsetX;
    letterboxOffsetY = offsetY;

    for (int y = 0; y < newH; y++) {
      for (int x = 0; x < newW; x++) {
        final p = resized.getPixel(x, y);
        canvas.setPixelRgb(
          offsetX + x,
          offsetY + y,
          p.r.toInt(),
          p.g.toInt(),
          p.b.toInt(),
        );
      }
    }
    return canvas;
  }

  Future<List<Detection>> detect(
    File imageFile, {
    double threshold = 0.4,
  }) async {
    if (_interpreter == null) return [];

    var image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) return [];
    image = img.bakeOrientation(image);

    final resized = _letterboxResize(image, inputSize);

    final input = [
      List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final p = resized.getPixel(x, y);
          return [
            p.r.toInt().clamp(0, 255),
            p.g.toInt().clamp(0, 255),
            p.b.toInt().clamp(0, 255),
          ];
        }),
      ),
    ];

    final outLoc = List.generate(
      1,
      (_) => List.generate(25, (_) => List.filled(4, 0.0)),
    );
    final outCls = List.generate(1, (_) => List.filled(25, 0.0));
    final outScore = List.generate(1, (_) => List.filled(25, 0.0));
    final outCount = List.filled(1, 0.0);

    try {
      _interpreter!.runForMultipleInputs(
        [input],
        {0: outLoc, 1: outCls, 2: outScore, 3: outCount},
      );
    } catch (e, st) {
      debugPrint('>>> ObjectDetectorService LỖI detect: $e');
      debugPrint('$st');
      return [];
    }

    final results = <Detection>[];
    for (int i = 0; i < outCount[0].toInt(); i++) {
      final score = outScore[0][i];
      if (score < threshold) continue;
      final box = outLoc[0][i];
      final labelIdx = outCls[0][i].toInt();
      if (labelIdx < 0 || labelIdx >= _labels.length) continue;
      results.add(
        Detection(
          label: _labels[labelIdx],
          confidence: score,
          ymin: box[0],
          xmin: box[1],
          ymax: box[2],
          xmax: box[3],
        ),
      );
    }
    return results;
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
