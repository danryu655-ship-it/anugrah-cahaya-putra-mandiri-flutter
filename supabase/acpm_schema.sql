-- ============================================================
-- Anugrah Cahaya Putra Mandiri (ACPM) — database Supabase
-- Proyek BARU "anugrah-cahaya" (JANGAN jalankan di proyek sekolah
-- "school_progress" — data toko harus tinggal di proyeknya sendiri).
--
-- CARA PAKAI:
-- 1. Buat proyek Supabase baru bernama "anugrah-cahaya" di dashboard
--    https://supabase.com/dashboard (gratis, tanpa kartu).
-- 2. Buka SQL Editor proyek baru itu, tempel seluruh file ini, Run.
-- 3. Salin Project URL + anon/public key dari Settings > API proyek baru.
-- 4. Isi di aplikasi: lib/data/products.dart -> supabaseUrl dan
--    supabaseAnonKey (keduanya masih KOSONG secara default).
--    Pakai ANON key saja — JANGAN pernah memasukkan service_role key.
-- 5. Build ulang APK. Aplikasi memuat produk dari tabel ini bila online;
--    bila offline / URL kosong / gagal, aplikasi memakai data lokal
--    (offline-first, harga & nama sama persis dengan seed di bawah).
--
-- HARGA: price NULL = "Hubungi Kami" (Paket Depot & Mesin RO sengaja
-- tidak dicantumkan di web karena harga bisa berubah sewaktu-waktu).
-- Foto produk: isi kolom image_url dengan URL foto asli bila sudah ada
-- (mis. URL publik Supabase Storage bucket "produk"); bila NULL,
-- aplikasi menampilkan gambar ilustrasi kategori.
-- ============================================================

create table if not exists public.acpm_products (
  id text primary key,
  name text not null,
  category text not null,
  price numeric null,
  unit_note text default '',
  badge text default '',
  description text default '',
  specs jsonb default '[]'::jsonb,
  warranty text default '',
  image_url text null,
  sort_order int default 0,
  updated_at timestamptz default now()
);

create table if not exists public.acpm_services (
  id text primary key,
  name text not null,
  description text default '',
  price numeric null,
  sort_order int default 0,
  updated_at timestamptz default now()
);

alter table public.acpm_products enable row level security;
alter table public.acpm_services enable row level security;

drop policy if exists "Public read products" on public.acpm_products;
create policy "Public read products" on public.acpm_products
  for select to anon, authenticated using (true);

drop policy if exists "Public read services" on public.acpm_services;
create policy "Public read services" on public.acpm_services
  for select to anon, authenticated using (true);

grant select on public.acpm_products to anon, authenticated;
grant select on public.acpm_services to anon, authenticated;

-- ================= ROLE: hanya admin yang boleh menulis =================
-- Pelanggan (anon) hanya bisa SELECT (policy di atas). Tulis (INSERT /
-- UPDATE / DELETE) hanya untuk role `authenticated` — yaitu akun admin
-- yang login lewat Supabase Auth. Jangan pernah memberi hak tulis ke anon:
-- siapa pun yang memegang anon key bisa mengubah harga bila policy ini
-- dilonggarkan.
-- Harga di Supabase adalah SUMBER KEBENARAN untuk katalog. Edit harga
-- lokal di aplikasi pelanggan TIDAK PERNAH menimpa Supabase — di aplikasi,
-- tombol edit hanya ada di Mode Admin (PIN), dan PATCH hanya dikirim dari
-- Mode Admin. Pelanggan tidak pernah mengirim PATCH.
-- CATATAN: aplikasi saat ini memakai anon key saja (belum ada login admin
-- Supabase Auth), jadi PATCH harga dari aplikasi akan ditolak (403) sampai
-- login admin ditambahkan. Sampai saat itu, ubah harga di Supabase lewat
-- dashboard (Table Editor); harga yang diedit admin di aplikasi tersimpan
-- lokal di HP admin itu sendiri.
drop policy if exists "Admin write products" on public.acpm_products;
create policy "Admin write products" on public.acpm_products
  for all to authenticated using (true) with check (true);

drop policy if exists "Admin write services" on public.acpm_services;
create policy "Admin write services" on public.acpm_services
  for all to authenticated using (true) with check (true);

grant insert, update, delete on public.acpm_products to authenticated;
grant insert, update, delete on public.acpm_services to authenticated;

-- ================= SEED: 28 produk (harga persis web, 17 Nov 2026) =================
insert into public.acpm_products
  (id, name, category, price, unit_note, badge, description, specs, warranty, image_url, sort_order)
