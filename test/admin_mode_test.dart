// Pengujian role ACPM: layar login, Tamu (tanpa tombol edit), PIN salah.
// PIN benar end-to-end tidak diuji di sini karena PIN asli tidak boleh
// tertulis di repo/test dalam bentuk apa pun. Logika "PIN benar diterima"
// diuji unit dengan hash yang disuntikkan ke verifyPin(), dan tampilan
// Mode Admin diuji dengan isAdmin=true langsung pada halaman detail.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anugrah_cahaya/data/products.dart';
import 'package:anugrah_cahaya/main.dart';
import 'package:anugrah_cahaya/services/admin_auth.dart';

void main() {
  test('verifyPin menolak format PIN yang tidak valid', () {
    expect(verifyPin('12'), isFalse);
    expect(verifyPin('12345'), isFalse);
    expect(verifyPin('abcd'), isFalse);
    expect(verifyPin(''), isFalse);
  });

  test('verifyPin menerima PIN benar bila hash-nya cocok', () {
    final hash = sha256.convert(utf8.encode('5678')).toString();
    expect(verifyPin('5678', hash: hash), isTrue);
    expect(verifyPin('5679', hash: hash), isFalse);
    expect(verifyPin('1234', hash: hash), isFalse);
  });

  testWidgets('layar awal: logo + Login Admin + Tamu, sesuai mockup',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AnugrahCahayaApp());
    await tester.pumpAndSettle();
    expect(find.text('ACPM'), findsOneWidget);
    expect(find.text('Login Admin'), findsOneWidget);
    expect(find.text('Masukkan PIN Admin'), findsOneWidget);
    expect(find.text('Masuk sebagai Admin'), findsOneWidget);
    expect(find.text('Masuk sebagai Tamu'), findsOneWidget);
    expect(find.text('atau'), findsOneWidget);
    expect(
        find.textContaining('Tamu hanya bisa melihat katalog dan memesan'),
        findsOneWidget);
    // Katalog belum terlihat sebelum masuk.
    expect(find.text('Karbon Filter'), findsNothing);
  });

  testWidgets('PIN salah: pesan tampil, tetap di layar login',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AnugrahCahayaApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Masuk sebagai Admin'));
    await tester.pumpAndSettle();
    expect(find.text('PIN salah, coba lagi'), findsOneWidget);
    expect(find.text('Masuk sebagai Tamu'), findsOneWidget);
    expect(find.text('Karbon Filter'), findsNothing);
  });

  testWidgets('mode Tamu: detail produk tanpa tombol edit apa pun',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AnugrahCahayaApp());
    await tester.pumpAndSettle();
    // Layar login lebih tinggi dari viewport test 800x600: scroll dulu.
    await tester.ensureVisible(find.text('Masuk sebagai Tamu'));
    await tester.tap(find.text('Masuk sebagai Tamu'));
    await tester.pumpAndSettle();
    // Produk pertama langsung terlihat tanpa scroll.
    expect(find.text('Paket Depot Air Mineral Standar'), findsOneWidget);
    await tester.tap(find.text('Paket Depot Air Mineral Standar'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Harga'), findsNothing);
    expect(find.text('Ubah Gambar'), findsNothing);
    expect(find.text('Reset ke Harga Web'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
    // Tamu tetap bisa memesan. Tombol WA ada di bawah lipatan halaman
    // detail (di bawah gambar + catatan display), jadi scroll dulu.
    expect(find.text('Tambah ke Keranjang'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pesan via WhatsApp'),
      300,
    );
    await tester.pumpAndSettle();
    expect(find.text('Pesan via WhatsApp'), findsOneWidget);
  });

  testWidgets('mode Admin: tombol edit terlihat di detail produk',
      (tester) async {
    // Menguji wiring isAdmin=true langsung pada halaman detail (tanpa PIN,
    // karena PIN asli tidak boleh tertulis di repo/test).
    final p = products.firstWhere((e) => e.id == 'karbon-filter');
    await tester.pumpWidget(MaterialApp(
      home: ProductDetailPage(
        product: p,
        price: 65000,
        isOverridden: false,
        isAdmin: true,
        waNumber: '6281234567890',
        onAddToCart: () {},
        onSetPrice: (_) {},
        onResetPrice: () {},
        onSetImage: (_) {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Edit Harga'), findsOneWidget);
    expect(find.text('Ubah Gambar'), findsOneWidget);
    // Ikon edit ada 2: ikon pensil di AppBar + ikon tombol Edit Harga.
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
  });

  testWidgets('mode Tamu: Pengaturan tanpa ubah WA / reset harga',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AnugrahCahayaApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Masuk sebagai Tamu'));
    await tester.tap(find.text('Masuk sebagai Tamu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Nomor WhatsApp Toko'), findsOneWidget);
    expect(find.text('Masuk sebagai Admin'), findsOneWidget);
    expect(find.text('Simpan Nomor WA'), findsNothing);
    expect(find.text('Reset Semua Harga ke Harga Web'), findsNothing);
  });
}
