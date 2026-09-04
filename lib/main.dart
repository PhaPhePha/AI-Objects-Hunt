import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ai_objects_hunt/language_state.dart';
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

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String? cameraInitializationError;

  const MyApp({
    super.key,
    required this.cameras,
    this.cameraInitializationError,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late LanguageNotifier _lang;

  @override
  void initState() {
    super.initState();

    _lang = LanguageNotifier();

    // Khi ngôn ngữ thay đổi -> MyApp rebuild
    _lang.addListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _lang.removeListener(_onLanguageChanged);
    _lang.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Objects Hunt',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: HomeScreen(
        cameras: widget.cameras,
        isEnglish: _lang.isEnglish,
        onToggleLanguage: _lang.toggle,
      ),
    );
  }
}