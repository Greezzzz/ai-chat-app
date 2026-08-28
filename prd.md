# Product Requirements Document (PRD)

## Mobile AI Chat Application

**Version:** 1.0
**Platform:** Mobile — Android & iOS
**Frontend Technology:** Flutter
**Backend:** Local Mock API terlebih dahulu, production API menyusul
**Product Type:** AI Conversational Chat Application
**Referensi UX:** ChatGPT / Claude

---

# 1. Product Overview

Aplikasi ini adalah mobile AI assistant yang memungkinkan user melakukan percakapan dengan AI melalui interface chat modern seperti ChatGPT atau Claude.

User dapat:

* Membuat akun
* Login
* Membuat percakapan baru
* Mengirim pesan ke AI
* Melihat respons AI secara streaming
* Melanjutkan percakapan sebelumnya
* Melihat daftar history conversation melalui sidebar
* Berpindah antar conversation
* Memulai conversation baru

Pada tahap awal, aplikasi menggunakan **local mock data / mock API** sehingga frontend dapat dikembangkan dan diuji tanpa menunggu API backend selesai.

Arsitektur aplikasi harus dibuat dengan prinsip **API abstraction**, sehingga ketika API production tersedia, implementasinya cukup mengganti data source/repository tanpa perlu melakukan perubahan besar pada UI.

---

# 2. Goals

## Primary Goals

1. Membuat aplikasi AI chat mobile yang terasa familiar seperti ChatGPT/Claude.
2. Menyediakan pengalaman chat yang cepat dan responsif.
3. Mendukung AI response secara streaming.
4. Menyediakan conversation history yang dapat dilanjutkan.
5. Memisahkan UI, business logic, dan data source.
6. Memungkinkan mock API diganti dengan real API dengan perubahan minimal.

## Non-Goals untuk MVP

Fitur berikut belum menjadi bagian MVP:

* Voice chat
* Image generation
* File upload
* Image upload
* Web browsing
* Plugin/tool system
* Payment/subscription
* Push notification
* Multi-device synchronization
* Admin dashboard
* Social sharing

---

# 3. Target User

Target utama:

* User yang ingin menggunakan AI assistant dari perangkat mobile.
* Developer/professional yang membutuhkan AI untuk pekerjaan sehari-hari.
* User yang membutuhkan percakapan AI yang dapat disimpan dan dilanjutkan.

---

# 4. User Flow

## 4.1 New User

```text
Splash
   ↓
Login / Register
   ↓
Register
   ↓
Login
   ↓
Chat Home
   ↓
New Conversation
   ↓
Input Message
   ↓
AI Streaming Response
   ↓
Conversation tersimpan ke History
```

## 4.2 Existing User

```text
Splash
   ↓
Login
   ↓
Chat Home
   ↓
History Conversation
   ↓
Pilih Conversation
   ↓
Load Previous Messages
   ↓
Continue Chat
```

## 4.3 New Conversation dari Existing Conversation

```text
Chat
 ↓
New Chat
 ↓
Empty Chat State
 ↓
Send Message
 ↓
Create Conversation
 ↓
Streaming AI Response
 ↓
Save Conversation
```

---

# 5. Information Architecture

```text
App
│
├── Authentication
│   ├── Register
│   └── Login
│
└── Main App
    │
    ├── Chat
    │   ├── New Conversation
    │   ├── Existing Conversation
    │   ├── Message Input
    │   └── Streaming Response
    │
    └── Sidebar
        ├── New Chat
        ├── Conversation History
        └── Conversation Selection
```

---

# 6. Screen Requirements

## 6.1 Splash Screen

### Purpose

Menentukan apakah user sudah login atau belum.

### Behavior

Saat aplikasi dibuka:

```text
Check local authentication
        ↓
Authenticated?
   ┌────┴────┐
  Yes        No
   ↓          ↓
Chat Home   Login
```

### MVP

Splash dapat berupa:

* Logo aplikasi
* Loading indicator

Tidak perlu animasi kompleks.

