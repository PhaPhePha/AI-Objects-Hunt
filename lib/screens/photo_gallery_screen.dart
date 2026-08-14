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

  Future<bool> _deletePhoto(File file) async {
    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá ảnh'),
        content: const Text('Bạn chắc chắn muốn xoá ảnh này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return false;

    try {
      await file.delete();
      setState(() {
        _photos.remove(file);
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi khi xoá ảnh: $e')));
      return false;
    }
  }

  void _openFullScreen(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenPhotoView(
          photos: _photos,
          initialIndex: initialIndex,
          onDelete: _deletePhoto,
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
        title: const Text(
          'Ảnh đã lưu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
          : Column(
              children: [
                // Header with refresh button and photo count
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_photos.length} ảnh',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white54),
                        onPressed: _loadPhotos,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final file = _photos[index];
                      return GestureDetector(
                        key: ValueKey(file.path),
                        onTap: () => _openFullScreen(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            file,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: Colors.white10,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FullScreenPhotoView extends StatefulWidget {
  final List<File> photos;
  final int initialIndex;
  final Future<bool> Function(File) onDelete;

  const _FullScreenPhotoView({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_FullScreenPhotoView> createState() => _FullScreenPhotoViewState();
}

class _FullScreenPhotoViewState extends State<_FullScreenPhotoView> {
  late final PageController _pageController;
  late final List<File> _photos;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _photos = List.of(widget.photos);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteCurrentPhoto() async {
    final file = _photos[_currentIndex];
    final wasDeleted = await widget.onDelete(file);
    if (!mounted || !wasDeleted) return;

    if (_photos.length == 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _photos.removeAt(_currentIndex);
      if (_currentIndex >= _photos.length) _currentIndex = _photos.length - 1;
    });
    _pageController.jumpToPage(_currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteCurrentPhoto,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) => Center(
          child: InteractiveViewer(
            child: Image.file(_photos[index], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
