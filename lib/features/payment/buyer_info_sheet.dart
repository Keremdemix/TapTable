import 'package:flutter/material.dart';

class BuyerInfo {
  final String name;
  final String surname;
  final String gsmNumber;
  final String? email;

  BuyerInfo({
    required this.name,
    required this.surname,
    required this.gsmNumber,
    this.email,
  });
}

Future<BuyerInfo?> showBuyerInfoSheet(BuildContext context, Color accent) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final surnameCtrl = TextEditingController();
  final gsmCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  return showModalBottomSheet<BuyerInfo>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ödeme Bilgileri',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: surnameCtrl,
                decoration: const InputDecoration(labelText: 'Soyad'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: gsmCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefon (05XX...)',
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Geçerli bir numara girin'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta (opsiyonel)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(
                    context,
                    BuyerInfo(
                      name: nameCtrl.text.trim(),
                      surname: surnameCtrl.text.trim(),
                      gsmNumber: gsmCtrl.text.trim(),
                      email: emailCtrl.text.trim().isEmpty
                          ? null
                          : emailCtrl.text.trim(),
                    ),
                  );
                },
                child: const Text('Ödemeye Geç'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