values
  ('paket-mineral-standar', 'Paket Depot Air Mineral Standar', 'Paket Depot', null, '', 'PAKET USAHA', 'Lengkap dengan etalase aluminium (2 isi + 1 cuci), 2 tabung stainless...', '[]'::jsonb, '', null, 1),
  ('paket-ro', 'Paket Depot Air RO (Reverse Osmosis)', 'Paket Depot', null, '', 'BEST SELLER', 'Kapasitas tinggi dengan teknologi penyaringan membran RO 400 GPD...', '["1 Lemari Etalase Aluminium", "1 Mesin RO 400 GPD", "2 Tabung FRP 1054", "Media + UV Sterilizer", "1 Toren Air 1000 Liter"]'::jsonb, 'Garansi Mesin Pompa RO 1 Tahun & Kelistrikan 6 Bulan.', null, 2),
  ('mesin-ro-400', 'Mesin RO 400 GPD', 'Mesin RO', null, '', '', 'Menghasilkan air murni berkualitas tinggi. Cocok untuk skala kecil.', '[]'::jsonb, '', null, 3),
  ('mesin-ro-1000', 'Mesin RO 1000 GPD', 'Mesin RO', null, '', '', 'Sangat handal untuk kebutuhan komersial depot air minum skala menengah.', '[]'::jsonb, '', null, 4),
  ('karbon-filter', 'Karbon Filter', 'Sparepart', 65000, '', '', '', '[]'::jsonb, '', null, 5),
  ('cartridge-10', 'Cartridge Filter No 10', 'Sparepart', 10000, '', '', '', '[]'::jsonb, '', null, 6),
  ('cartridge-05', 'Cartridge Filter No 05', 'Sparepart', 10000, '', '', '', '[]'::jsonb, '', null, 7),
  ('cartridge-03', 'Cartridge Filter No 03', 'Sparepart', 10000, '', '', '', '[]'::jsonb, '', null, 8),
  ('cartridge-01', 'Cartridge Filter No 01', 'Sparepart', 10000, '', '', '', '[]'::jsonb, '', null, 9),
  ('tutup-galon', 'Tutup Galon', 'Sparepart', 85000, '', '', '', '[]'::jsonb, '', null, 10),
  ('housing-20', 'Housing 20 Inc', 'Sparepart', 250000, '', '', '', '[]'::jsonb, '', null, 11),
  ('housing-10', 'Housing 10 Inc', 'Sparepart', 100000, '', '', '', '[]'::jsonb, '', null, 12),
  ('tabung-media', 'Tabung Media', 'Sparepart', 800000, '', '', '', '[]'::jsonb, '', null, 13),
  ('sikat-galon', 'Sikat Galon', 'Sparepart', 500000, '', '', '', '[]'::jsonb, '', null, 14),
  ('lampu-uv-30w', 'Lampu Sterilisasi UV 30 Watt / 8 GPM', 'Sparepart', 200000, '', '', '', '[]'::jsonb, '', null, 15),
  ('mesin-uv', 'Mesin UV', 'Sparepart', 400000, '', '', '', '[]'::jsonb, '', null, 16),
  ('tangki-air', 'Tangki Air', 'Sparepart', 800000, '', '', '', '[]'::jsonb, '', null, 17),
  ('toren-stainless', 'Toren Stainless', 'Sparepart', 1000000, '', '', '', '[]'::jsonb, '', null, 18),
  ('mesin-pompa', 'Mesin Pompa', 'Sparepart', 850000, '', '', '', '[]'::jsonb, '', null, 19),
  ('filter-bioenergi', 'Filter Bioenergi Spiral', 'Sparepart', 85000, '', '', '', '[]'::jsonb, '', null, 20),
  ('galon-pet', 'Galon Pet', 'Sparepart', 50000, '', '', '', '[]'::jsonb, '', null, 21),
  ('galon-guci', 'Galon Guci', 'Sparepart', 60000, '', '', '', '[]'::jsonb, '', null, 22),
  ('tissue', 'Tissue', 'Sparepart', 650000, '', '', '', '[]'::jsonb, '', null, 23),
  ('pasir-aktif', 'Pasir Aktif', 'Pasir & Media', 250000, 'Harga per sak', '', '', '[]'::jsonb, '', null, 24),
  ('karbon-aktif', 'Karbon Aktif', 'Pasir & Media', 500000, 'Harga per sak', '', '', '[]'::jsonb, '', null, 25),
  ('manganese-greensand', 'Manganese Greensand', 'Pasir & Media', 250000, 'Harga per sak', '', '', '[]'::jsonb, '', null, 26),
  ('pasir-silika', 'Pasir Silika', 'Pasir & Media', 200000, 'Harga per sak', '', '', '[]'::jsonb, '', null, 27),
  ('pasir-zeolit', 'Pasir Zeolit', 'Pasir & Media', 150000, 'Harga per sak', '', '', '[]'::jsonb, '', null, 28)
on conflict (id) do update set
  name = excluded.name, category = excluded.category, price = excluded.price,
  unit_note = excluded.unit_note, badge = excluded.badge,
  description = excluded.description, specs = excluded.specs,
  warranty = excluded.warranty, sort_order = excluded.sort_order,
  updated_at = now();

-- ================= SEED: 6 jasa (semua Hubungi Kami) =================
insert into public.acpm_services (id, name, description, price, sort_order)
values
  ('jasa-paket-mineral', 'Pemasangan Paket Depot Air Mineral', 'Pemasangan paket depot air mineral standar di lokasi Anda.', null, 1),
  ('jasa-paket-ro', 'Pemasangan Paket Depot Air RO', 'Pemasangan paket depot air RO lengkap dengan etalase dan toren.', null, 2),
  ('jasa-mesin-ro', 'Pemasangan Mesin RO 400 / 1000 GPD', 'Pemasangan mesin RO 400 GPD atau 1000 GPD untuk depot Anda.', null, 3),
  ('jasa-ganti-media', 'Ganti Media / Pasir Filter', 'Penggantian media dan pasir filter depot air minum.', null, 4),
  ('jasa-service', 'Service & Perawatan Depot Air Minum', 'Service berkala dan perawatan depot air minum isi ulang.', null, 5),
  ('jasa-uv-pompa', 'Pemasangan / Ganti Lampu UV & Pompa', 'Pemasangan atau penggantian lampu UV sterilizer dan mesin pompa.', null, 6)
on conflict (id) do update set
  name = excluded.name, description = excluded.description,
  price = excluded.price, sort_order = excluded.sort_order,
  updated_at = now();
