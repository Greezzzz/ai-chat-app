# Agents.md — Project Context & Handoff

Dokumen acuan untuk agent (dan developer) saat memulai/melanjutkan pekerjaan di
project ini. Baca dulu sebelum mulai mengerjakan apa pun.

---

## 1. Ringkasan Project

**Mobile AI Chat App** — aplikasi chat AI untuk Android & iOS.

- **Teknologi:** Flutter 3.47.1 / Dart 3.13.1 (stable)
- **Backend:** Local Mock API (MVP) → production API menyusul
- **Referensi UX:** ChatGPT / Claude (tanpa menyalin branding)
- **Tema:** Neo-brutalism (keputusan user; PRD §32 minta clean/minimal, tapi
  user memilih neo-brutalism — diikuti dengan restrain/design theory agar
  proporsional)
- **PRD:** `prd.md` (48 section — baca untuk detail lengkap)

---

## 2. Environment & Toolchain (WAJIB BACA)

### Flutter di Windows, kerja dari WSL

- Flutter SDK **hanya** di Windows: `C:\Flutter\flutter`
- SDK shell script-nya CRLF, jadi **tidak bisa** dipanggil langsung dari bash WSL
- Semua perintah Flutter lewat **wrapper** `~/.local/bin/flutter` yang memanggil
  `flutter.bat` via `cmd.exe`. Jika `flutter` tidak ketemu, pakai
  `~/.local/bin/flutter`.

```bash
~/.local/bin/flutter --version
~/.local/bin/flutter pub get
~/.local/bin/flutter analyze
~/.local/bin/flutter test
```

### Perintah penting

| Tujuan | Perintah |
| ------ | -------- |
| Static analysis | `~/.local/bin/flutter analyze` |
| Semua test | `~/.local/bin/flutter test` |
| Test 1 file | `~/.local/bin/flutter test test/widget_test.dart` |
| Integration test (E2E) | `~/.local/bin/flutter test integration_test/app_test.dart -d emulator-5554` |
| Test 1 test | pakai `--plain-name "nama tanpa titik dua"` (colon crash di Windows path) |
| Run app | `~/.local/bin/flutter run -d chrome` (cepat) / `-d emulator-5554` |

### Emulator Android dari terminal

```bash
~/.local/bin/flutter emulators
cmd.exe /c "C:\Users\user\AppData\Local\Android\sdk\emulator\emulator.exe -avd <nama>"
~/.local/bin/flutter devices
~/.local/bin/flutter run -d emulator-5554
```

Detail lengkap: `developer.md` section 4.3.

---

## 3. Status Pekerjaan

### ✅ Selesai

- [x] **Setup project** — scaffold Flutter (android+ios), dependencies:
  `flutter_riverpod`, `go_router`, `hive_ce` + `hive_ce_flutter`,
  `shared_preferences`, `dio`, `path_provider`, `crypto`
- [x] **Theme neo-brutalism** — `core/theme/`: `AppColors`, `AppSpacing`
  (scale 4px), `AppTypography` (type ramp), `AppShadows` (hard shadow),
  `NeoTheme` (ThemeExtension, light+dark), `AppTheme` (ThemeData)
- [x] **UI kit reusable** — `core/ui/components/`: `NeoSurface`, `AppButton`
  (4 varian + loading), `AppTextField` (validator), `FormErrorBanner`,
  `SkeletonLoader`, `EmptyState`, `ErrorState`
- [x] **Storage** — `core/storage/`: `AppDatabase` (Hive, 3 box:
  users/conversations/messages), `SessionStore` (SharedPreferences),
  `SeedData` (John Doe + 4 conversations), storage providers
- [x] **Auth feature lengkap** — domain (User, AuthRepository, usecases),
  data (`AuthMockDataSource` + `AuthRemoteDataSource` lengkap: register
  auto-login, login, logout, me + token refresh), presentation
  (`AuthController`, Splash/Login/Register + validators)
- [x] **Router** — `core/router/app_router.dart`: GoRouter dengan auth
  redirect (splash → login/chat), protected `/chat/*`
- [x] **Chat feature lengkap** — domain (Conversation, Message, usecases,
  title generator), data (`MockChatDataSource` streaming + `ChatRemoteDataSource`
  SSE + `ChatRepositoryImpl`), presentation (`ChatController`, ChatScreen,
  MessageBubble, MessageComposer, ConversationDrawer, EmptyChatState)
