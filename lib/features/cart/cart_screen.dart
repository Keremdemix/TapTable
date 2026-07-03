import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final lines = cart.values.toList();
    final total = ref.watch(cartTotalProvider);
    final accent = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(title: const Text('Sepetim')),
      body: lines.isEmpty
          ? const Center(child: Text('Sepetiniz boş.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (line.item.imageUrl != null && line.item.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: line.item.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.item.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              '₺${line.item.price.toStringAsFixed(2)} x ${line.quantity}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                              onPressed: () =>
                                  ref.read(cartProvider.notifier).decrement(line.item.id),
                            ),
                            Text('${line.quantity}',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700)),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16, color: Colors.white),
                              onPressed: () =>
                                  ref.read(cartProvider.notifier).add(line.item),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Toplam', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('₺${total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          // sonraki adım: sipariş gönderme (PublicOrderController.PlaceOrder)
                        },
                        child: const Text('Siparişi Onayla'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}