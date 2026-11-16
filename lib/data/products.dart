// Katalog Anugrah Cahaya Putra Mandiri — Spesialis Depot Air Minum.
// Data harga default = harga di web
// https://anugrahcahayaputramandiri.infinityfree.me/produk.html?i=2
// dibaca 17 Nov 2026 00:34 WIB. Harga di web sengaja tidak dicantumkan
// untuk Paket & Mesin RO ("Hubungi Kami") karena harga bisa berubah
// sewaktu-waktu — pemilik bisa mengubah harga di aplikasi tanpa rebuild
// (override tersimpan di SharedPreferences, key acpm_price_overrides).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.unitNote = '',
    this.badge = '',
    this.description = '',
    this.specs = const [],
    this.warranty = '',
    this.imageUrl,
  });
  final String id;
  final String name;
  final String category; // Paket Depot, Mesin RO, Sparepart, Pasir & Media
  final double? price; // null = Hubungi Kami
  final String unitNote; // mis. "Harga per sak"
  final String badge; // BEST SELLER / PAKET USAHA
  final String description;
  final List<String> specs;
  final String warranty;
  final String? imageUrl; // URL foto produk dari Supabase (null = pakai gambar kategori)

  factory Product.fromJson(Map<String, dynamic> j) {
    final specsRaw = j['specs'];
    final specs = specsRaw is List
        ? specsRaw.map((e) => e.toString()).toList()
        : <String>[];
    final priceRaw = j['price'];
    return Product(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? '',
      category: j['category'] as String? ?? '',
      price: priceRaw == null ? null : (priceRaw as num).toDouble(),
      unitNote: j['unit_note'] as String? ?? '',
      badge: j['badge'] as String? ?? '',
      description: j['description'] as String? ?? '',
      specs: specs,
      warranty: j['warranty'] as String? ?? '',
      imageUrl: j['image_url'] as String?,
    );
  }
}

// Gambar ilustrasi per kategori (aset lokal). Foto di web tidak dipakai:
// 18 kartu sparepart di web memakai gambar yang sama (alt "Lampu
// Sterilisasi UV") bahkan untuk galon/tissue, jadi foto itu salah untuk
// produknya. Gambar di bawah ini ilustrasi kategori, bukan foto asli produk.
const Map<String, String> categoryImage = {
  'Paket Depot': 'assets/category_paket_depot.png',
  'Mesin RO': 'assets/category_mesin_ro.png',
  'Sparepart': 'assets/category_sparepart.png',
  'Pasir & Media': 'assets/category_pasir_media.png',
};
const String serviceImage = 'assets/category_jasa.png';

// ---- Supabase (opsional) ----
// Isi keduanya setelah membuat proyek Supabase baru "anugrah-cahaya"
// dan menjalankan supabase/acpm_schema.sql di SQL editor-nya.
// Bila kosong, aplikasi memakai data lokal di bawah ini (offline-first).
// JANGAN isi dengan URL/key proyek sekolah (school_progress) — data toko
// harus tinggal di proyeknya sendiri.
const String supabaseUrl = '';
const String supabaseAnonKey = '';

const String priceDisclaimer =
    'Harga dapat berubah sewaktu-waktu — konfirmasi via WhatsApp sebelum memesan.';

