import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../application/iyzico_connect_providers.dart';
import '../data/iyzico_connect_models.dart';

class AdminIyzicoConnectScreen extends ConsumerWidget {
  const AdminIyzicoConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(iyzicoSubMerchantStatusProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Ayarları')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(iyzicoSubMerchantStatusProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            statusAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Durum alınamadı: $err'),
                ),
              ),
              data: (status) => _StatusCard(status: status),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const _SubMerchantFormScreen(),
                ),
              ),
              icon: const Icon(Icons.business),
              label: Text(
                statusAsync.value?.hasSubMerchant == true
                    ? 'Bilgileri Güncelle'
                    : 'iyzico ile Bağlan',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(iyzicoSubMerchantStatusProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Durumu Yenile'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Online ödeme (iyzico) almak için restoranınızın vergi ve banka bilgilerini '
              'tek seferlik kaydetmeniz gerekiyor. Bilgiler iyzico tarafından doğrulanana '
              'kadar müşterileriniz sadece nakit/kart (garson üzerinden) ödeme yapabilir.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Durum kartı ----------

class _StatusCard extends StatelessWidget {
  final IyzicoSubMerchantStatusDto status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      IyzicoSubMerchantStatusDto(isApproved: true) =>
        ('Online ödeme almaya hazır', Colors.green, Icons.check_circle),
      IyzicoSubMerchantStatusDto(hasSubMerchant: true) =>
        ('iyzico inceliyor, az kaldı', Colors.orange, Icons.hourglass_top),
      _ => ('Henüz bağlanmadı', Colors.grey, Icons.radio_button_unchecked),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Hesap oluşturuldu: ${status.hasSubMerchant ? 'Evet' : 'Hayır'}'),
                  Text('Onaylandı: ${status.isApproved ? 'Evet' : 'Hayır'}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Kayıt formu ----------

class _SubMerchantFormScreen extends ConsumerStatefulWidget {
  const _SubMerchantFormScreen();

  @override
  ConsumerState<_SubMerchantFormScreen> createState() => _SubMerchantFormScreenState();
}

class _SubMerchantFormScreenState extends ConsumerState<_SubMerchantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _contactName      = TextEditingController();
  final _contactSurname   = TextEditingController();
  final _email            = TextEditingController();
  final _gsm              = TextEditingController();
  final _iban             = TextEditingController();
  final _legalTitle       = TextEditingController();
  final _taxOffice        = TextEditingController();
  final _taxNumber        = TextEditingController();
  final _address          = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _contactName, _contactSurname, _email, _gsm,
      _iban, _legalTitle, _taxOffice, _taxNumber, _address,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final dto = RegisterSubMerchantRequestDto(
        contactName: _contactName.text.trim(),
        contactSurname: _contactSurname.text.trim(),
        email: _email.text.trim(),
        gsmNumber: _gsm.text.trim(),
        iban: _iban.text.trim().replaceAll(' ', ''),
        legalCompanyTitle: _legalTitle.text.trim(),
        taxOffice: _taxOffice.text.trim(),
        taxNumber: _taxNumber.text.trim(),
        address: _address.text.trim(),
      );

      await ref.read(iyzicoConnectRepositoryProvider).register(dto);
      ref.invalidate(iyzicoSubMerchantStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı! iyzico incelemeye aldı.')),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iyzico Kayıt')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_contactName,   'Yetkili Adı',          required: true),
            _field(_contactSurname,'Yetkili Soyadı',        required: true),
            _field(_email,         'E-posta',               keyboard: TextInputType.emailAddress, required: true),
            _field(_gsm,           'GSM (+905xxxxxxxxx)',   keyboard: TextInputType.phone, required: true),
            _field(_iban,          'IBAN (TR...)',          required: true),
            _field(_legalTitle,    'Şirket Ünvanı',         required: true),
            _field(_taxOffice,     'Vergi Dairesi',         required: true),
            _field(_taxNumber,     'Vergi Numarası',        keyboard: TextInputType.number, required: true),
            _field(_address,       'Adres',                 maxLines: 3, required: true),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label zorunlu' : null
              : null,
        ),
      );
}