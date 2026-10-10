# JelajahHub MVP

Starter marketplace travel multi-tenant: Umroh, Haji, wisata domestik, dan internasional. Dibangun dengan Next.js App Router + Supabase Auth/Postgres, siap dihubungkan ke GitHub dan Vercel.

## Fitur MVP
- Katalog publik dan detail paket, kategori, pencarian sederhana, CTA WhatsApp.
- Pendaftaran/login mitra dan status approval perusahaan.
- Dashboard agen untuk membuat paket dan landing page promosi.
- Dashboard admin untuk approve/reject/suspend perusahaan dan moderasi konten.
- Slug landing page publik `/promo/[slug]`.
- RLS policies di Supabase untuk membatasi akses data antarperusahaan dan mengunci status konten.

## 1. Persiapan
Butuh Node.js 20.9+ (disarankan Node 22) dan akun GitHub, Supabase, serta Vercel.

```bash
npm install
cp .env.example .env.local
npm run dev
```

## 2. Buat database Supabase
1. Buat project baru di Supabase.
2. Buka **SQL Editor** lalu jalankan seluruh isi `supabase/schema.sql`.
3. Buka **Project Settings → API** (atau Connect) dan salin Project URL dan publishable/anon key.
4. Isi `.env.local`:

```env
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_OR_ANON_KEY
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

Jangan pernah memasukkan `service_role` key ke browser, GitHub, atau variabel `NEXT_PUBLIC_*`.

## 3. Buat akun admin pertama
1. Jalankan aplikasi, daftar akun dengan email milikmu, dan selesaikan verifikasi email bila diminta.
2. Di Supabase SQL Editor, jalankan query berikut dengan email yang sama:

```sql
update public.profiles
set role = 'admin'
where id = (select id from auth.users where email = 'EMAIL_KAMU');
```

3. Keluar dan masuk kembali, lalu buka `/admin`.

**Penting:** admin pertama dipromosikan manual di SQL. Form signup selalu membuat role `agent`; klien tidak dapat menetapkan role admin.

## 4. Verifikasi email & URL Auth
Di Supabase **Authentication → URL Configuration**, set Site URL menjadi URL lokal saat development (`http://localhost:3000`) dan tambahkan URL deployment Vercel setelah deploy. Atur email confirmation sesuai kebutuhan. Jika email confirmation aktif, pengguna perlu verifikasi sebelum sesi login tersedia. Pada alur pendaftaran awal, untuk MVP ini agen mungkin perlu menyelesaikan profil perusahaan lagi bila sesi belum ada; jika begitu, matikan sementara email confirmation saat testing atau lanjutkan penyempurnaan flow verifikasi sebelum peluncuran publik.

## 5. GitHub dan Vercel
```bash
git init
git add .
git commit -m "Initial JelajahHub travel marketplace MVP"
git branch -M main
git remote add origin https://github.com/USERNAME/jelajahhub-mvp.git
git push -u origin main
```
Buat repository kosong di GitHub terlebih dahulu. Lalu di Vercel pilih **Add New → Project**, import repository, dan tambahkan environment variables yang sama dengan `.env.local`. Deploy.

Setelah deploy, tambahkan domain Vercel di Supabase Auth URL Configuration. Gunakan URL HTTPS production untuk `NEXT_PUBLIC_SITE_URL`.

## 6. Uji alur MVP
1. Daftar akun agen; pastikan status perusahaan pending.
2. Promosikan akunmu sendiri menjadi admin menggunakan query di atas.
3. Masuk sebagai admin dan setujui perusahaan.
4. Masuk kembali sebagai agen, buat paket; paket masuk status pending.
5. Admin setujui paket; paket muncul di katalog publik.
6. Buat landing page; admin setujui, lalu halaman tersedia di `/promo/slug`.
7. Uji akses antar akun agen untuk memastikan data tidak bocor.

## Batasan MVP yang perlu diselesaikan sebelum produksi
- Tambahkan halaman edit profil perusahaan dan proses pengajuan ulang setelah ditolak.
- Implementasikan upload gambar ke Supabase Storage (saat ini cover menerima URL gambar).
- Simpan catatan penolakan dan approval logs dari UI admin.
- Tambahkan rate limiting, captcha/anti-spam, email notifikasi, validasi dokumen legalitas, dan monitoring.
- Tambahkan workflow edit konten yang menyimpan draft/revisi, agar update konten live tidak mengubah konten publik sebelum disetujui.
- Statistik page views, booking, pembayaran, dan billing iklan belum diimplementasikan.
- Untuk produk Umroh/Haji, lakukan verifikasi legalitas/izin penyelenggara yang relevan sebelum memberi badge terverifikasi atau mengizinkan iklan berbayar.

## Catatan keamanan
RLS di schema merupakan batas keamanan inti. Jangan pernah menambahkan service-role key ke frontend. Audit ulang semua policy sebelum menerima agen sungguhan. Status yang ditulis UI saja tidak cukup; akses publik dibatasi oleh policy database.
