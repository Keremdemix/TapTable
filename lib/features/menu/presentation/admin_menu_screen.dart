import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tap_table_staff/features/menu/presentation/widgets/crop_dialog.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../application/menu_providers.dart';
import '../data/menu_models.dart';
import 'package:http/http.dart' as http;

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menü'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Kategoriler'), Tab(text: 'Ürünler')],
          ),
        ),
        body: const TabBarView(
          children: [_CategoriesTab(), _ItemsTab()],
        ),
      ),
    );
  }
}

/* ════════════════════════════ KATEGORİLER ════════════════════════════ */

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref, {
    CategoryResponseDto? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final sortController =
        TextEditingController(text: existing?.sortOrder.toString() ?? '0');
    bool isActive = existing?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(existing == null ? 'Yeni Kategori' : 'Kategoriyi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Kategori Adı'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sortController,
                decoration: const InputDecoration(labelText: 'Sıra'),
                keyboardType: TextInputType.number,
              ),
              if (existing != null) ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final sortOrder = int.tryParse(sortController.text) ?? 0;
                if (name.isEmpty) return;

                try {
                  final repository = ref.read(menuRepositoryProvider);
                  if (existing == null) {
                    await repository.createCategory(
                        name: name, sortOrder: sortOrder);
                  } else {
                    await repository.updateCategory(
                      id: existing.id,
                      name: name,
                      sortOrder: sortOrder,
                      isActive: isActive,
                    );
                  }
                  ref.invalidate(categoriesProvider);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on ApiException catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryResponseDto category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text('"${category.name}" silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(menuRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(categoriesProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(categoriesProvider),
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Hata: $err')),
          data: (categories) {
            if (categories.isEmpty) {
              return const Center(child: Text('Henüz kategori eklenmedi.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(category.name),
                    subtitle: Text(
                        '${category.menuItemCount} ürün'
                        '${category.isActive ? '' : '  •  Pasif'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showForm(context, ref, existing: category),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, ref, category),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/* ═════════════════════════════ ÜRÜNLER ═══════════════════════════════ */

class _ItemsTab extends ConsumerStatefulWidget {
  const _ItemsTab();

  @override
  ConsumerState<_ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends ConsumerState<_ItemsTab> {
  int? _selectedCategoryId;

  Future<void> _showForm(BuildContext context, {MenuItemResponseDto? existing}) async {
    final categories = await ref.read(menuRepositoryProvider).getCategories();
    if (categories.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce en az bir kategori eklemelisiniz.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // Form state değişkenleri — StatefulBuilder içinde setState ile güncellenir
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descController = TextEditingController(text: existing?.description ?? '');
    final priceController = TextEditingController(text: existing?.price.toString() ?? '');
    final sortController = TextEditingController(text: existing?.sortOrder.toString() ?? '0');
    int selectedCategoryId = existing?.categoryId ?? categories.first.id;
    bool isAvailable = existing?.isAvailable ?? true;
    bool isActive = existing?.isActive ?? true;
    String? uploadedImageUrl = existing?.imageUrl;
    Uint8List? pendingImageBytes; // henüz upload edilmemiş, kaydet anında yüklenecek
    bool imageUploading = false; // sadece kırpma/indirme için loading; asıl upload Kaydet'te

    final apiClient = ref.read(apiClientProvider);
    // Dialog açıldığındaki orijinal görsel — Kaydet'te değiştirildi/kaldırıldı mı
    // diye kıyaslamak ve eskisini Cloudinary'den silmek için saklanıyor.
    final originalImageUrl = existing?.imageUrl;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // ── Galeriden yeni resim seç + kırp (upload ETMEZ) ──────────────
          Future<void> pickAndCrop() async {
            final picker = ImagePicker();

            final picked = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 95,
            );

            if (picked == null) return;

            setDialogState(() => imageUploading = true);

            try {
              final bytes = await picked.readAsBytes();

              final croppedBytes = await showDialog<Uint8List>(
                context: context,
                barrierDismissible: false,
                builder: (_) => CropDialog(imageBytes: bytes),
              );

              if (croppedBytes == null) {
                setDialogState(() => imageUploading = false);
                return;
              }

              // Upload YOK — sadece local'de tutuluyor, Kaydet'e basınca yüklenecek
              setDialogState(() {
                pendingImageBytes = croppedBytes;
                imageUploading = false;
              });
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Görsel işlenemedi: $e')),
                );
              }
              setDialogState(() => imageUploading = false);
            }
          }

          // ── Mevcut görseli (bekleyen ya da yüklü) tekrar kırp ───────────
          Future<void> reEditImage() async {
            setDialogState(() => imageUploading = true);

            try {
              Uint8List bytes;

              if (pendingImageBytes != null) {
                // Henüz upload edilmemiş görseli tekrar kırp
                bytes = pendingImageBytes!;
              } else if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty) {
                // Sunucudaki mevcut görseli indir
                final response = await http.get(Uri.parse(uploadedImageUrl!));
                if (response.statusCode != 200) {
                  throw Exception('Görsel indirilemedi (${response.statusCode})');
                }
                bytes = response.bodyBytes;
              } else {
                setDialogState(() => imageUploading = false);
                return;
              }

              final croppedBytes = await showDialog<Uint8List>(
                context: context,
                barrierDismissible: false,
                builder: (_) => CropDialog(imageBytes: bytes),
              );

              if (croppedBytes == null) {
                setDialogState(() => imageUploading = false);
                return;
              }

              setDialogState(() {
                pendingImageBytes = croppedBytes; // upload YOK, Kaydet'i bekliyor
                imageUploading = false;
              });
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Düzenleme başarısız: $e')),
                );
              }
              setDialogState(() => imageUploading = false);
            }
          }

          final hasImage = pendingImageBytes != null ||
              (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty);

          // ── Dialog içeriği ────────────────────────────────────────────
          return AlertDialog(
            title: Text(existing == null ? 'Yeni Ürün' : 'Ürünü Düzenle'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori seçimi
                    DropdownButtonFormField<int>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categories
                          .map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) => setDialogState(
                          () => selectedCategoryId = val ?? selectedCategoryId),
                    ),
                    const SizedBox(height: 12),

                    // Ürün adı
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Ürün Adı'),
                    ),
                    const SizedBox(height: 12),

                    // Açıklama
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                          labelText: 'Açıklama (opsiyonel)'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // Fiyat
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),

                    // Sıra
                    TextField(
                      controller: sortController,
                      decoration: const InputDecoration(labelText: 'Sıra'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // ── Görsel alanı ──────────────────────────────────
                    const Text('Ürün Görseli',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                    const SizedBox(height: 8),

                    if (hasImage)
                      // Görsel varsa (bekleyen ya da yüklü) göster
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: pendingImageBytes != null
                                  ? Image.memory(
                                      pendingImageBytes!,
                                      fit: BoxFit.cover,
                                    )
                                  : CachedNetworkImage(
                                      imageUrl: uploadedImageUrl!,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    ),
                            ),
                          ),
                          // Kaldır butonu
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setDialogState(() {
                                uploadedImageUrl = null;
                                pendingImageBytes = null;
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          // Sağ alt butonlar: Düzenle + Değiştir
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Düzenle (mevcut görseli tekrar kırp)
                                GestureDetector(
                                  onTap: imageUploading ? null : reEditImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (imageUploading)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white),
                                          )
                                        else
                                          const Icon(Icons.crop,
                                              color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        const Text('Düzenle',
                                            style: TextStyle(
                                                color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Değiştir (yeni görsel seç)
                                GestureDetector(
                                  onTap: imageUploading ? null : pickAndCrop,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (imageUploading)
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white),
                                          )
                                        else
                                          const Icon(Icons.swap_horiz,
                                              color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        const Text('Değiştir',
                                            style: TextStyle(
                                                color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Görsel yok — yükleme alanı
                      GestureDetector(
                        onTap: imageUploading ? null : pickAndCrop,
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: imageUploading
                              ? const Center(child: CircularProgressIndicator())
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        size: 40, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Galeriden Görsel Seç',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13)),
                                  ],
                                ),
                        ),
                      ),

                    // Düzenleme modunda ek switch'ler
                    if (existing != null) ...[
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Stokta / Mevcut'),
                        value: isAvailable,
                        onChanged: (val) =>
                            setDialogState(() => isAvailable = val),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Aktif'),
                        value: isActive,
                        onChanged: (val) => setDialogState(() => isActive = val),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: imageUploading
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: imageUploading
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final priceText =
                            priceController.text.trim().replaceAll(',', '.');
                        final price = double.tryParse(priceText);
                        final sortOrder = int.tryParse(sortController.text) ?? 0;

                        if (name.isEmpty || price == null) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text('Ürün adı ve geçerli bir fiyat girin.')),
                          );
                          return;
                        }

                        final desc = descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim();

                        try {
                          // ── Görsel varsa şimdi upload et ──────────────────────
                          String? finalImageUrl = uploadedImageUrl;

                          if (pendingImageBytes != null) {
                            setDialogState(() => imageUploading = true);
                            final fileName =
                                'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
                            finalImageUrl = await apiClient.uploadImage(
                                pendingImageBytes!, fileName);
                            setDialogState(() => imageUploading = false);
                          }

                          final imgUrl =
                              (finalImageUrl?.isEmpty ?? true) ? null : finalImageUrl;

                          final repository = ref.read(menuRepositoryProvider);
                          if (existing == null) {
                            await repository.createItem(
                              categoryId: selectedCategoryId,
                              name: name,
                              description: desc,
                              price: price,
                              imageUrl: imgUrl,
                              sortOrder: sortOrder,
                            );
                          } else {
                            await repository.updateItem(
                              id: existing.id,
                              categoryId: selectedCategoryId,
                              name: name,
                              description: desc,
                              price: price,
                              imageUrl: imgUrl,
                              sortOrder: sortOrder,
                              isAvailable: isAvailable,
                              isActive: isActive,
                            );
                          }
                          ref.invalidate(menuItemsProvider);
                          ref.invalidate(categoriesProvider);

                          // Eski görsel değiştirildiyse ya da kaldırıldıysa
                          // Cloudinary'deki eski dosyayı sil (fire-and-forget).
                          if (originalImageUrl != null &&
                              originalImageUrl.isNotEmpty &&
                              originalImageUrl != imgUrl) {
                            apiClient.deleteImage(originalImageUrl).catchError((_) {
                              // Silme başarısız olsa bile kullanıcı akışını bozma
                            });
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } on ApiException catch (e) {
                          setDialogState(() => imageUploading = false);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(SnackBar(content: Text(e.message)));
                          }
                        }
                      },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(MenuItemResponseDto item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('"${item.name}" silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(menuRepositoryProvider).deleteItem(item.id);
      ref.invalidate(menuItemsProvider);
      ref.invalidate(categoriesProvider);

      // Ürünle birlikte görseli de Cloudinary'den temizle (fire-and-forget).
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
        ref.read(apiClientProvider).deleteImage(item.imageUrl!).catchError((_) {
          // Görsel silinemese bile ürün silme işlemi tamamlandı sayılır
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _toggleAvailability(MenuItemResponseDto item, bool value) async {
    try {
      await ref
          .read(menuRepositoryProvider)
          .setAvailability(id: item.id, isAvailable: value);
      ref.invalidate(menuItemsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(menuItemsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Kategori filtre çipleri
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: const Text('Tümü'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = null),
                    ),
                  ),
                  ...categories.map((c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: _selectedCategoryId == c.id,
                          onSelected: (_) =>
                              setState(() => _selectedCategoryId = c.id),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Ürün listesi
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(menuItemsProvider),
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Hata: $err')),
                data: (items) {
                  final filtered = _selectedCategoryId == null
                      ? items
                      : items
                          .where((i) => i.categoryId == _selectedCategoryId)
                          .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('Ürün bulunamadı.'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                        // ── IMAGE ─────────────────────────────────────────────
                        leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: 1.2,
                                  child: CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image, size: 20),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.fastfood,
                                  color: Colors.grey.shade400,
                                ),
                              ),

                        // ── TITLE ─────────────────────────────────────────────
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // ── SUBTITLE ──────────────────────────────────────────
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${item.categoryName}  •  ₺${item.price.toStringAsFixed(2)}'
                            '${item.isActive ? '' : '  •  Pasif'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // ── ACTIONS ───────────────────────────────────────────
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: item.isAvailable,
                              onChanged: (val) => _toggleAvailability(item, val),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showForm(context, existing: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(item),
                            ),
                          ],
                        ),
                      ),
                    );                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}