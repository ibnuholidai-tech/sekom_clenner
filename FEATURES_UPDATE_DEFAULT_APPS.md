# Fitur Baru: Edit, Hapus, dan Instal Aplikasi Default

## Ringkasan Perubahan

Telah ditambahkan fitur lengkap untuk mengelola aplikasi di tab **Aplikasi Default** dengan 4 tombol aksi untuk setiap aplikasi:

### 1. 📍 Tombol Tambah Path Instalasi (Biru)
- **Ikon**: `add_location_alt`
- **Tampil untuk**: Aplikasi yang belum terinstal
- **Fungsi**: Memilih path file installer (.exe atau .msi) untuk aplikasi yang tidak terdeteksi
- **Hasil**: Path disimpan ke daftar aplikasi yang dapat diinstal

### 2. ✏️ Tombol Edit (Hijau)
- **Ikon**: `edit_outlined`
- **Tampil untuk**: Semua aplikasi
- **Fungsi**: Mengedit informasi aplikasi dan menambahkan path instalasi
- **Hasil**: Aplikasi dapat diedit dan disimpan untuk instalasi manual

### 3. ⬇️ Tombol Instal (Ungu)
- **Ikon**: `download_for_offline_outlined`
- **Tampil untuk**: Aplikasi yang belum terinstal (status ❌)
- **Fungsi**: 
  - Membuka dialog untuk memilih file installer
  - Menjalankan instalasi otomatis dari file yang dipilih
  - Mendukung file .exe dan .msi
- **Hasil**: Installer dijalankan sesuai tipe file

### 4. ❌ Tombol Hapus (Merah)
- **Ikon**: `delete_outline`
- **Tampil untuk**: Semua aplikasi
- **Fungsi**: Menghapus aplikasi dari daftar default yang dipantau
- **Hasil**: Aplikasi dihapus dari monitoring default

## Aplikasi yang Tersedia di Tab Default

Daftar aplikasi bawaan yang dipantau:
- ✅ Microsoft Office
- ✅ Firefox
- ✅ Microsoft Edge
- ✅ Google Chrome
- ✅ WinRAR
- ✅ RustDesk
- ✅ DirectX

## Cara Penggunaan

### Instalasi Aplikasi Belum Terinstal
1. Lihat aplikasi dengan status ❌ (belum terinstal/silang)
2. Klik tombol **⬇️ (Install)** berwarna ungu
3. Pilih file installer (.exe atau .msi)
4. Klik **"Instal Sekarang"** untuk memulai instalasi

### Edit Informasi Aplikasi
1. Klik tombol **✏️ (Edit)** berwarna hijau
2. Ubah informasi atau tambah path instalasi
3. Simpan perubahan

### Hapus dari Daftar Default
1. Klik tombol **❌ (Hapus)** berwarna merah
2. Konfirmasi penghapusan
3. Aplikasi akan dihapus dari monitoring

## File yang Diubah

- `lib/widgets/installed_apps_section.dart`
  - Menambahkan method `_showInstallDialog()`
  - Menambahkan method `_showDeleteConfirmationDialog()`
  - Update UI untuk menampilkan tombol Instal dan Hapus

## Integrasi dengan Sistem

- Dialog instalasi terintegrasi dengan `ApplicationService.simulateInstallation()`
- Path installer dapat dibuat portable untuk USB compatibility
- Perubahan disimpan otomatis ke file `application_lists.json`
- Status pembaruan real-time dengan refresh otomatis

## Catatan

- Tombol Instal hanya tampil untuk aplikasi yang belum terinstal (status ❌)
- Tombol Tambah Path dan Edit tersedia untuk menambah path installer manual
- Sistem akan menggunakan tipe file untuk menentukan cara instalasi (MSI atau EXE)
- Semua path dapat dimulai sebagai path portable untuk fleksibilitas USB
