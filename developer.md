# Developer Guide — Chat App

Panduan untuk developer yang bekerja pada project ini dari **WSL (Windows Subsystem for Linux)** dengan **Flutter SDK terpasang di Windows**.

---

## 1. Prasyarat

| Komponen  | Lokasi                     | Versi |
| --------- | -------------------------- | ----- |
| Flutter   | `C:\Flutter\flutter`       | 3.47.1 (stable) |
| Dart      | (bundle Flutter SDK)       | 3.13.1 |
| WSL       | Ubuntu / distro apapun     | - |

> **Penting:** Flutter SDK **tidak** boleh dipasang/di-install ulang di dalam WSL.
> SDK hanya ada di Windows (`C:\Flutter\flutter`). Semua perintah Flutter dijalankan
> melalui **Windows interop** (`cmd.exe` → `flutter.bat`).

---

## 2. Setup Wrapper Flutter (wajib sekali)

Script Flutter SDK asli (`bin/shared.sh`, dll.) dikirim dengan **line ending CRLF**,
sehingga tidak bisa dieksekusi langsung oleh bash WSL (error `$'\r': command not found`).

Solusinya: wrapper bash yang meneruskan perintah ke `flutter.bat` Windows.

Buat file `~/.local/bin/flutter`:

```bash
#!/usr/bin/env bash
set -euo pipefail

FLUTTER_BAT='C:\Flutter\flutter\bin\flutter.bat'

exec cmd.exe /c "$FLUTTER_BAT $*"
```

Lalu beri izin eksekusi:

```bash
chmod +x ~/.local/bin/flutter
```

Pastikan `~/.local/bin` ada di `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

> Tambahkan baris `export PATH` tersebut ke `~/.bashrc` / `~/.zshrc` agar permanen.

Verifikasi:

```bash
flutter --version
# Flutter 3.47.1 • channel stable • ...
```

Jika command `flutter` tidak ditemukan di session baru, panggil dengan path penuh:

```bash
~/.local/bin/flutter --version
```

---

## 3. Perintah Harian

Semua perintah dijalankan dari root project (`mobile/chat_app`).

| Tujuan                    | Perintah                          |
| ------------------------- | --------------------------------- |
| Install dependencies      | `flutter pub get`                 |
| Tambah dependency         | `flutter pub add <package>`       |
| Static analysis           | `flutter analyze`                 |
| Unit/widget test          | `flutter test`                    |
| Test file tertentu        | `flutter test test/widget_test.dart` |
| Jalankan app (debug)      | `flutter run`                     |
| Jalankan app di emulator tertentu | `flutter run -d <device-id>` |
| Run mode production (API asli) | lihat §4.4 (`--dart-define=APP_ENV=production`) |
| Build APK                 | `flutter build apk --debug`       |

> Semua perintah akan memakan waktu lebih lama pada **panggilan pertama** karena
> Flutter Windows harus compile toolchain & Gradle (untuk Android).

---

## 4. Menjalankan Aplikasi

### 4.1 Pilih device

```bash
flutter devices
```

Contoh output (lewat Windows):

```text
Android SDK built for x86_64 (mobile) • emulator-5554
Windows (desktop)                     • windows
Chrome (web)                          • chrome
```

### 4.2 Jalankan

```bash
# Di emulator Android / device fisik
flutter run -d emulator-5554

# Di Chrome (paling cepat untuk cek UI)
flutter run -d chrome
```

> Karena toolchain berjalan di sisi Windows, emulator/device yang dipakai juga
> harus yang dikelola dari Windows (Android Studio / AVD Manager Windows).

### 4.3 Menjalankan Virtual Device (Android Emulator) dari Terminal

Semua perintah emulator dijalankan lewat **Windows** (emulator adalah aplikasi
Windows). Dari WSL, kita memanggilnya via `cmd.exe`.

**1) Lihat daftar AVD (virtual device) yang tersedia**

```bash
# Cara 1: lewat Flutter (paling simpel)
flutter emulators

