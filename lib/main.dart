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

class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
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