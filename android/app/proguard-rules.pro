# ===================================================================
# 1. QUY TẮC DÀNH CHO FLUTTER
# ===================================================================
# Giữ lại các class core của Flutter để không bị xóa khi làm rối code
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# ===================================================================
# 2. QUY TẮC DÀNH CHO TENSORFLOW LITE (Tránh lỗi R8 missing classes)
# ===================================================================
# Giữ lại toàn bộ class và method của TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Giữ lại các class GPU Delegate của TFLite
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# ===================================================================
# 3. BỎ QUA CÁC CẢNH BÁO KHÔNG CẦN THIẾT
# ===================================================================
# Bỏ qua các warning liên quan đến thư viện native C/C++ (.so) hoặc thiếu class phụ
-dontwarn **