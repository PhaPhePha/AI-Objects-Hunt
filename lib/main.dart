import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  // Bắt buộc trước khi gọi bất kỳ plugin native nào (camera, v.v.)
  WidgetsFlutterBinding.ensureInitialized();

  // Lấy danh sách camera có sẵn trên thiết bị
  cameras = await availableCameras();

  runApp(const MyApp());
}

// Check if any camera is available
bool hasCamera() {
  return cameras.isNotEmpty;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Nếu thiết bị không có camera, hiển thị màn hình thay thế
    if (!hasCamera()) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Objects Hunt',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
        ),
        home: const Scaffold(
          body: Center(
            child: Text(
              'Không có camera trên thiết bị này',
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