---

# 7. Register Screen

## Components

* App logo
* Title
* Name input
* Email input
* Password input
* Confirm password input
* Register button
* Link "Already have an account? Login"

## Validation

### Name

* Required
* Minimum 2 karakter

### Email

* Required
* Valid email format

### Password

* Required
* Minimum 8 karakter

### Confirm Password

* Required
* Harus sama dengan password

## Success

Setelah register berhasil:

```text
Register
   ↓
Create User
   ↓
Success
   ↓
Login / Auto Login
```

Untuk MVP, boleh menggunakan auto-login setelah register.

## Error States

Contoh:

* Email sudah terdaftar
* Invalid email
* Password terlalu pendek
* Password confirmation tidak sama
* General error

---

# 8. Login Screen

## Components

* Email input
* Password input
* Login button
* Register link

## Behavior

User memasukkan:

```text
email
password
```

Kemudian aplikasi melakukan authentication melalui repository.

Mock implementation akan melakukan validasi terhadap local data.

## Success

```text
Login
 ↓
Save Auth Session
 ↓
Chat Home
```

## Error

Menampilkan error seperti:

> Email atau password salah.

---

# 9. Main Chat Screen

Ini merupakan screen utama aplikasi.

Layout desktop-style sidebar tidak diperlukan secara permanen pada mobile.

Gunakan:

```text
┌──────────────────────────────┐
│ ☰   AI Assistant       ⋮     │
├──────────────────────────────┤
│                              │
│        Conversation          │
│                              │
│ User message                 │
│                       AI msg │
│                              │
│ User message                 │
│                       AI msg │
│                              │
├──────────────────────────────┤
│ Ask anything...        Send  │
└──────────────────────────────┘
```

## Header

Header berisi:

* Hamburger button
* Conversation title
* Optional menu

Hamburger membuka sidebar.

---

# 10. Message UI

Conversation menggunakan pola:

### User

Message user berada di **sisi kanan**.

### Assistant

Message AI berada di **sisi kiri**.

Contoh:

```text
                         ┌───────────────┐
                         │ Halo AI       │
                         └───────────────┘

┌───────────────────────────────┐
│ Halo! Ada yang bisa saya bantu│
└───────────────────────────────┘
```

## Message Properties

Setiap message minimal memiliki:

```text
id
conversationId
role
content
createdAt
status
```

Role:

```text
user
assistant
```

Status:

```text
pending
streaming
completed
error
```

---

# 11. Streaming AI Response

Ini merupakan fitur penting MVP.

Saat user mengirim pesan:

```text
User
 ↓
Send
 ↓
Create User Message
 ↓
Create Assistant Message
 ↓
Start Streaming
 ↓
Receive Chunk
 ↓
Append Chunk
 ↓
Update UI
 ↓
Streaming Complete
```

Contoh:

```text
Chunk 1:
"Halo"

Chunk 2:
", saya"

Chunk 3:
" adalah"

Chunk 4:
" AI assistant."
```

UI harus menampilkan:

```text
Halo
Halo, saya
Halo, saya adalah
Halo, saya adalah AI assistant.
```

bukan menunggu seluruh response selesai.

## Mock Streaming

Karena API belum tersedia, mock API harus mensimulasikan streaming.

Contoh:

```text
Mock response:
"Halo! Saya AI assistant. Ada yang bisa saya bantu hari ini?"
```

Mock service mengirim response per chunk dengan delay:

```text
Halo!
↓ 50ms
 Saya
↓ 50ms
 AI
↓ 50ms
 assistant.
↓ 50ms
 Ada
...
```

Delay dapat dibuat configurable.

Contoh interface:

```text
streamChat(...)
```

Interface ini nantinya dapat menggunakan:

```text
MockChatDataSource
```

atau:

```text
RemoteChatDataSource
```

tanpa mengubah Chat UI.

---

# 12. Chat Input

Bagian bawah screen berisi message composer.

## Components

* Text field
* Send button

Optional state:

### Empty

