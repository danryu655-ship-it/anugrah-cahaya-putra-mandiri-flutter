# Anugrah Cahaya Putra Mandiri

Aplikasi katalog offline untuk **Anugrah Cahaya Putra Mandiri — Spesialis Depot Air Minum** (air minum isi ulang).

- **Katalog:** 28 produk — 2 Paket Depot, 2 Mesin RO, 19 Sparepart, 5 Pasir & Media. Cari + filter kategori.
- **Jasa:** 6 jasa pemasangan & perawatan, semua "Hubungi Kami".
- **Keranjang:** tersimpan offline, total hanya untuk item berhaga, pesan terformat via WhatsApp.
- **Harga bisa diubah pemilik tanpa rebuild:** di detail produk ada Edit Harga (ikon pensil) + Reset ke Harga Web. Override tersimpan di SharedPreferences (`acpm_price_overrides`). Harga default = harga web 17 Nov 2026. Disclaimer di katalog & detail: "Harga dapat berubah sewaktu-waktu — konfirmasi via WhatsApp sebelum memesan."
- **Nomor WA bisa diubah:** Pengaturan (ikon ⚙️) — field nomor WA, tersimpan di `acpm_wa_number`. Default 6281234567890 (dari tombol web, terlihat seperti nomor contoh — ganti dengan nomor WA asli sebelum APK dibagikan ke pelanggan).
- Offline-first, tanpa Supabase, tanpa login.

## Build

```bash
source ~/.bashrc
export GRADLE_USER_HOME=~/workspace/gradle-home
flutter pub get
flutter analyze
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

Versi: 1.0.0+1 • Package: com.danryu.anugrah_cahaya