- [x] **Streaming** — mock stream per-kata, delay configurable, thinking
  delay, canned responses (deteksi kata kunci), persist incremental
- [x] **Remote chat API (ai-backend-v2)** — `ChatRemoteDataSource` lengkap:
  `GET /api/chat/conversations` (list), `GET /api/chat/conversations/{id}`
  (metadata + **riwayat pesan**), `POST /api/chat/stream` (SSE
  `data: {"delta"}` + `[DONE]`), auth header Bearer, mapping error contract
  `{code, message, details}`. Backend pegang persistence (repo skip Hive via
  `persistsLocally`). New chat di remote: backend buat conversation saat pesan
  pertama, client discover id via re-list **hanya** setelah pesan pertama
  new chat selesai (bukan tiap pesan)
- [x] **Mock chat per-user** — `MockChatDataSource._currentUserId` baca dari
  session (`SessionStore`), bukan hardcoded `'user_001'`
- [x] **API base URL helper** — `core/utils/api_base_url.dart`: Android emulator
  → `10.0.2.2`, platform lain → `127.0.0.1` (dipakai auth + chat remote)
- [x] **Client trace id** — `core/network/client_trace.dart`: kirim header
  W3C `traceparent` (`00-<traceId32hex>-<spanId16hex>-01`) + `X-Trace-Id`
  (trace id yang sama) di semua request auth + chat via Dio interceptor;
  backend OTel mengadopsi trace id klien → bisa dicari di Jaeger
- [x] **History** — drawer dengan group Today/Yesterday/Older, select
  conversation, continue chat, persist Hive
- [x] **Streaming stabil** — throttle rebuild UI (80ms) di `ChatController`
  supaya respons panjang tidak freeze (hindari O(n²) `toString()` + copy list
  per chunk); chat singkat tidak stuck (konten penuh di-set di `onDone`)
- [x] **Reset chat state saat logout** — `ChatController.reset()` dipanggil
  dari `main.dart` (`ref.listen` saat auth jadi `unauthenticated`) + tombol
  logout, supaya login berikutnya tidak auto-select conversation lama
- [x] **Logout button** — di drawer (ikon + teks merah), panggil
  `AuthController.logout()` → redirect ke login
- [x] **Test** — 22 test lolos (auth widget + chat widget flow + remote chat
  unit test: SSE parsing, error event, token requirement, list mapping,
  message history, persistsLocally + title generator/streaming + UserModel
  int-id parsing + ClientTraceId) + **1 integration test E2E Android hijau**
  di `emulator-5554` (`integration_test/app_test.dart`: register → restore
  session → login → chat → streaming → history)
- [x] **Docs** — `developer.md` (running project), `prd.md` (acuan)
- [x] **GitHub repo** — https://github.com/Greezzzz/ai-chat-app (public,
  branch `master`), di-push via `gh repo create`
- [x] **RAG context (V1)** — di new chat ada tombol "Add context": form
  title + isi konteks → upload `POST /api/rag/documents` → `document_id`
  disimpan sebagai `pendingDocument` di `ChatController` → dikirim bersama
  pesan pertama (`POST /api/chat/stream` body `document_id`) → ter-bind ke
  percakapan (backend). Chip indikator konteks di atas composer; popup
  konfirmasi saat back/new chat jika konteks belum terpakai. `Conversation`
  punya field `documentId` (parsing dari list/detail API)

### ⬜ Belum / Next Steps

- [ ] **Polish phase (PRD Phase 5)** — sebagian sudah (loading/error/empty
  state, auto-scroll, dark mode jalan via theme), sisanya:
  - Stop generation → sudah ada tombol stop di composer, test manual belum
  - Animation halus (transisi antar screen, message masuk)
  - Accessibility audit (semantic labels, touch target audit)
- [ ] **ChatScreen `_userScrolledUp`** — auto-scroll behavior perlu dicek
  manual; logika `_onScroll` masih sederhana
- [ ] **Sidebar search** — search box ada di PRD §14 layout tapi belum
  berfungsi (V1.1)
- [ ] **Retry failed message** — message status `error` sudah ada, tombol
  retry belum
