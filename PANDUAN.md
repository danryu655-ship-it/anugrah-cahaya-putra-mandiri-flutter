# Panduan Aplikasi ACPM v1.0.0+4

**Anugrah Cahaya Putra Mandiri — Spesialis Depot Air Minum**

Aplikasi katalog offline: 28 produk (2 Paket Depot, 2 Mesin RO, 19 Sparepart,
5 Pasir & Media) + 6 jasa pemasangan. Pesanan dikirim lewat WhatsApp.
Tidak perlu internet untuk membuka katalog — internet hanya dipakai saat
mengirim pesan WhatsApp.

> **Catatan penting sebelum dibagikan ke pelanggan:** nomor WhatsApp di dalam
> aplikasi masih nomor contoh dari website (`6281234567890`). Ganti dulu
> dengan nomor WhatsApp toko yang asli lewat menu Pengaturan (Mode Admin,
> lihat bagian 6) sebelum APK disebar.

---

## 1. Instal APK

1. Unduh file APK (84,8 MB) dari link unduhan yang diberikan.
2. Buka file APK yang sudah terunduh, lalu ketuk **Instal**.
3. Kalau muncul peringatan "Diblokir" / "Instal aplikasi tidak dikenal",
   izinkan dulu:
   - Ketuk **Setelan** pada peringatan itu, lalu aktifkan
     **Izinkan dari sumber ini** untuk aplikasi yang membuka file APK
     (biasanya Chrome atau aplikasi chat).
   - Atau buka manual: **Pengaturan HP → Aplikasi → akses khusus →
     Instal aplikasi tidak dikenal → pilih aplikasi yang membuka APK →
     Izinkan**.
4. Setelah terinstal, ikon **ACPM** muncul di layar HP.

### Kalau tidak bisa terinstal

Jangan langsung instal ulang berkali-kali. Baca dulu pesan persis yang
muncul di layar, lalu coba satu perbaikan dalam satu waktu:

| Yang muncul / terjadi | Kemungkinan penyebab & perbaikan |
|---|---|
| "Aplikasi tidak terpasang" | Unduhan belum selesai (file 84,8 MB) — unduh ulang sampai penuh, lalu instal lagi. |
| "Diblokir" / "tidak dikenal" | Izin instal dari sumber tidak dikenal belum diizinkan (lihat langkah 3 di atas). |
| "Tidak cukup ruang" | Hapus dulu file/aplikasi yang tidak dipakai; APK butuh ruang kosong lebih dari 84,8 MB. |
| "Terjadi kesalahan saat mengurai paket" / parse error | File APK rusak saat unduh — hapus file lama, unduh ulang dari link yang sama. |
| Sudah ada versi lama terinstal | Hapus (uninstall) versi lama dulu, baru instal yang baru. |
| Tidak ada pesan, instal diam-diam gagal | Restart HP, lalu coba instal sekali lagi. |

Kalau dua kali perbaikan masih gagal, catat pesan persisnya dan kirim ke
Rias — jangan rebuild dulu sebelum penyebabnya jelas.

---

## 2. Buka pertama kali — Login Admin / Tamu

Setiap kali aplikasi dibuka, muncul layar login:

- **Masuk sebagai Admin** — isi PIN Admin 4 digit (PIN yang sudah kamu
  tentukan), lalu ketuk tombolnya. Kalau salah, muncul "PIN salah, coba lagi".
- **Masuk sebagai Tamu** — ketuk tombol di bawah kartu login. Tamu hanya
  bisa melihat katalog dan memesan; tidak ada tombol edit sama sekali.

Aturan Mode Admin:

- Mode Admin hanya berlaku **sampai aplikasi ditutup**. Buka lagi = login lagi.
- PIN Admin jangan dibagikan ke pelanggan.
- Yang bisa dilakukan admin: ubah harga, ubah gambar produk, ubah nomor WA
  (lihat bagian 6).

---

## 3. Katalog — 28 produk

Tab **Katalog** di bawah. Saring dengan chip kategori di atas daftar:

- **Semua** · **Paket Depot** · **Mesin RO** · **Sparepart** · **Pasir & Media**

Ketuk satu produk untuk membuka halaman detailnya:

- Gambar produk di atas, dengan catatan di bawahnya:
  > "Gambar ini hanya display, untuk lebih detailnya bisa hub nomor yang tertera."
- Nama, kategori, harga (atau **Hubungi Kami** untuk Paket Depot dan
  Mesin RO yang harganya memang tidak dicantumkan).
- Deskripsi, Spesifikasi Lengkap, dan kartu **Jaminan Garansi** kalau ada.
- Harga dapat berubah sewaktu-waktu — konfirmasi via WhatsApp sebelum memesan.

Dua tombol di bawah halaman detail:

- **Tambah ke Keranjang** — masukkan produk ke keranjang.
- **Pesan via WhatsApp** — langsung tanya produk itu ke nomor toko.

---

## 4. Jasa — 6 jasa pemasangan

Tab **Jasa** berisi 6 layanan, semuanya **Hubungi Kami** (harga menyesuaikan
pekerjaan):

