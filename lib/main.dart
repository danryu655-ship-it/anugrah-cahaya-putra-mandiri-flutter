import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data/products.dart';
import 'services/acpm_supabase.dart';
import 'services/admin_auth.dart';

void main() => runApp(const AnugrahCahayaApp());

const String defaultWaNumber = '6281234567890';
const String waWarning =
    'Nomor WA di web terlihat seperti nomor contoh — ganti dengan nomor WA asli sebelum APK dibagikan ke pelanggan.';

String formatIDR(double v) {
  var s = v.round().toString();
  final buf = StringBuffer();
  var c = 0;
  for (var i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    c++;
    if (c % 3 == 0 && i != 0) buf.write('.');
  }
  return 'Rp${buf.toString().split('').reversed.join()}';
}

String priceText(double? price) =>
    price == null ? 'Hubungi Kami' : formatIDR(price);

IconData iconForCategory(String category) => switch (category) {
      'Paket Depot' => Icons.store,
      'Mesin RO' => Icons.water_drop,
      'Pasir & Media' => Icons.grain,
      _ => Icons.build,
    };

class CartItem {
  CartItem({required this.kind, required this.id, required this.qty});
  final String kind; // 'product' atau 'service'
  final String id;
  int qty;
  String get key => '$kind:$id';
  Map<String, dynamic> toJson() => {'kind': kind, 'id': id, 'qty': qty};
  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        kind: j['kind'] as String? ?? 'product',
        id: j['id'] as String? ?? '',
        qty: (j['qty'] as num? ?? 1).toInt(),
      );
}

Future<void> showWaDialog(
    BuildContext context, String waNumber, String message) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Pesan via WhatsApp'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nomor WA: $waNumber',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(message),
            ),
            const SizedBox(height: 8),
            const Text(priceDisclaimer,
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message));
            Navigator.pop(ctx, false);
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pesan disalin.')));
          },
          child: const Text('Salin Pesan'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.chat),
          label: const Text('Buka WhatsApp'),
        ),
      ],
    ),
  );
  if (ok == true) {
    final uri = Uri.parse(
        'https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'WhatsApp tidak bisa dibuka — pesan sudah disiapkan, silakan salin manual.')));
    }
  }
}

