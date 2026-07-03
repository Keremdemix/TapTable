import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class CropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final double aspectRatio;

  const CropDialog({
    super.key,
    required this.imageBytes,
    this.aspectRatio = 1.2,
  });

  @override
  State<CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<CropDialog> {
  final _controller = CropController();
  Uint8List? _croppedBytes;
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(16),
      title: const Text(
        "Fotoğrafı Kırp",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: 420,
        height: 520,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              aspectRatio: widget.aspectRatio,
              onStatusChanged: (status) {
                setState(() => _isCropping = status == CropStatus.cropping);
              },
              onCropped: (CropResult result) {
                if (result is CropSuccess) {
                  setState(() => _croppedBytes = result.croppedImage);
                } else if (result is CropFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kırpma başarısız: ${result.cause}'),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        TextButton(
          onPressed: _isCropping ? null : () => _controller.crop(),
          child: const Text("Kırp"),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.greenAccent.shade700,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _croppedBytes == null
              ? null
              : () => Navigator.pop(context, _croppedBytes),
          child: const Text("Onayla"),
        ),
      ],
    );
  }
}