Send button disabled.

### Typing

Send button enabled.

### Streaming

Send button dapat berubah menjadi:

```text
Stop
```

sehingga user dapat menghentikan generation.

Untuk MVP, fitur Stop boleh dibuat sebagai optional enhancement.

---

# 13. Auto Scroll

Saat streaming:

* Chat otomatis scroll ke message terbaru.
* User tetap dapat melakukan scroll manual.
* Jika user sedang berada jauh dari bottom, aplikasi tidak boleh memaksa scroll setiap chunk.

Recommended behavior:

```text
User at bottom
      ↓
Auto scroll = YES

User scrolls upward
      ↓
Auto scroll = NO
```

Tambahkan optional floating button:

```text
↓
```

untuk kembali ke message terbaru.

---

# 14. Sidebar / Conversation History

Sidebar dibuka melalui hamburger button.

Layout:

```text
┌──────────────────────────────┐
│ New Chat                 +   │
├──────────────────────────────┤
│ Search conversations         │
├──────────────────────────────┤
│ Today                        │
│                              │
│ How to build Flutter app     │
│ Explain React architecture   │
│ Marketing strategy           │
│                              │
│ Yesterday                    │
│                              │
│ Learn Python                 │
│ Product requirements         │
└──────────────────────────────┘
```

## Sidebar Features MVP

### New Chat

Membuat conversation kosong.

### Conversation List

Menampilkan:

* Conversation title
* Last updated
* Optional unread/active indicator

### Select Conversation

Saat conversation dipilih:

```text
Sidebar
 ↓
Select conversation
 ↓
Load messages
 ↓
Close sidebar
 ↓
Show conversation
```

---

# 15. Conversation History

Setiap conversation memiliki:

```text
id
userId
title
createdAt
updatedAt
```

Contoh:

```json
{
  "id": "conv_001",
  "userId": "user_001",
  "title": "Belajar Flutter",
  "createdAt": "2026-08-26T10:00:00Z",
  "updatedAt": "2026-08-26T10:15:00Z"
}
```

## Conversation Title

Untuk MVP, title dapat dibuat dari message pertama.

Contoh:

```text
User:
"Tolong jelaskan state management di Flutter"

Title:
"State management di Flutter"
```

Mock dapat melakukan simple truncation:

```text
firstMessage.substring(0, 40)
```

Nantinya title generation dapat dipindahkan ke backend/AI.

---

# 16. Continue Conversation

Conversation yang sudah ada harus dapat dilanjutkan.

Flow:

```text
History
 ↓
Select conversation
 ↓
Load messages
 ↓
Display previous messages
 ↓
User sends new message
 ↓
AI continues context
```

Pada mock implementation, conversation context dapat disimpan di local memory/database.

---

# 17. Empty Chat State

Saat belum ada message:

```text
         ✨

      AI Assistant

How can I help you today?

[ Explain something ]
[ Write something ]
[ Help me code ]
```

Suggestion chips bersifat optional untuk MVP.

Contoh:

```text
Explain quantum computing
Write a product description
Help me debug code
```

Ketika chip dipilih, text dimasukkan ke composer.

---

# 18. Loading States

## Initial Loading

Saat membuka conversation:

```text
Loading messages...
```

Gunakan skeleton/loading indicator.

## Sending

Setelah user menekan send:

```text
User message
Assistant typing...
```

## Streaming

Tampilkan cursor/indicator:

```text
Assistant:
Halo, saya bisa membantu▌
```

## Error

Jika streaming gagal:

```text
Something went wrong.

[Retry]
```

---

# 19. Error Handling

Semua error harus memiliki state yang jelas.

Kategori:

### Authentication Error

```text
Invalid credentials
Session expired
```

### Network Error

Pada production:

```text
Unable to connect to server.
```

### AI Error

```text
AI response failed.
```

### Unknown Error

```text
Something went wrong.
Please try again.
```

Mock API juga harus dapat mensimulasikan error untuk testing.

---

# 20. Mock API Requirements