class AnugrahCahayaApp extends StatelessWidget {
  const AnugrahCahayaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACPM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E6BA8),
          primary: const Color(0xFF0E6BA8),
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  List<CartItem> _cart = [];
  Map<String, double?> _overrides = {};
  String _waNumber = defaultWaNumber;
  bool _loaded = false;
  // Katalog aktif: data lokal dulu, ditimpa data Supabase bila tersedia.
  List<Product> _catalog = products;
  List<ServiceItem> _serviceList = services;
  // Mode Admin: MEMORI SAJA, sengaja tidak disimpan ke SharedPreferences.
  // Tiap aplikasi ditutup lalu dibuka lagi, muncul layar login lagi.
  bool _isAdmin = false;
  // Sudah melewati layar sambutan/login? false = tampilkan layar login.
  bool _entered = false;
  // Override gambar produk oleh admin: id produk -> aset kategori / URL.
  Map<String, String> _imageOverrides = {};

  @override
  void initState() {
    super.initState();
    _load();
    _loadRemote();
  }

  // Muat dari Supabase bila dikonfigurasi; gagal/offline = tetap data lokal.
  Future<void> _loadRemote() async {
    final remoteProducts = await fetchRemoteProducts();
    final remoteServices = await fetchRemoteServices();
    if (!mounted) return;
    if (remoteProducts != null || remoteServices != null) {
      setState(() {
        if (remoteProducts != null) _catalog = remoteProducts;
        if (remoteServices != null) _serviceList = remoteServices;
      });
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final cartRaw = prefs.getString('acpm_cart');
    final ovRaw = prefs.getString('acpm_price_overrides');
    final imgRaw = prefs.getString('acpm_image_overrides');
    final wa = prefs.getString('acpm_wa_number');
    setState(() {
      if (cartRaw != null) {
        try {
          final list = jsonDecode(cartRaw) as List;
          _cart = list
              .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      if (ovRaw != null) {
        try {
          final m = jsonDecode(ovRaw) as Map<String, dynamic>;
          _overrides = {
            for (final e in m.entries) e.key: (e.value as num?)?.toDouble(),
          };
        } catch (_) {}
      }
      if (imgRaw != null) {
        try {
          final m = jsonDecode(imgRaw) as Map<String, dynamic>;
          _imageOverrides = {
            for (final e in m.entries) e.key: e.value.toString(),
          };
        } catch (_) {}
      }
      if (wa != null && wa.trim().isNotEmpty) _waNumber = wa.trim();
      _loaded = true;
    });
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'acpm_cart', jsonEncode(_cart.map((e) => e.toJson()).toList()));
  }

  Future<void> _saveOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('acpm_price_overrides', jsonEncode(_overrides));
  }

  Future<void> _saveImageOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'acpm_image_overrides', jsonEncode(_imageOverrides));
  }

  // Admin: ganti gambar produk. [value] = path aset kategori atau URL gambar.
  // null = hapus override (kembali ke gambar bawaan / foto Supabase).
  void _setImageOverride(String productId, String? value) {
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _imageOverrides.remove(productId);
      } else {
        _imageOverrides[productId] = value.trim();
      }
    });
    _saveImageOverrides();
    // Bila override berupa URL dan Supabase terkonfigurasi, kirim juga
    // ke Supabase (kolom image_url). Override aset lokal tidak dikirim.
    if (_isAdmin && value != null && value.startsWith('http')) {
      _syncImageToSupabase(productId, value);
    }
  }

  Future<void> _syncImageToSupabase(String productId, String url) async {
    if (!supabaseConfigured) return;
    final ok = await updateRemoteImage(productId, url);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Gambar tersimpan di HP ini (gagal kirim ke Supabase — periksa koneksi / login admin Supabase).')));
    }
  }

  Future<void> _saveWa(String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('acpm_wa_number', number);
  }

  double? effectivePrice(Product p) =>
      _overrides.containsKey(p.id) ? _overrides[p.id] : p.price;

  String itemName(CartItem item) {
    if (item.kind == 'service') {
      for (final s in _serviceList) {
        if (s.id == item.id) return s.name;
      }
      return findService(item.id)?.name ?? item.id;
    }
    for (final p in _catalog) {
      if (p.id == item.id) return p.name;
    }
    return findProduct(item.id)?.name ?? item.id;
  }

  double? itemPrice(CartItem item) {
    if (item.kind == 'service') return null;
    for (final p in _catalog) {
      if (p.id == item.id) return effectivePrice(p);
    }
    final p = findProduct(item.id);
    return p == null ? null : effectivePrice(p);
  }

  void _addToCart(String kind, String id) {
    setState(() {
      final i = _cart.indexWhere((e) => e.key == '$kind:$id');
      if (i >= 0) {
        _cart[i].qty++;
      } else {
        _cart.add(CartItem(kind: kind, id: id, qty: 1));
      }
    });
    _saveCart();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ditambahkan ke keranjang.')));
  }

  void _changeQty(String key, int delta) {
    setState(() {
      final i = _cart.indexWhere((e) => e.key == key);
      if (i < 0) return;
      _cart[i].qty += delta;
      if (_cart[i].qty <= 0) _cart.removeAt(i);
    });
    _saveCart();
  }

  void _removeItem(String key) {
    setState(() => _cart.removeWhere((e) => e.key == key));
    _saveCart();
  }

  void _clearCart() {
    setState(() => _cart.clear());
    _saveCart();
  }

  void _setPriceOverride(String productId, double? price) {
    setState(() => _overrides[productId] = price);
    _saveOverrides();
    // Admin + Supabase terkonfigurasi: kirim juga ke Supabase (best-effort).
    // Pelanggan tidak pernah sampai ke sini (tombol edit tidak ada).
    if (_isAdmin) _syncPriceToSupabase(productId, price);
  }

  void _resetPriceOverride(String productId) {
    setState(() => _overrides.remove(productId));
    _saveOverrides();
    if (_isAdmin) {
      double? base;
      for (final p in _catalog) {
        if (p.id == productId) base = p.price;
      }
      base ??= findProduct(productId)?.price;
      _syncPriceToSupabase(productId, base);
    }
  }

  Future<void> _syncPriceToSupabase(String productId, double? price) async {
    if (!supabaseConfigured) return;
    final ok = await updateRemotePrice(productId, price);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Harga tersimpan di HP ini (gagal kirim ke Supabase — periksa koneksi / login admin Supabase).')));
    }
  }

  void _enterAdmin() {
    showAdminPinDialog(context, onUnlocked: (_) {
      setState(() => _isAdmin = true);
    });
  }

  void _exitAdmin() {
    setState(() => _isAdmin = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keluar dari Mode Admin.')));
  }

  void _resetAllPrices() {
    setState(() => _overrides.clear());
    _saveOverrides();
  }

  void _setWaNumber(String number) {
    setState(() => _waNumber = number);
    _saveWa(number);
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          isAdmin: _isAdmin,
          waNumber: _waNumber,
          onWaChanged: _setWaNumber,
          onResetAllPrices: _resetAllPrices,
          overrideCount: _overrides.length,
          onEnterAdmin: _enterAdmin,
          onExitAdmin: _exitAdmin,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _openDetail(Product p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          product: p,
          price: effectivePrice(p),
          isOverridden: _overrides.containsKey(p.id),
          isAdmin: _isAdmin,
          imageOverride: _imageOverrides[p.id],
          waNumber: _waNumber,
          onAddToCart: () => _addToCart('product', p.id),
          onSetPrice: (v) => _setPriceOverride(p.id, v),
          onResetPrice: () => _resetPriceOverride(p.id),
          onSetImage: (v) => _setImageOverride(p.id, v),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    // Layar sambutan/login: muncul setiap kali aplikasi dibuka.
    if (!_entered) {
      return WelcomeScreen(
        onGuest: () => setState(() {
          _isAdmin = false;
          _entered = true;
        }),
        onAdminUnlocked: () => setState(() {
          _isAdmin = true;
          _entered = true;
        }),
      );
    }
    final cartCount = _cart.fold<int>(0, (a, e) => a + e.qty);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACPM'),
        backgroundColor: const Color(0xFF0E6BA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan (nomor WA & harga)',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : switch (_tab) {
              0 => CatalogScreen(
                  items: _catalog,
                  onOpenDetail: _openDetail,
                  priceOf: effectivePrice,
                ),
              1 => ServicesScreen(
                  items: _serviceList,
                  waNumber: _waNumber,
                  onAddToCart: (id) => _addToCart('service', id),
                ),
              _ => CartScreen(
                  cart: _cart,
                  nameOf: itemName,
                  priceOf: itemPrice,
                  waNumber: _waNumber,
                  onChangeQty: _changeQty,
                  onRemove: _removeItem,
                  onClear: _clearCart,
                  onOpenSettings: _openSettings,
                ),
            },
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: const Color(0xFF0E6BA8),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.store), label: 'Katalog'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.build), label: 'Jasa'),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_cart),
            label: cartCount > 0 ? 'Keranjang ($cartCount)' : 'Keranjang',
          ),
        ],
      ),
    );
  }
}