# Cara 2: langsung dari SDK
cmd.exe /c "C:\Users\user\AppData\Local\Android\sdk\emulator\emulator.exe -list-avds"
```

Output `flutter emulators` contohnya:

```text
2 available emulators:

Pixel_8_API_34   • Pixel 8 • Google APIs • android-34 • Android 13
```

**2) Nyalakan emulator**

```bash
# Dari nama AVD (pakai nama persis dari daftar di atas)
cmd.exe /c "C:\Users\user\AppData\Local\Android\sdk\emulator\emulator.exe -avd Pixel_8_API_34"

# Atau lewat Flutter
flutter emulators --launch Pixel_8_API_34
```

> Emulator berjalan di **background** (window emulator terbuka). Biarkan
> prosesnya berjalan; jangan tutup terminal-nya.

**3) Cek device terdeteksi**

```bash
flutter devices
```

Tunggu sampai emulator selesai boot (muncul di daftar dengan id seperti
`emulator-5554`). Butuh beberapa saat pada boot pertama.

**4) Jalankan app di emulator**

```bash
flutter run -d emulator-5554
```

> Gunakan id dari `flutter devices`, bisa `emulator-5554`, `Pixel_8_API_34`,
> atau yang lain — tidak harus persis contoh di atas.

**5) Shortcut saat `flutter run` aktif**

| Tombol | Fungsi |
| ------ | ------ |
| `r` | Hot reload (cepat, pertahankan state) |
| `R` | Hot restart (reset state) |
| `q` | Keluar / stop app |

**Membuat AVD baru (jika belum ada)**

```bash
# Pastikan AVD manager ada di SDK
ls /mnt/c/Users/user/AppData/Local/Android/sdk/cmdline-tools

# Buat AVD (contoh: Pixel 8, API 34)
cmd.exe /c "C:\Users\user\AppData\Local\Android\sdk\cmdline-tools\latest\bin\avdmanager.bat create avd -n Pixel_8_API_34 -k system-images;android-34;google_apis;x86_64"
```

Jika `cmdline-tools` belum terinstall, buka Android Studio → SDK Manager →
install "Android SDK Command-line Tools", atau buat AVD langsung dari
Android Studio (Device Manager).

### 4.4 Mode mock vs production

App punya **2 mode data** (PRD §45 — UI tidak tahu sumber data). Mode dipilih
via `--dart-define` saat run; **tidak ada file `.env`** di Flutter. Konfigurasi
dibaca dari `lib/config/environment.dart` (`APP_ENV` & `API_BASE_URL`).

**Mode mock (default, tanpa backend):**

```bash
flutter run -d emulator-5554
# atau
flutter run -d chrome
```

Semua data dari `MockChatDataSource`: streaming simulasi per-kata, respons
canned, persisten di Hive lokal. Tidak butuh backend sama sekali.

**Mode production (backend ai-backend-v2 asli):**

```bash
flutter run -d emulator-5554 --dart-define=APP_ENV=production --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

- Pastikan backend **sudah running** di `127.0.0.1:8000` (lihat repo
  `ai-backend-v2`, jalankan `uv run uvicorn app.main:app` dari folder tersebut).
- **Android emulator:** `127.0.0.1` otomatis di-rewrite ke `10.0.2.2` oleh
  `core/utils/api_base_url.dart` (host loopback Windows tidak bisa diakses
  emulator lewat `127.0.0.1`).
- **Windows desktop / Chrome:** tanpa rewrite — langsung pakai `127.0.0.1:8000`
  (jalan di sisi host yang sama dengan backend).
- Di mode ini yang dipakai `ChatRemoteDataSource`: list conversation + streaming
  SSE (`POST /api/chat/stream`). Backend pegang persistence; Hive tidak dipakai
  untuk chat.
- **History chat:** `GET /api/chat/conversations/{id}` mengembalikan metadata +
  seluruh riwayat pesan — membuka conversation dari drawer menampilkan
  pesan-pesan sebelumnya (bukan kosong).

**Mengubah default ke production (tanpa flag tiap run):**

Edit `lib/config/environment.dart`:

