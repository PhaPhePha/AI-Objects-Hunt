import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  // Bắt buộc trước khi gọi bất kỳ plugin native nào (camera, v.v.)
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = const [];
  String? cameraInitializationError;
  try {
    cameras = await availableCameras();
  } on CameraException catch (error) {
    cameraInitializationError = _cameraErrorMessage(error);
  } catch (_) {
    cameraInitializationError = 'Không thể tìm thấy camera. Vui lòng thử lại.';
  }

  runApp(
    MyApp(
      cameras: cameras,
      cameraInitializationError: cameraInitializationError,
    ),
  );
}

String _cameraErrorMessage(CameraException error) {
  switch (error.code) {
    case 'CameraAccessDenied':
    case 'CameraAccessDeniedWithoutPrompt':
    case 'CameraAccessRestricted':
      return 'Ứng dụng chưa được cấp quyền dùng camera. Hãy cấp quyền trong Cài đặt rồi mở lại ứng dụng.';
    case 'CameraNotFound':
      return 'Không tìm thấy camera trên thiết bị này.';
    default:
      return 'Không thể khởi tạo camera. Vui lòng thử lại.';
  }
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  final String? cameraInitializationError;

  const MyApp({
    super.key,
    this.cameras = const [],
    this.cameraInitializationError,
  });

  @override
  Widget build(BuildContext context) {
    if (cameras.isEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Objects Hunt',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: Scaffold(
          body: Center(
            child: Text(
              cameraInitializationError ?? 'Không có camera trên thiết bị này',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Objects Hunt',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: HomeScreen(cameras: cameras),
    );
  }
}