Walaupun belum ada API backend, aplikasi **tidak boleh mengakses mock data langsung dari widget/UI**.

Gunakan abstraction:

```text
UI
 ↓
State Management
 ↓
Repository
 ↓
Data Source
 ↓
Mock API
```

Nantinya:

```text
UI
 ↓
State Management
 ↓
Repository
 ↓
Remote API
 ↓
Backend
```

Dengan demikian perubahan dari mock → production hanya mengganti DataSource.

---

# 21. Recommended Architecture

Gunakan pendekatan **Clean Architecture / feature-based architecture** yang tidak terlalu kompleks untuk MVP.

Recommended:

```text
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   └── utils/
│
├── features/
│   │
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── chat/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
└── main.dart
```

---

# 22. Flutter Packages

Package dapat dipilih sesuai kebutuhan implementasi.

Recommended:

### State Management

Salah satu:

* Riverpod
* Bloc

Untuk MVP, **Riverpod** direkomendasikan karena relatif sederhana dan cocok untuk dependency injection/state management.

### Local Storage

Pilihan:

* Hive
* Isar
* SharedPreferences

Recommended:

* SharedPreferences untuk auth/session sederhana.
* Isar/Hive untuk conversation dan messages.

### Networking

Gunakan:

```text
Dio
```

walaupun saat MVP belum melakukan request ke backend.

Dengan demikian interface networking sudah siap ketika API production tersedia.

---

# 23. Domain Models

## User

```text
User
- id
- name
- email
```

## Conversation

```text
Conversation
- id
- userId
- title
- createdAt
- updatedAt
```

## Message

```text
Message
- id
- conversationId
- role
- content
- createdAt
- status
```

---

# 24. Repository Interfaces

## AuthRepository

```text
register()
login()
logout()
getCurrentUser()
isAuthenticated()
```

## ConversationRepository

```text
getConversations()
getConversation(id)
createConversation()
updateConversation()
deleteConversation()
```

## ChatRepository

```text
getMessages(conversationId)
sendMessage()
streamResponse()
```

---

# 25. Data Source

## MockAuthDataSource

```text
register()
login()
logout()
getCurrentUser()
```

## MockConversationDataSource

```text
getConversations()
getConversation()
createConversation()
saveConversation()
```

## MockChatDataSource

```text
getMessages()
streamChat()
```

---

# 26. Production Migration Strategy

Saat API tersedia, implementasi:

```text
MockChatDataSource
```

diganti dengan:

```text
RemoteChatDataSource
```

Contoh:

```text
ChatRepository
      │
      ├── MockChatDataSource
      │
      └── RemoteChatDataSource
```

Dependency injection menentukan datasource yang digunakan.

Environment:

```text
APP_ENV=mock
```

atau:

```text
APP_ENV=production
```

Sehingga developer dapat menjalankan:

```text
Mock Mode
```

tanpa backend.

---

# 27. Mock API Specification

Mock API sebaiknya meniru API production sedekat mungkin.

## Register

```http
POST /auth/register
```

Request:

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

Response:

```json
{
  "user": {
    "id": "user_001",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "token": "mock_token"
}
```

---

## Login

```http
POST /auth/login
```

Request:

```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

Response:

```json
{
  "user": {
    "id": "user_001",
    "name": "John Doe",
    "email": "john@example.com"
  },
  "token": "mock_token"
}
```

---

## Get Conversations

```http
GET /conversations
```

Response:

```json
{
  "data": [
    {
      "id": "conv_001",
      "title": "Belajar Flutter",
      "createdAt": "2026-08-26T10:00:00Z",
      "updatedAt": "2026-08-26T10:15:00Z"
    }
  ]
}
```

---

## Get Conversation Messages

```http
GET /conversations/{conversationId}/messages
```

Response:

```json
{
  "data": [
    {
      "id": "msg_001",
      "conversationId": "conv_001",
      "role": "user",
      "content": "Apa itu Flutter?",
      "createdAt": "2026-08-26T10:00:00Z"
    },
    {
      "id": "msg_002",
      "conversationId": "conv_001",
      "role": "assistant",
      "content": "Flutter adalah framework UI...",
      "createdAt": "2026-08-26T10:00:02Z"
    }
  ]
}
```

---

# 28. Chat Streaming API Contract

Production API kemungkinan akan menggunakan:

* SSE
* HTTP streaming
* WebSocket

Tetapi frontend harus mengabstraksikan transport tersebut.

Interface:

```text
Stream<String> streamChat({
  required String conversationId,
  required String message,
});
```

Mock implementation:

```text
Stream<String>
```

mengirimkan chunk secara berkala.

Contoh:

```text
"Flutter"
" adalah"
" framework"
" UI"
" dari"
" Google."
```

UI tidak perlu mengetahui apakah source-nya:

```text
Mock
```

atau:

```text
SSE
```

---

# 29. Mock Data

Aplikasi harus memiliki seed data untuk development.

Contoh user:

```text
John Doe
john@example.com
password123
```

Contoh conversations:

```text
1. Belajar Flutter
2. Membuat REST API
3. Product Requirements
4. Belajar AI
```

Masing-masing memiliki beberapa message sehingga ketika aplikasi dibuka developer langsung dapat mencoba history.

---

# 30. Persistence

Mock mode sebaiknya tetap memiliki persistence lokal.

Tujuannya agar:

```text
Close app
 ↓
Open app
 ↓
