# Sound Test Audio Asset

## File Audio untuk Testing Sound L/R

File audio yang digunakan untuk testing sound:
- **Nama File**: `ringtone-193209.mp3`
- **Lokasi**: `assets/ringtone-193209.mp3`
- **Ukuran**: ~65KB
- **Fungsi**: Digunakan untuk testing speaker/headphone kiri dan kanan

## Perubahan dari Windows Default Sound

### Masalah Sebelumnya:
- Menggunakan Windows default sound yang sering menyebabkan force close
- Tidak reliable dan tergantung pada sistem Windows

### Solusi Saat Ini:
- Menggunakan file audio dari assets yang sudah di-bundle dengan aplikasi
- Lebih stable dan tidak tergantung pada sistem Windows
- Menambahkan error handling yang comprehensive untuk mencegah crash

## Implementasi

File audio di-load menggunakan `audioplayers` package dengan `AssetSource`:

```dart
await _player.play(ap.AssetSource('ringtone-193209.mp3'));
```

### Fitur Save Volume

Aplikasi sekarang menyimpan pengaturan volume yang dipilih user menggunakan `SharedPreferences`:

- **Auto-Save**: Volume otomatis disimpan saat slider diubah
- **Auto-Load**: Volume yang tersimpan akan di-load saat aplikasi dibuka kembali
- **Persistent**: Pengaturan tetap tersimpan meskipun aplikasi ditutup atau device restart

Implementasi:
```dart
// Save volume
final prefs = await SharedPreferences.getInstance();
await prefs.setDouble('sound_test_volume', volume);

// Load volume
final savedVolume = prefs.getDouble('sound_test_volume');
```

## Error Handling

Semua operasi audio dibungkus dengan try-catch untuk mencegah force close:

1. **Play Operations**: Menangkap error saat memutar audio
2. **Stop Operations**: Menangkap error saat menghentikan audio
3. **State Management**: Menggunakan `mounted` check untuk mencegah setState pada disposed widget
4. **User Feedback**: Menampilkan pesan error yang jelas kepada user

## Cara Menambah/Mengganti File Audio

1. Letakkan file audio (.mp3, .wav, dll) di folder `assets/`
2. Pastikan file sudah terdaftar di `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/
   ```
3. Update kode di `sound_test_lr.dart` untuk menggunakan nama file yang baru
4. Jalankan `flutter clean` dan `flutter pub get`

## Testing

Untuk testing sound L/R:
1. Buka aplikasi
2. Navigasi ke Testing tab
3. Pilih "Sound L/R Test"
4. Test dengan:
   - Play Left: Suara hanya di speaker/headphone kiri
   - Play Right: Suara hanya di speaker/headphone kanan
   - Both (L+R): Suara di kedua speaker/headphone
   - Stop: Menghentikan playback

## Troubleshooting

Jika masih terjadi force close:
1. Pastikan file audio ada di folder assets
2. Cek log error untuk detail masalah
3. Pastikan package `audioplayers` sudah terinstall dengan benar
4. Coba gunakan file audio dengan format berbeda (mp3, wav, ogg)