// ---------------- LAYAR SAMBUTAN / LOGIN ----------------
// Muncul setiap kali aplikasi dibuka dari kondisi tertutup.
// Tamu masuk tanpa PIN; admin masuk dengan PIN 4 digit.
// PIN salah -> "PIN salah, coba lagi", tetap di layar ini.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen(
      {super.key, required this.onGuest, required this.onAdminUnlocked});
  final VoidCallback onGuest;
  final VoidCallback onAdminUnlocked;
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pin = TextEditingController();
  String _error = '';

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _tryAdminLogin() {
    if (verifyPin(_pin.text.trim())) {
      widget.onAdminUnlocked();
    } else {
      setState(() => _error = 'PIN salah, coba lagi');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Persis mockup yang disetujui user (17 Nov 01:05 WIB):
    // logo lengkap di atas, judul ACPM, kartu Login Admin, "atau",
    // tombol Masuk sebagai Tamu, catatan kecil di bawah kartu.
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/logo_full.png', height: 150,
                  fit: BoxFit.contain),
              const SizedBox(height: 24),
              const Text('ACPM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B3D66))),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Login Admin',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B3D66))),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _pin,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        maxLength: 4,
                        decoration: InputDecoration(
                          labelText: 'Masukkan PIN Admin',
                          prefixIcon: const Icon(Icons.lock),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          counterText: '',
                        ),
                        onSubmitted: (_) => _tryAdminLogin(),
                      ),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_error,
                            style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _tryAdminLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0E6BA8),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Masuk sebagai Admin',
                            style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 16),
                      const Text('atau',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: widget.onGuest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0E6BA8),
                          side: const BorderSide(
                              color: Color(0xFF0E6BA8), width: 1.5),
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Masuk sebagai Tamu',
                            style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tamu hanya bisa melihat katalog dan memesan. '
                'Hanya admin yang bisa ubah harga, ubah gambar, '
                'dan ubah nomor WhatsApp.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- KATALOG ----------------

