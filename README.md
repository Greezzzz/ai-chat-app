# Chatly — Mobile AI Chat App

Aplikasi chat AI untuk Android & iOS dengan UI neo-brutalism, dibangun dengan
Flutter. Backend: `ai-backend-v2` (repo terpisah).

## Prasyarat

- Flutter SDK di Windows (`C:\Flutter\flutter`) — dipanggil dari WSL via
  wrapper `~/.local/bin/flutter` (lihat `developer.md` section 2)
- Backend `ai-backend-v2` berjalan untuk mode production

## Mode data

App punya 2 mode (PRD §45 — UI tidak tahu sumber data):

| Mode | Perintah run | Data |
| ---- | ------------ | ---- |
| **Mock** (default) | `flutter run` | Lokal Hive, streaming simulasi, tanpa backend |
| **Production** | `flutter run --dart-define=APP_ENV=production --dart-define=API_BASE_URL=<url>` | API `ai-backend-v2` (SSE streaming, RAG, dll.) |

> Android emulator: `API_BASE_URL=http://127.0.0.1:8000` otomatis di-rewrite ke
> `10.0.2.2` oleh `lib/core/utils/api_base_url.dart`. Device fisik butuh IP LAN
> komputer (lihat build APK di bawah).

## Menjalankan

```bash
# Mode mock (tanpa backend)
~/.local/bin/flutter run -d emulator-5554

# Mode production (backend asli)
~/.local/bin/flutter run -d emulator-5554 \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Build APK (install ke HP)

```bash
# APK production — nyambung ke backend asli (REKOMENDASI untuk HP)
~/.local/bin/flutter build apk --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=http://<IP-LAN-KOMPUTER>:8000

# APK mock — demo offline tanpa backend (data lokal)
~/.local/bin/flutter build apk --release
```

Hasil: `build/app/outputs/flutter-apk/app-release.apk` — transfer ke HP dan install.

### Catatan build APK production

- **`API_BASE_URL` harus IP LAN komputer** (contoh `http://192.168.1.5:8000`),
  bukan `127.0.0.1`/`10.0.2.2` — di HP fisik kedua alamat itu tidak menunjuk ke
  komputer. Cek IP: `ipconfig` di Windows (cari IPv4 adapter WiFi/LAN).
- HP dan komputer harus **satu jaringan WiFi**.
- Backend harus **listen di `0.0.0.0`** (bukan cuma `127.0.0.1`) supaya bisa
  diakses dari HP, dan port `8000` tidak diblokir firewall Windows.
- **Signing**: `--release` butuh keystore. Untuk dev/testing, Flutter bisa pakai
  debug signing (lihat `android/app/build.gradle.kts`); untuk distribusi publik
  siapkan keystore release sendiri.

## Testing

```bash
# Semua test
~/.local/bin/flutter test

# Satu file
~/.local/bin/flutter test test/widget_test.dart

# Integration test E2E (butuh emulator aktif)
~/.local/bin/flutter test integration_test/app_test.dart -d emulator-5554
```

## Dokumentasi

- `developer.md` — panduan developer (setup WSL, perintah, troubleshooting)
- `prd.md` — product requirements
- `AGENTS.md` — status pekerjaan & arsitektur (baca sebelum mulai bekerja)
