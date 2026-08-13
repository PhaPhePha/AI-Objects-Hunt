import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<File> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${appDir.path}/captured_photos');

      if (!await savedDir.exists()) {
        setState(() {
          _photos = [];
          _isLoading = false;
        });
        return;
      }

      final files = savedDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList();

      // Ảnh mới nhất lên đầu
      files.sort((a, b) => b.path.compareTo(a.path));

      setState(() {
        _photos = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePhoto(File file) async {
    try {
      await file.delete();
      setState(() {
        _photos.remove(file);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xoá ảnh: $e')),
      );
    }
  }

  void _openFullScreen(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoView(
          file: file,
          onDelete: () {
            Navigator.of(context).pop();
            _deletePhoto(file);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Ảnh đã lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _photos.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có ảnh nào :(',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final file = _photos[index];
                    return GestureDetector(
                      onTap: () => _openFullScreen(file),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(file, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
    );
  }
}

class _FullScreenPhotoView extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;

  const _FullScreenPhotoView({required this.file, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: onDelete,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }
}