const List<String> categories = [
  'Semua',
  'Paket Depot',
  'Mesin RO',
  'Sparepart',
  'Pasir & Media',
];

class CatalogScreen extends StatefulWidget {
  const CatalogScreen(
      {super.key,
      required this.items,
      required this.onOpenDetail,
      required this.priceOf});
  final List<Product> items;
  final ValueChanged<Product> onOpenDetail;
  final double? Function(Product) priceOf;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';
  String _category = 'Semua';

  @override
  Widget build(BuildContext context) {
    final shown = widget.items.where((p) {
      final okCat = _category == 'Semua' || p.category == _category;
      final q = _query.toLowerCase();
      final okQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      return okCat && okQuery;
    }).toList();
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Image.asset('assets/logo_full.png', height: 84,
              fit: BoxFit.contain),
        ),
        Container(
          width: double.infinity,
          color: const Color(0xFF0E6BA8),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anugrah Cahaya Putra Mandiri',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                  'SPESIALIS DEPOT AIR MINUM — katalog produk & paket usaha: sparepart, mesin RO, pasir & media filter.',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Cari nama produk...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: categories.map((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
              );
            }).toList(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(priceDisclaimer,
              style: TextStyle(color: Colors.orange, fontSize: 12)),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('Produk tidak ditemukan.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final p = shown[i];
                    final price = widget.priceOf(p);
                    return Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            p.imageAsset,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                              categoryImage[p.category] ??
                                  'assets/category_sparepart.png',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => CircleAvatar(
                                backgroundColor: const Color(0xFF0E6BA8),
                                foregroundColor: Colors.white,
                                child: Icon(iconForCategory(p.category)),
                              ),
                            ),
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                            '${p.category}${p.unitNote.isEmpty ? '' : ' • ${p.unitNote}'}${p.badge.isEmpty ? '' : '\n${p.badge}'}'),
                        isThreeLine: p.badge.isNotEmpty,
                        trailing: Text(
                          priceText(price),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: price == null
                                ? Colors.orange
                                : const Color(0xFF0E6BA8),
                          ),
                        ),
                        onTap: () => widget.onOpenDetail(p),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------- DETAIL PRODUK ----------------