Conversation masih ada
```

Data yang disimpan:

```text
Authentication session
Users
Conversations
Messages
```

Untuk MVP, local database sudah cukup.

---

# 31. Navigation

Recommended navigation:

```text
GoRouter
```

Routes:

```text
/splash
/login
/register
/chat
/chat/:conversationId
```

Protected route:

```text
/chat/*
```

hanya dapat diakses user authenticated.

---

# 32. UI/UX Guidelines

## Design Direction

Visual:

* Clean
* Minimal
* Modern
* Professional
* Tidak terlalu banyak dekorasi

Referensi pengalaman:

* ChatGPT
* Claude

Namun jangan melakukan copy identitas visual/branding secara langsung.

## Typography

Gunakan font system/default Flutter pada MVP.

## Colors

Gunakan theme system agar mudah diubah:

```text
primary
background
surface
text
border
error
```

Dark mode sebaiknya disiapkan sejak awal.

---

# 33. Responsive Layout

Target:

* Android phone
* iPhone

Minimum target width harus tetap usable pada device kecil.

Sidebar pada mobile:

```text
Drawer / Modal Sidebar
```

Bukan fixed desktop sidebar.

Tablet dapat menggunakan layout:

```text
┌────────────┬──────────────────────┐
│ Sidebar    │ Chat                 │
│            │                      │
│ History    │ Conversation         │
│            │                      │
└────────────┴──────────────────────┘
```

Tetapi tablet optimization bukan prioritas MVP.

---

# 34. Accessibility

Minimal:

* Text contrast cukup
* Button memiliki semantic label
* Input memiliki label/hint
* Touch target minimal sekitar 44–48 px
* Keyboard tidak menutupi composer
* Support dynamic text size sejauh memungkinkan

---

# 35. Security

Walaupun menggunakan mock API:

* Jangan menyimpan password plaintext jika tidak diperlukan.
* Jangan hardcode credential production.
* Token disimpan menggunakan secure storage ketika production.
* API key AI tidak boleh ditanam di Flutter application.
* Semua credential/API secret harus berada di backend production.

Catatan penting:

**Flutter app tidak boleh langsung menyimpan OpenAI/Anthropic/provider API key.**

Architecture production:

```text
Flutter
   ↓
Your Backend API
   ↓
AI Provider
```

bukan:

```text
Flutter
   ↓
OpenAI/Anthropic API directly
```

---

# 36. Analytics

Tidak wajib untuk MVP.

Tetapi event berikut sebaiknya sudah dapat dipersiapkan:

```text
register_success
login_success
conversation_created
conversation_opened
message_sent
message_stream_completed
message_stream_failed
```

---

# 37. Acceptance Criteria

## Authentication

### Register

* User dapat membuat account.
* Invalid input menampilkan error.
* Email duplicate ditolak.
* Register berhasil membawa user ke application.

### Login

* User dapat login dengan credential valid.
* Credential invalid menampilkan error.
* Session tersimpan.
* User dapat tetap login setelah restart aplikasi.

---

# 38. Chat Acceptance Criteria

* User dapat membuat conversation baru.
* User dapat mengirim message.
* User message muncul di sisi kanan.
* Assistant message muncul di sisi kiri.
* Assistant response ditampilkan secara streaming.
* UI tetap responsive selama streaming.
* Conversation otomatis tersimpan.
* User dapat melanjutkan conversation.

---

# 39. History Acceptance Criteria

* Sidebar dapat dibuka.
* Conversation history ditampilkan.
* Conversation dapat dipilih.
* Message history dimuat.
* User dapat melanjutkan conversation.
* New Chat membuat conversation baru.
* History tetap tersedia setelah aplikasi restart dalam mock mode.

---

# 40. Streaming Acceptance Criteria

Ketika user mengirim:

```text
Hello
```

Mock API harus mengembalikan response secara bertahap.

Contoh:

```text
Hello
↓
Hello! 
↓
Hello! How
↓
Hello! How can
↓
Hello! How can I
↓
Hello! How can I help?
```

UI harus memperlihatkan perubahan tersebut secara real-time.

Tidak boleh:

```text
[Loading...]
```

kemudian tiba-tiba seluruh response muncul.

---

# 41. Testing Requirements

## Unit Test

Minimal test:

* Auth repository
* Login validation
* Register validation
* Conversation repository
* Message repository
* Mock streaming service
* Conversation title generation

## Widget Test

Test:

* Login screen
* Register screen
* Chat screen
* Message bubble
* Sidebar
* Message composer

## Integration Test

Minimal:

```text
Register
 ↓
Login
 ↓
New Chat
 ↓
Send Message
 ↓
Streaming Response
 ↓
Close App
 ↓
Open App
 ↓
Open History
 ↓
Continue Chat
```

---

# 42. Development Phases

## Phase 1 — Foundation

* Flutter project setup
* Theme
* Routing
* Architecture
* Dependency injection
* Local storage
* Mock environment

## Phase 2 — Authentication

* Register
* Login
* Session
* Logout
* Protected routes

## Phase 3 — Chat

* Chat UI
* User message
* Assistant message
* Composer
* New conversation
* Mock streaming

## Phase 4 — History

* Sidebar
* Conversation list
* Conversation detail
* Continue conversation
* Persistence

## Phase 5 — Polish

* Loading state
* Error state
* Empty state
* Auto-scroll
* Dark mode
* Accessibility
* Animation

## Phase 6 — API Integration

Ketika API backend sudah tersedia:

```text
MockDataSource
       ↓
RemoteDataSource
```

Ganti implementation tanpa melakukan rewrite terhadap UI.

---

# 43. MVP Definition of Done

MVP dianggap selesai apabila user dapat melakukan end-to-end flow:

```text
Register
   ↓
Login
   ↓
New Chat
   ↓
Type Message
   ↓
Send
   ↓
AI Streaming Response
   ↓
Conversation Saved
   ↓
Open Sidebar
   ↓
Select Previous Conversation
   ↓
Read History
   ↓
Continue Conversation
```

Semua flow tersebut harus dapat berjalan **tanpa backend production**, menggunakan mock/local implementation.

---

# 44. Recommended Technical Structure

Struktur final yang direkomendasikan:

```text
lib/
│
├── main.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── router/
│   ├── theme/
│   ├── storage/
│   └── utils/
│
├── features/
│
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_mock_datasource.dart
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   └── chat/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── chat_mock_datasource.dart
│       │   │   └── chat_remote_datasource.dart
│       │   ├── models/
│       │   └── repositories/
│       │
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       │
│       └── presentation/
│           ├── providers/
│           ├── screens/
│           │   └── chat_screen.dart
│           └── widgets/
│               ├── chat_app_bar.dart
│               ├── conversation_drawer.dart
│               ├── message_bubble.dart
│               ├── message_composer.dart
│               └── streaming_indicator.dart
│
└── config/
    └── environment.dart
```

---

# 45. Key Architectural Principle

Prinsip terpenting dari project ini:

> **UI tidak boleh mengetahui apakah data berasal dari Mock API atau Production API.**

Flow yang diharapkan:

```text
                 ┌──────────────────┐
                 │   Flutter UI     │
                 └────────┬─────────┘
                          │
                          ▼
                 ┌──────────────────┐
                 │ State Management │
                 └────────┬─────────┘
                          │
                          ▼
                 ┌──────────────────┐
                 │   Repository     │
                 └────────┬─────────┘
                          │
                 ┌────────┴─────────┐
                 ▼                  ▼
        ┌─────────────────┐  ┌─────────────────┐
        │  Mock DataSource│  │ Remote DataSource│
        └─────────────────┘  └─────────────────┘
                 │                  │
                 ▼                  ▼
           Local Storage        Backend API
                                      │
                                      ▼
                                 AI Provider
```

Dengan architecture ini, pekerjaan frontend dapat berjalan sekarang menggunakan mock, sementara backend API dapat dikembangkan secara paralel.

---

# 46. Future Roadmap

Setelah MVP stabil, fitur dapat ditambahkan:

### V1.1

* Rename conversation
* Delete conversation
* Search history
* Retry failed response
* Stop generation
* Markdown rendering
* Code syntax highlighting
* Copy message
* Regenerate response

### V1.2

* File upload
* Image input
* Model selection
* AI personality/system prompt
* Conversation sharing

### V2

* Voice input
* Voice output
* Web search
* Tool calling
* Custom AI agents
* Subscription
* Usage limits
* Multi-device sync

---

# 47. Priority Matrix

| Feature               | Priority | MVP         |
| --------------------- | -------- | ----------- |
| Register              | P0       | Yes         |
| Login                 | P0       | Yes         |
| Session               | P0       | Yes         |
| New Chat              | P0       | Yes         |
| Send Message          | P0       | Yes         |
| Streaming Response    | P0       | Yes         |
| Message History       | P0       | Yes         |
| Conversation Sidebar  | P0       | Yes         |
| Continue Conversation | P0       | Yes         |
| Local Mock API        | P0       | Yes         |
| Local Persistence     | P0       | Yes         |
| Error Handling        | P0       | Yes         |
| Auto Scroll           | P1       | Yes         |
| Dark Mode             | P1       | Recommended |
| Stop Generation       | P1       | Optional    |
| Rename Conversation   | P2       | No          |
| Delete Conversation   | P2       | No          |
| Search History        | P2       | No          |
| File Upload           | P2       | No          |
| Voice                 | P3       | No          |
| Web Search            | P3       | No          |
| Payment               | P3       | No          |

---

# 48. Final Product Scope

Versi pertama aplikasi harus fokus pada **core conversational experience**:

```text
AUTH
  │
  ▼
CHAT
  │
  ├── New Conversation
  │
  ├── Send Message
  │
  ├── Streaming AI
  │
  └── Save Conversation
          │
          ▼
      HISTORY
          │
          ▼
   Continue Conversation
```

Jangan menambahkan terlalu banyak fitur pada MVP. Prioritas utama adalah membuat **chat terasa cepat, streaming berjalan natural, history reliable, dan architecture siap menerima real API**.

Dengan pendekatan ini, ketika spesifikasi backend sudah diberikan, pekerjaan integrasi idealnya cukup mencakup pembuatan `RemoteDataSource`, mapping response API ke domain model, konfigurasi authentication/networking, serta mengganti dependency dari mock ke remote.