- [ ] **Markdown rendering** untuk message AI (V1.1, opsional)
- [ ] **coba `flutter run -d chrome`** untuk melihat UI sebenarnya (belum
  pernah dijalankan visual)

---

## 4. Arsitektur

**Clean Architecture / feature-based** (PRD §44). Prinsip kunci (PRD §45):
**UI tidak boleh tahu apakah data dari mock atau production.**

```text
lib/
├── main.dart                 # init storage → runApp (UncontrolledProviderScope)
├── config/environment.dart   # APP_ENV=mock|production, API_BASE_URL
├── core/
│   ├── constants/  errors/  router/  storage/  theme/  ui/components/  utils/
└── features/
    ├── auth/  (data/ domain/ presentation/)
    └── chat/  (data/ domain/ presentation/)
```

### Layer flow

```text
UI → State (Riverpod StateNotifier) → UseCase → Repository (interface)
   → DataSource (Mock | Remote) → Hive / Backend
```

### Pola Riverpod yang dipakai

- `Provider` untuk usecases & repository (DI)
- `StateNotifierProvider` untuk controller (`AuthController`, `ChatController`)
- `FutureProvider` untuk init (`storageInitProvider`)
- Storage di-inject via `ProviderContainer(overrides: [...])` di `main()`
  (lihat section 5.2)

### Router auth flow

- `/splash` → restore session → redirect ke `/login` atau `/chat`
- Redirect logic baca `currentAuthState` (global di app_router.dart),
  di-update oleh `ChatApp` via `ref.listen` → `_router.refresh()`
- Jangan pindahkan ke `ref.listen` di dalam provider body — itu hang (lihat 5.4)

---

## 5. Keputusan Teknis & Pitfalls (PENTING)

### 5.1 Password hashing (mock)

`HashUtil` (SHA-256 + salt per user) di `core/utils/`. Production: backend
yang pegang verifikasi — **jangan** simpan password di client.

### 5.2 Storage init di main()

```dart
final container = ProviderContainer();
await container.read(storageInitProvider.future);
await container.read(seedDataProvider.future);
runApp(UncontrolledProviderScope(container: container, child: const ChatApp()));
```

**Jangan** dispose container setelah runApp (app butuh akses storage via
`AppDatabase.instance`).

### 5.3 Test + Hive + FakeAsync (sering jadi masalah)

- `testWidgets` pakai FakeAsync zone — **file I/O (Hive, path_provider) HANG**
  di dalamnya
- **Solusi:** init Hive di `setUpAll` (real async zone) dengan
  `AppDatabase.init(path: tempDir)`, share db antar test
- Widget test yang butuh chat streaming: **override `chatRepositoryProvider`**
  dengan fake in-memory repository (lihat `_FakeChatRepository` di
  `test/widget_test.dart`) — jangan pakai repository asli yang nulis ke Hive
- `SharedPreferences.setMockInitialValues({})` per test, buat container baru
  per test
- `pumpAndSettle` **hang** kalau ada animasi infinite (CircularProgressIndicator
  di splash) — pakai `pump(Duration)` eksplisit

### 5.4 GoRouter + Riverpod

- Router dibuat sekali di `appRouterProvider` (Provider)
- `currentAuthState` global diupdate dari `ChatApp` (ConsumerStatefulWidget)
  via `ref.listen` → `_router.refresh()`
- **Jangan** pakai `ref.listen` di dalam body provider (hang/leak); jangan
  recreate router tiap auth berubah (state navigasi hilang)
- Splash harus redirect keluar setelah status diketahui (jangan biarkan
  user diam di splash saat unauthenticated)

### 5.5 Streaming design

- `MockChatDataSource.streamChat` yield per kata, `chunkDelay` configurable
- `ChatRepositoryImpl.sendMessage` orkestrasi: create conv (jika baru),
  persist user msg, persist chunk incrementally, update title dari first
  message (`ConversationTitleGenerator`, truncate 40 + ellipsis)
- `ChatController` akumulasi chunk via `StringBuffer` (jangan pakai
  `state.messages.last.content` — race condition)
- **Penting:** `onDone` stream harus update status message terakhir ke
  `completed` — kalau tidak, cursor streaming nyangkut selamanya (bug yang
  sudah diperbaiki)

### 5.6 UI kit

