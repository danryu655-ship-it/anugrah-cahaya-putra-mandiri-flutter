-- ACPM: kunci tulis Supabase — hanya admin (pemilik, lewat dashboard
-- Supabase) yang bisa mengubah harga/gambar di database.
-- Anon (publishable key yang tertanam di APK dan dipakai semua pelanggan)
-- hanya boleh BACA. Jalankan sekali di SQL Editor proyek
-- ipktwifbornanhrntvlb. Idempotent: aman dijalankan ulang.
--
-- Latar: tes 17 Nov 13:33 WIB membuktikan PATCH harga dengan anon key
-- BERHASIL (204) — RLS/policy di tabel live tidak menahan tulis.
-- Harga tes sempat berubah lalu sudah dikembalikan ke 65000.

-- 1. Aktifkan RLS di kedua tabel.
ALTER TABLE public.acpm_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.acpm_services ENABLE ROW LEVEL SECURITY;

-- 2. Hapus SEMUA policy lama di kedua tabel (nama apa pun), supaya tidak
--    ada policy longgar yang tertinggal.
DO $$
DECLARE pol record;
BEGIN
  FOR pol IN
    SELECT policyname, tablename FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('acpm_products', 'acpm_services')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- 3. Policy baru: baca untuk semua, tulis hanya untuk role authenticated
--    (login Supabase pemilik di dashboard). Aplikasi tidak login Supabase,
--    jadi PATCH dari aplikasi akan ditolak — sesuai desain: harga di
--    Supabase diubah lewat dashboard, perubahan admin di aplikasi hanya
--    berlaku di HP admin itu sendiri.
CREATE POLICY "acpm_products_select" ON public.acpm_products
  FOR SELECT USING (true);
CREATE POLICY "acpm_products_write" ON public.acpm_products
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "acpm_services_select" ON public.acpm_services
  FOR SELECT USING (true);
CREATE POLICY "acpm_services_write" ON public.acpm_services
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 4. Sabuk pengaman kedua di level hak tabel: anon tidak boleh
--    INSERT/UPDATE/DELETE sama sekali.
REVOKE INSERT, UPDATE, DELETE ON public.acpm_products FROM anon;
REVOKE INSERT, UPDATE, DELETE ON public.acpm_services FROM anon;
GRANT SELECT ON public.acpm_products, public.acpm_services TO anon;

-- 5. Bukti: tampilkan RLS + policy yang aktif (sertakan hasilnya di laporan).
SELECT tablename, rowsecurity FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('acpm_products', 'acpm_services');
SELECT tablename, policyname, roles, cmd FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('acpm_products', 'acpm_services')
ORDER BY tablename, policyname;