// Gambar produk: override admin dulu, lalu foto Supabase, lalu ilustrasi kategori.
// [overrideSource] = path aset kategori atau URL gambar (dari admin).
class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, this.overrideSource});
  final Product product;
  final String? overrideSource;
  @override
  Widget build(BuildContext context) {
    final categoryAsset = categoryImage[product.category] ??
        'assets/category_sparepart.png';
    // Gambar produk sendiri dulu; bila gagal, gambar kategori; lalu ikon.
    final fallback = Image.asset(product.imageAsset,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(categoryAsset,
            height: 200, width: double.infinity, fit: BoxFit.cover));
    final override = overrideSource;
    if (override != null && override.isNotEmpty) {
      if (override.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(override,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback),
        );
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(override,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback),
      );
    }
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: fallback);
  }
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
    required this.price,
    required this.isOverridden,
    required this.isAdmin,
    this.imageOverride,
    required this.waNumber,
    required this.onAddToCart,
    required this.onSetPrice,
    required this.onResetPrice,
    required this.onSetImage,
  });
  final Product product;
  final double? price;
  final bool isOverridden;
  final bool isAdmin;
  final String? imageOverride;
  final String waNumber;
  final VoidCallback onAddToCart;
  final ValueChanged<double?> onSetPrice;
  final VoidCallback onResetPrice;
  final ValueChanged<String?> onSetImage;

  Future<void> _changeImage(BuildContext context) async {
    final urlCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Gambar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih gambar kategori:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...categoryImage.entries.map((e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(e.value,
                          width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    title: Text(e.key),
                    onTap: () {
                      onSetImage(e.value);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Gambar produk diubah.')));
                    },
                  )),
              const SizedBox(height: 12),
              const Text('Atau tempel URL gambar:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: urlCtrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final v = urlCtrl.text.trim();
                    if (v.isEmpty || !v.startsWith('http')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Tempel URL gambar yang valid.')));
                      return;
                    }
                    onSetImage(v);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gambar produk diubah.')));
                  },
                  child: const Text('Pakai URL Ini'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    onSetImage(null);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Gambar dikembalikan ke gambar bawaan.')));
                  },
                  child: const Text('Hapus Perubahan Gambar'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup')),
        ],
      ),
    );
    urlCtrl.dispose();
  }

  Future<void> _editPrice(BuildContext context) async {
    final ctrl = TextEditingController(
        text: price == null ? '' : price!.round().toString());
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Harga'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga baru (Rp)',
                hintText: 'Kosongkan = Hubungi Kami',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Harga ini hanya berubah di HP ini (pemilik). Pelanggan melihat harga terbaru setelah Anda mengubahnya.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      onSetPrice(null);
    } else {
      final v =
          double.tryParse(trimmed.replaceAll('.', '').replaceAll(',', '.'));
      if (v == null || v < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Harga tidak valid.')));
        return;
      }
      onSetPrice(v);
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga diperbarui di HP ini.')));
  }

  @override
  Widget build(BuildContext context) {
    final message = price == null
        ? 'Halo, saya tertarik dengan ${product.name}. Berapa harganya?'
        : 'Halo, saya tertarik dengan ${product.name} (${formatIDR(price!)}). Apakah masih tersedia?';
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: const Color(0xFF0E6BA8),
        foregroundColor: Colors.white,
        // Tamu tidak melihat tombol edit sama sekali.
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Harga',
              onPressed: () => _editPrice(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProductImage(product: product, overrideSource: imageOverride),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  imageDisplayNote,
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(label: Text(product.category)),
              if (product.badge.isNotEmpty) ...[
                const SizedBox(width: 8),
                Chip(
                  label: Text(product.badge),
                  backgroundColor: Colors.orange.shade100,
                ),
              ],
              if (isOverridden) ...[
                const SizedBox(width: 8),
                const Chip(label: Text('Harga diubah')),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(product.name,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            priceText(price),
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0E6BA8)),
          ),
          if (product.unitNote.isNotEmpty) Text(product.unitNote),
          const SizedBox(height: 8),
          const Text(priceDisclaimer,
              style: TextStyle(color: Colors.orange, fontSize: 12)),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Deskripsi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(product.description),
          ],
          if (product.specs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Spesifikasi Lengkap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...product.specs.map((s) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.check,
                      color: Color(0xFF0E6BA8)),
                  title: Text(s),
                )),
          ],
          if (product.warranty.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: const Text('Jaminan Garansi'),
                subtitle: Text(product.warranty),
              ),
            ),
          ],
          // Hanya admin yang melihat tombol edit harga & gambar.
          if (isAdmin) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editPrice(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Harga'),
                  ),
                ),
                const SizedBox(width: 8),
                if (isOverridden)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        onResetPrice();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Harga dikembalikan ke harga web.')));
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Reset ke Harga Web'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _changeImage(context),
                icon: const Icon(Icons.image),
                label: const Text('Ubah Gambar'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddToCart,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Tambah ke Keranjang'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showWaDialog(context, waNumber, message),
              icon: const Icon(Icons.chat),
              label: const Text('Pesan via WhatsApp'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- JASA ----------------

class ServicesScreen extends StatelessWidget {
  const ServicesScreen(
      {super.key,
      required this.items,
      required this.waNumber,
      required this.onAddToCart});
  final List<ServiceItem> items;
  final String waNumber;
  final ValueChanged<String> onAddToCart;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(serviceImage,
              height: 160, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 8),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                imageDisplayNote,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text('Jasa Pemasangan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(serviceNote, style: TextStyle(color: Colors.orange)),
        const SizedBox(height: 12),
        ...items.map((s) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF0E6BA8),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.build),
                      ),
                      title: Text(s.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(s.description),
                      trailing: const Text('Hubungi Kami',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onAddToCart(s.id),
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Keranjang'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => showWaDialog(
                              context,
                              waNumber,
                              'Halo, saya mau tanya jasa ${s.name}. Berapa biayanya?',
                            ),
                            icon: const Icon(Icons.chat),
                            label: const Text('Tanya via WA'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ---------------- KERANJANG ----------------

class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.cart,
    required this.nameOf,
    required this.priceOf,
    required this.waNumber,
    required this.onChangeQty,
    required this.onRemove,
    required this.onClear,
    required this.onOpenSettings,
  });
  final List<CartItem> cart;
  final String Function(CartItem) nameOf;
  final double? Function(CartItem) priceOf;
  final String waNumber;
  final void Function(String key, int delta) onChangeQty;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    double total = 0;
    var hasPriced = false;
    var hasUnpriced = false;
    for (final item in cart) {
      final p = priceOf(item);
      if (p == null) {
        hasUnpriced = true;
      } else {
        hasPriced = true;
        total += p * item.qty;
      }
    }
    final lines = <String>[
      'Halo, saya mau pesan dari Anugrah Cahaya Putra Mandiri:'
    ];
    for (final item in cart) {
      final p = priceOf(item);
      final priceStr = p == null ? 'Hubungi Kami' : formatIDR(p * item.qty);
      lines.add('- ${nameOf(item)} x${item.qty} = $priceStr');
    }
    if (hasPriced) lines.add('Total (item berhaga): ${formatIDR(total)}');
    if (hasUnpriced) {
      lines.add('Item "Hubungi Kami" harganya dikonfirmasi via WA.');
    }
    lines.add(priceDisclaimer);
    final message = lines.join('\n');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Keranjang',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Keranjang tersimpan offline di HP.',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        if (cart.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: Text(
                    'Keranjang masih kosong.\nTambahkan produk dari Katalog atau jasa dari tab Jasa.')),
          ),
        ...cart.map((item) {
          final p = priceOf(item);
          return Card(
            child: ListTile(
              title: Text(nameOf(item)),
              subtitle: Text(p == null
                  ? 'Hubungi Kami — harga dikonfirmasi via WA'
                  : '${formatIDR(p)} / item'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => onChangeQty(item.key, -1)),
                  Text('${item.qty}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => onChangeQty(item.key, 1)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onRemove(item.key),
                  ),
                ],
              ),
            ),
          );
        }),
        if (cart.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFE3F2FD),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total (item berhaga):',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatIDR(total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  if (hasUnpriced)
                    const Text(
                      'Ada item "Hubungi Kami" — harganya dikonfirmasi via WA, tidak masuk total.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  const SizedBox(height: 4),
                  const Text(priceDisclaimer,
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showWaDialog(context, waNumber, message),
              icon: const Icon(Icons.chat),
              label: const Text('Pesan via WhatsApp'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Kosongkan Keranjang'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan WhatsApp'),
            subtitle: Text('Nomor WA saat ini: $waNumber'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenSettings,
          ),
        ),
      ],
    );
  }
}