```dart
static const String _env = String.fromEnvironment('APP_ENV',
    defaultValue: 'production');   // default: 'mock'
```

Disarankan tetap pakai flag supaya mode mock gampang dipakai untuk
development/testing.

---

## 5. Data & Akun Demo (Mock Mode)

Saat pertama kali app dijalankan, database lokal di-seed otomatis:

- **Akun:** `john@example.com` / `password123`
- **Conversations seed:** Belajar Flutter, Membuat REST API, Product Requirements, Belajar AI
- **Storage lokal:** Hive (conversations, messages, users) + SharedPreferences (session)

Reset data mock: hapus folder data app di device, atau clear Hive boxes
via `AppDatabase.clearAll()`.

**Jika login/registrasi macet di emulator** (data Hive lama rusak / session
nyangkut), reset lewat salah satu cara:

```bash
# Cara 1 (tanpa kode): uninstall → data ikut terhapus
adb uninstall com.example.chat_app

# Cara 2: tombol debug di layar login (hanya di build debug)
#   "Reset local data (debug)" — clear Hive + session, langsung kembali ke
#   first-run, seed jalan lagi.
```

---

## 6. Struktur Project

```text
lib/
├── main.dart                 # Entry point (init storage → runApp)
├── config/
│   └── environment.dart      # APP_ENV, API_BASE_URL
├── core/
│   ├── constants/            # AppConstants
│   ├── errors/               # AppException, AuthException, NetworkException, ...
│   ├── router/               # GoRouter + auth redirect
│   ├── storage/              # AppDatabase (Hive), SessionStore, SeedData
│   ├── theme/                # Neo-brutalism theme (colors, spacing, shadows, typography)
│   ├── ui/components/        # UI kit reusable (NeoSurface, AppButton, AppTextField, ...)
│   └── utils/                # HashUtil, dll.
├── features/
│   ├── auth/
│   │   ├── data/             # datasources (mock/remote), models, repositories
│   │   ├── domain/           # entities, repositories, usecases
│   │   └── presentation/     # providers, screens, widgets
│   └── chat/                 # (struktur sama dengan auth)
└── test/                     # unit & widget test
```

Arsitektur: **Clean Architecture / feature-based** — UI tidak tahu apakah data
berasal dari mock atau production (lihat PRD §45). Migrasi mock → remote cukup
mengganti `DataSource` di `authDataSourceProvider` / `chatDataSourceProvider`.

---

## 7. Testing

```bash
# Semua test
flutter test

# Satu file
flutter test test/widget_test.dart

# Integration test (E2E) di emulator/device Android
flutter test integration_test/app_test.dart -d emulator-5554

# Dengan output per-test
flutter test --reporter expanded
```

> **Integration test butuh device/emulator aktif** (bukan virtual FakeAsync);
> dijalankan dengan `-d <device-id>`. Menjalankan alur nyata: register → restore
> session → login → chat → streaming, terhadap Hive + SharedPreferences asli.

> **Catatan penting untuk test:** Inisialisasi Hive (file I/O) tidak bisa berjalan
> di dalam `testWidgets` (FakeAsync zone). Setup storage selalu dilakukan di
> `setUpAll` dengan `AppDatabase.init(path: <tempDir>)` — lihat `test/widget_test.dart`
> sebagai referensi.

---

## 8. Troubleshooting

### `$'\r': command not found`
Script bash Flutter SDK tidak dipanggil langsung. Gunakan wrapper (section 2).

### `flutter: command not found`
PATH belum di-set. Panggil `~/.local/bin/flutter` atau export PATH.

### Perintah lambat / terasa "hang" di panggilan pertama
Normal — Flutter Windows/Gradle melakukan compile awal. Tunggu sampai selesai.

### Test hang selamanya di `testWidgets`
Kemungkinan ada file I/O (Hive/path_provider) di dalam test. Pindahkan ke `setUpAll`.

### Emulator tidak terdeteksi
Pastikan emulator dijalankan dari Windows (Android Studio AVD Manager), bukan dari WSL.
