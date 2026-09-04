# ai_objects_hunt

A Flutter mobile application for object detection using TensorFlow Lite, with camera capture and photo gallery functionality.

## Overview

**AI Objects Hunt** is a mobile app that captures photos using the device camera and runs real-time object detection using the EfficientDet-Lite0 model. Users can capture images, view detected objects with bounding boxes, and save annotated photos to their gallery.

The app includes:
- Camera integration with flash mode support
- TensorFlow Lite object detection (EfficientDet-Lite0)
- Auto-letterbox resizing for model input
- Photo gallery with delete functionality
- Model loading status indicator

## Features

| Feature | Description |
|---------|-------------|
| **Camera Capture** | Take photos using the device's rear camera with flash control |
| **Object Detection** | Detect objects using TensorFlow Lite EfficientDet-Lite0 model |
| **Annotated Preview** | View detection results with bounding boxes overlaying the camera preview |
| **Save Photos** | Save captured images with detection data (labels, confidence scores, bounding boxes) |
| **Photo Gallery** | Browse all captured photos, view full-screen, and delete unwanted images |
| **Flash Mode** | Toggle between flash off/torch modes |
| **Model Loading** | Visual indication when the AI model is loading or if errors occur |

## Prerequisites

- Flutter SDK (^3.13.0)
- Android Studio / Xcode for mobile development
- A device with a camera (the app requires camera access)


## Project Structure

```
ai_objects_hunt/
├── android/           # Android-specific configuration
├── assets/            # Static assets (TFLite model and labels)
│   ├── efficientdet_lite0.tflite  # Object detection model
│   └── labels.txt                   # Class labels for detection
├── .dart_tool/        # Build tooling
├── .flutter-plugins-dependencies/  # Flutter plugin configs
├── lib/               # Dart source code
│   ├── main.dart                          # App entry point
│   ├── models/                            # Data models
│   │   └── detection.dart                 # Detection result model
│   ├── screens/                           # UI screens
│   │   ├── home_screen.dart               # Main camera screen
│   │   ├── camera_screen.dart             # Camera with detection
│   │   └── photo_gallery_screen.dart      # Photo gallery
│   ├── services/                          # Business logic
│   │   ├── object_detector_service.dart   # TFLite inference
│   │   └── photo_storage_service.dart     # Photo saving logic
│   └── widgets/                           # Reusable widgets
│       ├── capture_controls.dart          # Camera controls UI
│       └── detection_painter.dart         # Custom painter for bounding boxes
├── test/            # Test files
├── pubspec.yaml     # Dependencies and assets configuration
└── README.md        # This file
```

## Dependencies

Key dependencies from `pubspec.yaml`:

| Package | Purpose |
|---------|---------|
| `camera` | Camera access and preview |
| `tflite_flutter` | TensorFlow Lite inference |
| `image` | Image processing (letterbox resize, pixel access) |
| `path_provider` | Access application documents directory |

## Configuration

### Assets

The app uses two assets from the `assets/` directory:

- `assets/models/efficientdet_lite0.tflite` - TFLite model file
- `assets/models/labels.txt` - Label definitions

These are declared in `pubspec.yaml` under the `flutter/assets` section.

### Model Input

The EfficientDet-Lite0 model expects:
- Input size: 320x320 pixels
- Letterbox resizing maintains aspect ratio with padding
- RGB channel order

The service handles letterbox scale and offset calculations to map detections back to the original image coordinates.

## Usage

1. **Launch the app** - The camera will initialize (may take a moment for model loading)
2. **Grant camera permissions** when prompted by the system
3. **Take a photo** - Tap the "Chụp ảnh" (Capture) button
4. **View results** - Detection results appear as bounding boxes with labels and confidence scores
5. **Save the photo** - Tap "Lưu ảnh" to save with detection data
6. **View gallery** - Tap "Xem ảnh đã lưu" to browse all captured photos
7. **Toggle flash** - Use the flash icon to turn the torch on/off

## Development

### Adding New Features

- **New model**: Place the .tflite file in `assets/models/` and update `labels.txt`
- **Camera settings**: Modify `capture_controls.dart` 
- **Detection threshold**: Adjust `_confidenceThreshold` in `camera_screen.dart` (currently 0.48)
- **Output format**: Update `object_detector_service.dart` `detect()` method

## License

This project is open source. See the repository for license details.