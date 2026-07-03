import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tap_table_staff/features/auth/application/current_user_providers.dart';
import 'package:tap_table_staff/features/menu/presentation/widgets/crop_dialog.dart';
import '../../../core/network/api_exception.dart';
import '../application/branding_providers.dart';

Color hexToColor(String hex) {
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}

class MenuDesignSettingsScreen extends ConsumerStatefulWidget {
  const MenuDesignSettingsScreen({super.key});

  @override
  ConsumerState<MenuDesignSettingsScreen> createState() =>
      _MenuDesignSettingsScreenState();
}

class _MenuDesignSettingsScreenState
    extends ConsumerState<MenuDesignSettingsScreen> {
  Color? _primaryColor;
  Color? _accentColor;
  Uint8List? _pendingLogoBytes;
  bool _removeLogo = false;
  bool _saving = false;
  bool _initialized = false;

  void _initFromBranding(String primaryHex, String accentHex) {
    if (_initialized) return;
    _primaryColor = hexToColor(primaryHex);
    _accentColor = hexToColor(accentHex);
    _initialized = true;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    final cropped = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CropDialog(imageBytes: bytes, aspectRatio: 1),
    );

    if (cropped == null) return;

    setState(() {
      _pendingLogoBytes = cropped;
      _removeLogo = false;
    });
  }

  Future<void> _pickColor({
    required String title,
    required Color current,
    required void Function(Color) onSelected,
  }) async {
    Color picked = current;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: current,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              onSelected(picked);
              Navigator.pop(dialogContext);
            },
            child: const Text('Seç'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(String? existingLogoUrl) async {
    if (_primaryColor == null || _accentColor == null) return;

    setState(() => _saving = true);

    try {
      final restaurantId = await ref.read(currentRestaurantIdProvider.future);
      final repository = ref.read(brandingRepositoryProvider);

      await repository.updateBranding(
        restaurantId: restaurantId,
        primaryColorHex: colorToHex(_primaryColor!),
        accentColorHex: colorToHex(_accentColor!),
        logoBytes: _pendingLogoBytes,
        logoFileName: _pendingLogoBytes != null
            ? 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : null,
        removeLogo: _removeLogo,
      );

      ref.invalidate(brandingProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tasarım ayarları kaydedildi.')),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandingAsync = ref.watch(brandingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Menü Tasarım Ayarları')),
      body: brandingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Hata: $err')),
        data: (branding) {
          _initFromBranding(branding.primaryColorHex, branding.accentColorHex);

          final hasLogo = !_removeLogo &&
              (_pendingLogoBytes != null ||
                  (branding.logoUrl != null && branding.logoUrl!.isNotEmpty));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Restoran Logosu',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 10),

                if (hasLogo)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: _pendingLogoBytes != null
                              ? Image.memory(_pendingLogoBytes!, fit: BoxFit.cover)
                              : CachedNetworkImage(
                                  imageUrl: branding.logoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _pendingLogoBytes = null;
                            _removeLogo = true;
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text('Logo Ekle',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),

                if (hasLogo) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickLogo,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Logoyu Değiştir'),
                  ),
                ],

                const SizedBox(height: 28),

                const Text('Renkler',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 10),

                _ColorRow(
                  label: 'Ana Renk',
                  sublabel: 'AppBar, butonlar, seçili sekme',
                  color: _primaryColor!,
                  onTap: () => _pickColor(
                    title: 'Ana Rengi Seç',
                    current: _primaryColor!,
                    onSelected: (c) => setState(() => _primaryColor = c),
                  ),
                ),
                const SizedBox(height: 12),
                _ColorRow(
                  label: 'Vurgu Rengi',
                  sublabel: 'Sepete ekle butonu, fiyat vurgusu',
                  color: _accentColor!,
                  onTap: () => _pickColor(
                    title: 'Vurgu Rengini Seç',
                    current: _accentColor!,
                    onSelected: (c) => setState(() => _accentColor = c),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _save(branding.logoUrl),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Kaydet'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ColorRow({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(sublabel,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}