const List<Product> products = [
  // ---- Paket Depot (Hubungi Kami) ----
  Product(
    id: 'paket-mineral-standar',
    name: 'Paket Depot Air Mineral Standar',
    category: 'Paket Depot',
    price: null,
    badge: 'PAKET USAHA',
    description:
        'Lengkap dengan etalase aluminium (2 isi + 1 cuci), 2 tabung stainless...',
  ),
  Product(
    id: 'paket-ro',
    name: 'Paket Depot Air RO (Reverse Osmosis)',
    category: 'Paket Depot',
    price: null,
    badge: 'BEST SELLER',
    description:
        'Kapasitas tinggi dengan teknologi penyaringan membran RO 400 GPD...',
    specs: [
      '1 Lemari Etalase Aluminium',
      '1 Mesin RO 400 GPD',
      '2 Tabung FRP 1054',
      'Media + UV Sterilizer',
      '1 Toren Air 1000 Liter',
    ],
    warranty: 'Garansi Mesin Pompa RO 1 Tahun & Kelistrikan 6 Bulan.',
  ),
  // ---- Mesin RO (Hubungi Kami) ----
  Product(
    id: 'mesin-ro-400',
    name: 'Mesin RO 400 GPD',
    category: 'Mesin RO',
    price: null,
    description:
        'Menghasilkan air murni berkualitas tinggi. Cocok untuk skala kecil.',
  ),
  Product(
    id: 'mesin-ro-1000',
    name: 'Mesin RO 1000 GPD',
    category: 'Mesin RO',
    price: null,
    description:
        'Sangat handal untuk kebutuhan komersial depot air minum skala menengah.',
  ),
  // ---- Sparepart ----
  Product(
    id: 'karbon-filter',
    name: 'Karbon Filter',
    category: 'Sparepart',
    price: 65000,
  ),
  Product(
    id: 'cartridge-10',
    name: 'Cartridge Filter No 10',
    category: 'Sparepart',
    price: 10000,
  ),
  Product(
    id: 'cartridge-05',
    name: 'Cartridge Filter No 05',
    category: 'Sparepart',
    price: 10000,
  ),
  Product(
    id: 'cartridge-03',
    name: 'Cartridge Filter No 03',
    category: 'Sparepart',
    price: 10000,
  ),
  Product(
    id: 'cartridge-01',
    name: 'Cartridge Filter No 01',
    category: 'Sparepart',
    price: 10000,
  ),
  Product(
    id: 'tutup-galon',
    name: 'Tutup Galon',
    category: 'Sparepart',
    price: 85000,
  ),
  Product(
    id: 'housing-20',
    name: 'Housing 20 Inc',
    category: 'Sparepart',
    price: 250000,
  ),
  Product(
    id: 'housing-10',
    name: 'Housing 10 Inc',
    category: 'Sparepart',
    price: 100000,
  ),
  Product(
    id: 'tabung-media',
    name: 'Tabung Media',
    category: 'Sparepart',
    price: 800000,
  ),
  Product(
    id: 'sikat-galon',
    name: 'Sikat Galon',
    category: 'Sparepart',
    price: 500000,
  ),
  Product(
    id: 'lampu-uv-30w',
    name: 'Lampu Sterilisasi UV 30 Watt / 8 GPM',
    category: 'Sparepart',
    price: 200000,
  ),
  Product(
    id: 'mesin-uv',
    name: 'Mesin UV',
    category: 'Sparepart',
    price: 400000,
  ),
  Product(
    id: 'tangki-air',
    name: 'Tangki Air',
    category: 'Sparepart',
    price: 800000,
  ),
  Product(
    id: 'toren-stainless',
    name: 'Toren Stainless',
    category: 'Sparepart',
    price: 1000000,
  ),
  Product(
    id: 'mesin-pompa',
    name: 'Mesin Pompa',
    category: 'Sparepart',
    price: 850000,
  ),
  Product(
    id: 'filter-bioenergi',
    name: 'Filter Bioenergi Spiral',
    category: 'Sparepart',
    price: 85000,
  ),
  Product(
    id: 'galon-pet',
    name: 'Galon Pet',
    category: 'Sparepart',
    price: 50000,
  ),
  Product(
    id: 'galon-guci',
    name: 'Galon Guci',
    category: 'Sparepart',
    price: 60000,
  ),
  Product(
    id: 'tissue',
    name: 'Tissue',
    category: 'Sparepart',
    price: 650000,
  ),
  // ---- Pasir & Media (Harga per sak) ----
  Product(
    id: 'pasir-aktif',
    name: 'Pasir Aktif',
    category: 'Pasir & Media',
    price: 250000,
    unitNote: 'Harga per sak',
  ),
  Product(
    id: 'karbon-aktif',
    name: 'Karbon Aktif',
    category: 'Pasir & Media',
    price: 500000,
    unitNote: 'Harga per sak',
  ),
  Product(
    id: 'manganese-greensand',
    name: 'Manganese Greensand',
    category: 'Pasir & Media',
    price: 250000,
    unitNote: 'Harga per sak',
  ),
  Product(
    id: 'pasir-silika',
    name: 'Pasir Silika',
    category: 'Pasir & Media',
    price: 200000,
    unitNote: 'Harga per sak',
  ),
  Product(
    id: 'pasir-zeolit',
    name: 'Pasir Zeolit',
    category: 'Pasir & Media',
    price: 150000,
    unitNote: 'Harga per sak',
  ),
];

class ServiceItem {
  const ServiceItem({required this.id, required this.name, required this.description});
  final String id;
  final String name;
  final String description;

  factory ServiceItem.fromJson(Map<String, dynamic> j) => ServiceItem(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
      );
}

const String serviceNote =
    'Harga jasa menyesuaikan lokasi & kondisi — konfirmasi via WhatsApp.';

const List<ServiceItem> services = [
  ServiceItem(
    id: 'jasa-paket-mineral',
    name: 'Pemasangan Paket Depot Air Mineral',
    description: 'Pemasangan paket depot air mineral standar di lokasi Anda.',
  ),
  ServiceItem(
    id: 'jasa-paket-ro',
    name: 'Pemasangan Paket Depot Air RO',
    description: 'Pemasangan paket depot air RO lengkap dengan etalase dan toren.',
  ),
  ServiceItem(
    id: 'jasa-mesin-ro',
    name: 'Pemasangan Mesin RO 400 / 1000 GPD',
    description: 'Pemasangan mesin RO 400 GPD atau 1000 GPD untuk depot Anda.',
  ),
  ServiceItem(
    id: 'jasa-ganti-media',
    name: 'Ganti Media / Pasir Filter',
    description: 'Penggantian media dan pasir filter depot air minum.',
  ),
  ServiceItem(
    id: 'jasa-service',
    name: 'Service & Perawatan Depot Air Minum',
    description: 'Service berkala dan perawatan depot air minum isi ulang.',
  ),
  ServiceItem(
    id: 'jasa-uv-pompa',
    name: 'Pemasangan / Ganti Lampu UV & Pompa',
    description: 'Pemasangan atau penggantian lampu UV sterilizer dan mesin pompa.',
  ),
];

Product? findProduct(String id) {
  for (final p in products) {
    if (p.id == id) return p;
  }
  return null;
}

ServiceItem? findService(String id) {
  for (final s in services) {
    if (s.id == id) return s;
  }
  return null;
}
