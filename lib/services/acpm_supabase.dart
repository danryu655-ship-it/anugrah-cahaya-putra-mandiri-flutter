// Muat katalog dari Supabase (PostgREST) bila SUPABASE_URL + ANON KEY terisi.
// Bila kosong / gagal / offline, kembalikan null dan aplikasi memakai data
// lokal di lib/data/products.dart (offline-first). Supabase pernah tidak
// bisa di-resolve DNS-nya di HP user, jadi fallback lokal ini wajib ada.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/products.dart';

bool get supabaseConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

Map<String, String> get _headers => {
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey',
      'Accept': 'application/json',
    };

Future<List<Product>?> fetchRemoteProducts() async {
  if (!supabaseConfigured) return null;
  try {
    final res = await http
        .get(
          Uri.parse(
              '$supabaseUrl/rest/v1/acpm_products?select=*&order=sort_order'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List;
    final items = list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items;
  } catch (_) {
    return null;
  }
}

/// Kirim perubahan harga admin ke Supabase (PATCH).
/// Hanya dipanggil dari Mode Admin. Mengembalikan false bila gagal —
/// pemanggil tetap menyimpan harga secara lokal di HP admin.
/// CATATAN: policy tulis di SQL hanya untuk role `authenticated`, sedangkan
/// aplikasi saat ini memakai anon key saja, jadi PATCH ini akan ditolak
/// (403) sampai login admin Supabase Auth ditambahkan. Sampai saat itu,
/// harga Supabase diubah lewat dashboard; harga lokal admin tetap berlaku
/// di HP admin itu sendiri.
Future<bool> updateRemotePrice(String productId, double? price) async {
  if (!supabaseConfigured) return false;
  try {
    final res = await http
        .patch(
          Uri.parse(
              '$supabaseUrl/rest/v1/acpm_products?id=eq.$productId'),
          headers: {
            ..._headers,
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({'price': price}),
        )
        .timeout(const Duration(seconds: 10));
    return res.statusCode == 200 || res.statusCode == 204;
  } catch (_) {
    return false;
  }
}

/// Kirim perubahan gambar admin ke Supabase (PATCH image_url).
/// Hanya dipanggil dari Mode Admin dan hanya untuk URL (bukan aset lokal).
/// Batasan yang sama dengan updateRemotePrice: policy tulis hanya untuk
/// role `authenticated`, jadi dengan anon key saja PATCH ini ditolak (403)
/// sampai login admin Supabase Auth ditambahkan.
Future<bool> updateRemoteImage(String productId, String imageUrl) async {
  if (!supabaseConfigured) return false;
  try {
    final res = await http
        .patch(
          Uri.parse(
              '$supabaseUrl/rest/v1/acpm_products?id=eq.$productId'),
          headers: {
            ..._headers,
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal',
          },
          body: jsonEncode({'image_url': imageUrl}),
        )
        .timeout(const Duration(seconds: 10));
    return res.statusCode == 200 || res.statusCode == 204;
  } catch (_) {
    return false;
  }
}

Future<List<ServiceItem>?> fetchRemoteServices() async {
  if (!supabaseConfigured) return null;
  try {
    final res = await http
        .get(
          Uri.parse(
              '$supabaseUrl/rest/v1/acpm_services?select=*&order=sort_order'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final list = jsonDecode(res.body) as List;
    final items = list
        .map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
        .where((s) => s.id.isNotEmpty && s.name.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items;
  } catch (_) {
    return null;
  }
}