// ---------------- PENGATURAN ----------------

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.isAdmin,
    required this.waNumber,
    required this.onWaChanged,
    required this.onResetAllPrices,
    required this.overrideCount,
    required this.onEnterAdmin,
    required this.onExitAdmin,
  });
  final bool isAdmin;
  final String waNumber;
  final ValueChanged<String> onWaChanged;
  final VoidCallback onResetAllPrices;
  final int overrideCount;
  final VoidCallback onEnterAdmin;
  final VoidCallback onExitAdmin;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _wa =
      TextEditingController(text: widget.waNumber);

  @override
  void dispose() {
    _wa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: const Color(0xFF0E6BA8),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tamu: nomor WA hanya tampil, tidak bisa diubah.
          // Admin: bisa mengubah nomor WA.
          const Text('Nomor WhatsApp Toko',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (!widget.isAdmin) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF0E6BA8)),
                title: Text(widget.waNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hubungi kami di nomor ini'),
              ),
            ),
          ] else ...[
            TextField(
              controller: _wa,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor WA (format: 628xxx)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(waWarning,
                    style: TextStyle(color: Colors.orange.shade900)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final v = _wa.text.trim();
                  if (v.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Nomor WA tidak boleh kosong.')));
                    return;
                  }
                  widget.onWaChanged(v);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Nomor WA disimpan di HP ini.')));
                },
                icon: const Icon(Icons.save),
                label: const Text('Simpan Nomor WA'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Harga Produk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(priceDisclaimer),
          if (widget.isAdmin) ...[
            const SizedBox(height: 8),
            Text(
                'Harga bisa diubah pemilik di halaman detail produk (ikon pensil), tanpa rebuild. Saat ini ${widget.overrideCount} produk harganya diubah dari harga web.'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  widget.onResetAllPrices();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Semua harga dikembalikan ke harga web.')));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.restore),
                label: const Text('Reset Semua Harga ke Harga Web'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Tentang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text(
              'Anugrah Cahaya Putra Mandiri — Spesialis Depot Air Minum.\nAplikasi katalog offline: produk, jasa pemasangan, dan keranjang. Pesanan dikirim via WhatsApp.'),
          const SizedBox(height: 8),
          const Text(priceDisclaimer,
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          const Text('Mode Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (widget.isAdmin) ...[
            const Card(
              color: Color(0xFFE3F2FD),
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings,
                    color: Color(0xFF0E6BA8)),
                title: Text('Mode Admin aktif'),
                subtitle: Text(
                    'Anda bisa mengubah harga, gambar produk, dan nomor WA. Mode ini berakhir saat aplikasi ditutup.'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  widget.onExitAdmin();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Keluar dari Mode Admin'),
              ),
            ),
          ] else ...[
            const Text(
                'Anda sedang dalam Mode Tamu. Masuk sebagai Admin untuk mengubah harga, gambar produk, dan nomor WA.'),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onEnterAdmin,
                icon: const Icon(Icons.lock),
                label: const Text('Masuk sebagai Admin'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
