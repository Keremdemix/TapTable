import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import '../application/menu_providers.dart';
import '../data/menu_models.dart';

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
    bool imageUploading = false;

    final apiClient = ref.read(apiClientProvider);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // ── Resim yükleme fonksiyonu ──────────────────────────────────
          Future<void> pickAndUpload() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: ImageSource.gallery,
              maxWidth: 1200,
              maxHeight: 1200,
              imageQuality: 90,
            );
            if (picked == null) return;

            setDialogState(() => imageUploading = true);
            try {
              final url = await apiClient.uploadImage(picked.path);
              setDialogState(() => uploadedImageUrl = url);
            } on ApiException catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(SnackBar(content: Text('Yükleme başarısız: ${e.message}')));
              }
            } catch (e) {
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(SnackBar(content: Text('Yükleme başarısız: $e')));
              }
            } finally {
              setDialogState(() => imageUploading = false);
            }
          }

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
                      value: selectedCategoryId,
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

                    if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty)
                      // Yüklü görsel varsa göster
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: uploadedImageUrl!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                height: 160,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 160,
                                color: Colors.grey.shade200,
                                child: const Center(
                                    child: Icon(Icons.broken_image, size: 40)),
                              ),
                            ),
                          ),
                          // Kaldır butonu
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () => setDialogState(() => uploadedImageUrl = null),
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
                          // Değiştir butonu
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: imageUploading ? null : pickAndUpload,
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
                          ),
                        ],
                      )
                    else
                      // Görsel yok — yükleme alanı
                      GestureDetector(
                        onTap: imageUploading ? null : pickAndUpload,
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
                        final sortOrder =
                            int.tryParse(sortController.text) ?? 0;

                        if (name.isEmpty || price == null) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Ürün adı ve geçerli bir fiyat girin.')),
                          );
                          return;
                        }

                        final desc = descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim();
                        final imgUrl = (uploadedImageUrl?.isEmpty ?? true)
                            ? null
                            : uploadedImageUrl;

                        try {
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
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } on ApiException catch (e) {
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(e.message)));
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
                          // Görsel varsa thumbnail olarak göster
                          leading: item.imageUrl != null &&
                                  item.imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: item.imageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                          child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2))),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.broken_image,
                                          size: 20),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.fastfood,
                                      color: Colors.grey.shade400),
                                ),

                          // Stok switch'i
                          title: Text(item.name),
                          subtitle: Text(
                              '${item.categoryName}  •  ₺${item.price.toStringAsFixed(2)}'
                              '${item.isActive ? '' : '  •  Pasif'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Stok durumu switch
                              Switch(
                                value: item.isAvailable,
                                onChanged: (val) =>
                                    _toggleAvailability(item, val),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showForm(context, existing: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _confirmDelete(item),
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
          ),
        ],
      ),
    );
  }
}