1. Pemasangan Paket Depot Air Mineral
2. Pemasangan Paket Depot Air RO
3. Pemasangan Mesin RO 400/1000 GPD
4. Ganti Media / Pasir Filter
5. Service & Perawatan Depot Air Minum
6. Pemasangan / Ganti Lampu UV & Pompa

Gambar di atas tab Jasa juga hanya display (catatan yang sama seperti produk).
Ketuk **Keranjang** pada jasa untuk menambahkannya, lalu pesan via WhatsApp.

---

## 5. Keranjang & pesan via WhatsApp

Tab **Keranjang** di bawah (ada angka jumlah isinya).

- Keranjang **tersimpan offline di HP** — menutup aplikasi tidak
  menghapusnya.
- Atur jumlah / hapus item dari daftar keranjang.
- Ketuk **Pesan via WhatsApp** — aplikasi membuka WhatsApp dengan pesan
  pesanan yang sudah terisi otomatis (nama produk + harga).
- Kalau WhatsApp belum terpasang di HP, muncul pilihan untuk menyalin pesan
  dan mengirimnya manual.
- **Kosongkan Keranjang** menghapus semua isi keranjang.

---

## 6. Untuk pemilik (Mode Admin)

Masuk dulu sebagai Admin (bagian 2). Semua perubahan di bawah ini
**tersimpan di HP itu saja** (offline), bukan di server — jadi harga/gambar/
nomor WA yang diubah di HP admin tidak otomatis berubah di HP pelanggan
yang sudah menginstal APK. Supaya harga di semua HP pelanggan ikut berubah,
aktifkan Supabase (bagian 7).

### Ubah harga

1. Buka detail produk, ketuk ikon pensil di kanan atas (atau tombol
   **Edit Harga**).
2. Isi harga baru (Rp). Kosongkan = kembali ke **Hubungi Kami**.
3. Ketuk **Simpan**. Harga di HP ini langsung berubah; ada chip
   "Harga diubah" di detail produk.
4. **Reset ke Harga Web** mengembalikan harga produk itu ke harga awal.
   Di **Pengaturan → Harga Produk** ada **Reset Semua Harga ke Harga Web**
   untuk mengembalikan semuanya sekaligus.

### Ubah gambar produk

1. Buka detail produk (Mode Admin), ketuk **Ubah Gambar**.
2. Pilih salah satu gambar kategori, atau tempel URL gambar
   (`https://...`), lalu ketuk **Pakai URL Ini**.
3. **Hapus Perubahan Gambar** mengembalikan gambar bawaan.
4. Foto produk asli lebih baik daripada gambar ilustrasi — kalau sudah ada
   foto asli, tempel URL-nya di sini.

### Ubah nomor WhatsApp toko

1. Ketuk ikon gerigi **Pengaturan** di kanan atas halaman utama.
2. Isi **Nomor WA** dengan format `628xxx` (tanpa `+`, tanpa spasi).
3. Ketuk **Simpan Nomor WA**.
4. Nomor ini yang dipakai semua tombol "Pesan via WhatsApp".

### Keluar dari Mode Admin

**Pengaturan → Mode Admin → Keluar dari Mode Admin**. Tamu yang memakai HP
itu sesudahnya tidak akan melihat tombol edit apa pun.

---

## 7. Supabase (opsional, untuk harga online)

Saat ini aplikasi memakai data lokal di dalam APK (offline-first). Supaya
harga dan produk bisa diubah dari satu tempat dan terlihat di semua HP
pelanggan, perlu database Supabase sendiri:

1. Buat proyek baru di [Supabase](https://supabase.com/dashboard) bernama
   `anugrah-cahaya` (jangan pakai proyek sekolah — data toko harus terpisah).
2. Di SQL Editor proyek itu, jalankan file `supabase/acpm_schema.sql`
   dari repo ini (membuat tabel `acpm_products` + `acpm_services` beserta
   data 28 produk + 6 jasa).
3. Isi `supabaseUrl` dan `supabaseAnonKey` di `lib/data/products.dart`.
4. Build ulang APK dan bagikan versi barunya.

Selama Supabase belum diisi, aplikasi tetap jalan penuh dengan data lokal.

---

## 8. Ringkasan cepat

| Saya mau... | Caranya |
|---|---|
| Lihat produk | Tab Katalog, saring pakai chip kategori |
| Tanya / pesan produk | Detail produk → Pesan via WhatsApp |
| Pesan banyak item sekaligus | Tambah ke Keranjang → tab Keranjang → Pesan via WhatsApp |
| Ubah harga | Mode Admin → detail produk → ikon pensil |
| Ubah gambar | Mode Admin → detail produk → Ubah Gambar |
| Ganti nomor WA toko | Mode Admin → Pengaturan → Nomor WhatsApp Toko |
| Keluar dari admin | Pengaturan → Keluar dari Mode Admin |
| Kembalikan semua harga | Mode Admin → Pengaturan → Reset Semua Harga ke Harga Web |

**Versi panduan ini:** ACPM v1.0.0+4 (17 Nov 2026).
Repo: https://github.com/danryu655-ship-it/anugrah-cahaya-putra-mandiri-flutter