- Semua warna/efek baca dari `Theme.of(context).extension<NeoTheme>()!` —
  jangan hardcode warna di widget
- Spacing pakai `AppSpacing.*` (scale 4px) — jangan angka random
- Komponen baru yang reusable taruh di `core/ui/components/`, bukan
  duplikasi di feature

### 5.7 Device macet di login/register (auth lockout)

Kode mock auth **logis benar** (salt/hash/session/seed sinkron — widget test
terbukti). Di emulator, login & register "selalu gagal" biasanya karena **data
lokal stale** di Hive/SharedPreferences (row user korup dari run yang
terpotong, atau session `auth_user_id` menunjuk user yang sudah hilang).
`UserModel.fromJson` yang lempar `TypeError` akan di-swallow jadi pesan generik
"Gagal masuk/mendaftar". Recovery:

- **Tombol debug** di layar login (`kDebugMode` only): "Reset local data
  (debug)" → `resetLocalDataProvider` → clear Hive + session, kembali ke
  first-run dan seed jalan lagi.
- **Tanpa kode:** `adb uninstall com.example.chat_app` lalu `flutter run`
  ulang (data ikut terhapus).

Jangan "perbaiki" hash/salt karena tampak gagal — verifikasi dulu apakah
widget test yang pakai mock asli (seed box) tetap lolos. Kalau lolos, masalah
pasti di persistence, bukan logika auth. `flutter_01.log`/`flutter_02.log` di
root adalah crash lama yang **tidak relevan**: itu dari `flutter test
--plain-name "...colon..."` crash di path Windows (lihat §2 pitfall), bukan
dari bug ini.

### 5.8 `AppDatabase.init` idempotent

`AppDatabase.instance` adalah **singleton global**. Saat integration test
(E2E) memanggil `storageInitProvider` untuk mensimulasikan relaunch, `init()`
bisa terpanggil dua kali dalam satu proses → `LateInitializationError: Field
'instance' has already been initialized`. `init()` sekarang **re-entrant**
(guard `_initialized`: kembalikan instance yang ada). Jangan hapus guard ini —
widget & integration test sama-sama mengandalkannya.

---

## 6. Struktur File Kunci

```text
lib/core/router/app_router.dart          # GoRouter + redirect
lib/core/storage/app_database.dart       # Hive init (path optional utk test)
lib/core/storage/seed_data.dart          # seed user + 4 conversations
lib/core/storage/storage_providers.dart  # storageInitProvider, sessionStore
lib/core/debug/reset_local_data.dart     # recovery: clear Hive + session
lib/core/theme/neo_theme.dart            # ThemeExtension light+dark
lib/core/theme/app_theme.dart            # ThemeData lengkap
lib/core/ui/components/                  # UI kit
lib/features/auth/presentation/providers/auth_controller.dart
lib/features/auth/presentation/screens/  # splash, login, register
lib/features/chat/presentation/providers/chat_controller.dart
lib/features/chat/presentation/screens/chat_screen.dart
lib/features/chat/presentation/widgets/  # bubble, composer, drawer, dll
lib/features/chat/data/datasources/chat_mock_datasource.dart
lib/features/chat/data/repositories/chat_repository_impl.dart
test/widget_test.dart                    # auth + chat flow (fake repo)
test/chat_unit_test.dart                 # title generator + streaming
integration_test/app_test.dart           # E2E Android
```

---

## 7. Data Demo (Mock)

- Akun: `john@example.com` / `password123`
- Seed conversations: Belajar Flutter, Membuat REST API, Product Requirements,
  Belajar AI (masing-masing punya messages)
- Reset data: tombol "Reset local data (debug)" di layar login (`kDebugMode`
  only), `AppDatabase.clearAll()`, atau hapus folder app di device /
  `adb uninstall com.example.chat_app`

---

## 8. Definisi Selesai (PRD §43)

End-to-end tanpa backend:
`Register → Login → New Chat → Type → Send → AI Streaming → Saved → Sidebar
→ Select → Read History → Continue Chat`

Semua harus jalan di mock mode. Saat ini tercapai dan **terverifikasi lewat
integration test E2E** (`integration_test/app_test.dart`) di emulator Android
(register → restore session → login → chat → streaming → history). Verifikasi
visual opsional masih terbuka via `flutter run -d chrome`.
