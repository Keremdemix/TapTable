import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerField extends StatefulWidget {
  final String? initialUrl;
  final void Function(String url) onUploaded;

  /// Web + mobile uyumlu: bytes + filename almalı
  final Future<String> Function(Uint8List bytes, String fileName) uploadFn;

  const ImagePickerField({
    super.key,
    this.initialUrl,
    required this.onUploaded,
    required this.uploadFn,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  String? _currentUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
  }

  Future<void> _pick() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (picked == null) return;

    /// 1. CROPPER (mobile + web fallback destekli)
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Görseli Düzenle',
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Görseli Düzenle',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (cropped == null) return;

    setState(() => _uploading = true);

    try {
      final bytes = await cropped.readAsBytes();
      final fileName = picked.name;

      final url = await widget.uploadFn(bytes, fileName);

      setState(() => _currentUrl = url);
      widget.onUploaded(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yükleme başarısız: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _remove() {
    setState(() => _currentUrl = null);
    widget.onUploaded('');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ürün Görseli',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        if (_currentUrl != null && _currentUrl!.isNotEmpty) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _currentUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox(
                    height: 160,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        size: 14, color: Colors.white),
                    onPressed: _remove,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pick,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Görseli Değiştir'),
          ),
        ] else ...[
          GestureDetector(
            onTap: _uploading ? null : _pick,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _uploading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Görsel Ekle',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}