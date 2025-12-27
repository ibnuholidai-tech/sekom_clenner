# 📦 Assets Requirements

## Required Assets untuk Fitur Modern

### 1. System Tray Icon (Windows)

**File**: `assets/app_icon.ico`
**Format**: ICO (Windows Icon)
**Sizes**: 16x16, 32x32, 48x48, 256x256
**Purpose**: System tray icon

**Cara membuat**:
1. Buat icon di https://www.canva.com atau design tool lainnya
2. Export sebagai PNG (256x256)
3. Convert ke ICO di https://convertio.co/png-ico/
4. Simpan di folder `assets/app_icon.ico`

**Alternative**: Gunakan icon PNG untuk development
```dart
// Di system_tray_service.dart
SystemTrayHelper.getDevIconPath() // Menggunakan PNG
```

---

### 2. Lottie Animations (Optional)

**Folder**: `assets/animations/`
**Format**: JSON
**Purpose**: Smooth animations untuk loading, success, error states

**Download gratis dari**:
- https://lottiefiles.com

**Recommended animations**:
1. **Loading**: `loading.json`
   - https://lottiefiles.com/animations/loading
   
2. **Success**: `success.json`
   - https://lottiefiles.com/animations/success
   
3. **Error**: `error.json`
   - https://lottiefiles.com/animations/error
   
4. **Cleaning**: `cleaning.json`
   - https://lottiefiles.com/animations/cleaning

**Usage**:
```dart
import 'package:lottie/lottie.dart';

Lottie.asset(
  'assets/animations/loading.json',
  width: 200,
  height: 200,
)
```

---

### 3. App Icon (Windows Executable)

**File**: `windows/runner/resources/app_icon.ico`
**Format**: ICO
**Sizes**: 16x16, 32x32, 48x48, 256x256
**Purpose**: Application icon (taskbar, exe file)

**Cara setup**:
1. Buat icon seperti di atas
2. Simpan di `windows/runner/resources/app_icon.ico`
3. Rebuild aplikasi

---

## 📁 Folder Structure

```
assets/
├── app_icon.ico              # System tray icon
├── app_icon.png              # Development icon (alternative)
└── animations/               # Lottie animations (optional)
    ├── loading.json
    ├── success.json
    ├── error.json
    └── cleaning.json
```

---

## ⚙️ Update pubspec.yaml

Pastikan assets sudah terdaftar di `pubspec.yaml`:

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - assets/
    - assets/animations/  # Jika menggunakan Lottie
```

**✅ Sudah terdaftar** - Tidak perlu update lagi karena sudah ada `- assets/`

---

## 🎨 Icon Design Guidelines

### Colors
- **Primary**: Blue (#2196F3)
- **Secondary**: White (#FFFFFF)
- **Accent**: Orange (#FF9800)

### Style
- Modern & minimalist
- Flat design
- Clear & recognizable di size kecil (16x16)

### Suggestions
1. **Broom icon** - Untuk cleaning app
2. **Shield + broom** - Security + cleaning
3. **Gear + broom** - System + cleaning
4. **Speedometer** - Performance optimization

---

## 🔧 Quick Setup (Minimal)

Jika tidak ingin repot dengan custom icons, gunakan default:

1. **System Tray**: Gunakan Flutter logo atau text-based icon
2. **Lottie**: Skip dulu, gunakan SpinKit loading indicators
3. **App Icon**: Gunakan default Flutter icon

**Aplikasi tetap bisa berjalan tanpa custom assets!**

---

## 📝 Notes

- System tray icon **WAJIB** jika menggunakan `SystemTrayService`
- Lottie animations **OPTIONAL** - bisa skip untuk sekarang
- App icon **RECOMMENDED** untuk branding

---

## 🚀 Next Steps

1. ✅ Buat folder `assets/` jika belum ada
2. ⏳ Download atau buat `app_icon.ico`
3. ⏳ (Optional) Download Lottie animations
4. ⏳ Update `pubspec.yaml` jika perlu
5. ⏳ Run `flutter pub get`

---

Semua assets bersifat **optional** untuk development. Aplikasi tetap bisa berjalan tanpa assets ini, tapi akan lebih profesional dengan assets yang proper! 🎨
