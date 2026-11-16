// Mode Admin ACPM — hanya admin yang boleh ubah harga & nomor WA.
//
// CARA KERJA:
// - Aplikasi dibuka selalu sebagai PELANGGAN. Semua tombol edit
//   disembunyikan total di mode Pelanggan (bukan hanya nonaktif).
// - Masuk Mode Admin lewat PIN 4 digit (ikon gembok di AppBar / menu di
//   Pengaturan). Status admin disimpan di MEMORI SAJA — tiap aplikasi
//   ditutup lalu dibuka lagi, pelanggan kembali terkunci.
// - PIN TIDAK PERNAH disimpan polos. Yang disimpan di sini hanya hash
//   SHA-256 (hex) dari PIN.
//
// PIN ADMIN — HANYA HASH YANG DISIMPAN DI SINI.
// Konstanta di bawah adalah hash SHA-256 (hex) dari PIN 4 digit admin.
// PIN aslinya TIDAK PERNAH ditulis di kode, repo, commit, log, atau laporan.
// Untuk mengganti PIN: hitung SHA-256 dari PIN baru, ganti konstanta ini,
// lalu build ulang APK.
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

const String adminPinSha256 =
    'b4ff2b19753f126767e446acac628f07165d8852d9296e95cacda9b8aa00c641';

bool verifyPin(String pin, {String hash = adminPinSha256}) {
  if (pin.length != 4 || int.tryParse(pin) == null) return false;
  final digest = sha256.convert(utf8.encode(pin)).toString();
  return _constantTimeEquals(digest, hash);
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Dialog PIN Admin. Panggil dari AppBar / Pengaturan.
/// [onUnlocked] dipanggil dengan true hanya bila PIN benar.
Future<void> showAdminPinDialog(
  BuildContext context, {
  required ValueChanged<bool> onUnlocked,
}) async {
  final ctrl = TextEditingController();
  var error = '';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('Mode Admin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan PIN Admin 4 digit untuk mengubah harga dan nomor WA.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'PIN Admin',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                onSubmitted: (_) {
                  if (verifyPin(ctrl.text.trim())) {
                    Navigator.pop(ctx, true);
                  } else {
                    setDialogState(() => error = 'PIN salah');
                  }
                },
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(error,
                    style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (verifyPin(ctrl.text.trim())) {
                  Navigator.pop(ctx, true);
                } else {
                  setDialogState(() => error = 'PIN salah');
                }
              },
              child: const Text('Masuk'),
            ),
          ],
        );
      },
    ),
  );
  ctrl.dispose();
  if (ok == true && context.mounted) {
    onUnlocked(true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mode Admin aktif — harga & nomor WA bisa diubah.')));
  }
}
