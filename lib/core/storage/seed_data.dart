import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/utils/hash_util.dart';

/// Seeds the local database with demo data on first launch (PRD §29).
///
/// Only runs when the users box is empty, so it never overwrites real data.
class SeedData {
  const SeedData(this._db, this._hash);

  final AppDatabase _db;
  final HashUtil _hash;

  Future<void> seedIfNeeded() async {
    if (_db.users.isNotEmpty) return;

    final salt = 'seed';
    final user = <String, dynamic>{
      'id': 'user_001',
      'username': AppConstants.seedUserUsername,
      'name': 'John Doe',
      'email': AppConstants.seedUserEmail,
      'passwordHash': _hash.hash(AppConstants.seedUserPassword, salt: salt),
      'salt': salt,
    };
    await _db.users.put('user_001', user);

    final now = DateTime.now();
    final seeds = _seedConversations(now);
    for (final c in seeds) {
      await _db.conversations.put(c['id'], c);
    }
    for (final m in _seedMessages(now)) {
      await _db.messages.put(m['id'], m);
    }
  }

  List<Map<String, dynamic>> _seedConversations(DateTime now) {
    final today = now;
    final yesterday = now.subtract(const Duration(days: 1));
    final twoDaysAgo = now.subtract(const Duration(days: 2));

    return [
      {
        'id': 'conv_001',
        'userId': 'user_001',
        'title': 'Belajar Flutter',
        'createdAt': today.subtract(const Duration(hours: 3)).toIso8601String(),
        'updatedAt': today.subtract(const Duration(minutes: 30)).toIso8601String(),
      },
      {
        'id': 'conv_002',
        'userId': 'user_001',
        'title': 'Membuat REST API',
        'createdAt': yesterday.subtract(const Duration(hours: 5)).toIso8601String(),
        'updatedAt': yesterday.subtract(const Duration(hours: 4)).toIso8601String(),
      },
      {
        'id': 'conv_003',
        'userId': 'user_001',
        'title': 'Product Requirements',
        'createdAt': yesterday.subtract(const Duration(hours: 8)).toIso8601String(),
        'updatedAt': yesterday.subtract(const Duration(hours: 7)).toIso8601String(),
      },
      {
        'id': 'conv_004',
        'userId': 'user_001',
        'title': 'Belajar AI',
        'createdAt': twoDaysAgo.toIso8601String(),
        'updatedAt': twoDaysAgo
            .add(const Duration(minutes: 20))
            .toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> _seedMessages(DateTime now) {
    final base = now.subtract(const Duration(hours: 3));

    return [
      // conv_001 — Belajar Flutter
      _msg('msg_001', 'conv_001', 'user', 'Apa itu Flutter?',
          base.subtract(const Duration(minutes: 40))),
      _msg(
        'msg_002',
        'conv_001',
        'assistant',
        'Flutter adalah framework UI open-source dari Google untuk membangun '
            'aplikasi cross-platform (Android, iOS, web, desktop) dari satu '
            'codebase menggunakan bahasa Dart.',
        base.subtract(const Duration(minutes: 38))),
      _msg(
        'msg_003',
        'conv_001',
        'user',
        'Apa kelebihan Flutter dibanding React Native?',
        base.subtract(const Duration(minutes: 30))),
      _msg(
        'msg_004',
        'conv_001',
        'assistant',
        'Flutter menggunakan engine rendering sendiri (Skia/Impeller) sehingga '
            'konsisten di semua platform, sedangkan React Native bergantung pada '
            'bridge ke native widgets. Flutter juga memiliki hot reload yang '
            'sangat cepat untuk iterasi UI.',
        base.subtract(const Duration(minutes: 28))),

      // conv_002 — Membuat REST API
      _msg('msg_005', 'conv_002', 'user', 'Bagaimana cara membuat REST API?',
          base.subtract(const Duration(hours: 5, minutes: 10))),
      _msg(
        'msg_006',
        'conv_002',
        'assistant',
        'Langkah dasar: 1) Pilih framework (Express, FastAPI, dll). '
            '2) Definisikan resource dan endpoint REST. 3) Hubungkan ke '
            'database. 4) Tambahkan validasi input. 5) Implementasikan '
            'authentication. 6) Tulis dokumentasi dan test.',
        base.subtract(const Duration(hours: 5, minutes: 8))),

      // conv_003 — Product Requirements
      _msg('msg_007', 'conv_003', 'user',
          'Tolong buatkan outline PRD untuk aplikasi chat AI.',
          base.subtract(const Duration(hours: 8))),
      _msg(
        'msg_008',
        'conv_003',
        'assistant',
        'Outline PRD: 1) Product Overview 2) Goals & Non-Goals 3) Target User '
            '4) User Flow 5) Information Architecture 6) Screen Requirements '
            '7) Acceptance Criteria 8) Development Phases 9) Future Roadmap.',
        base.subtract(const Duration(hours: 7, minutes: 58))),

      // conv_004 — Belajar AI
      _msg('msg_009', 'conv_004', 'user', 'Apa itu machine learning?',
          base.subtract(const Duration(hours: 50))),
      _msg(
        'msg_010',
        'conv_004',
        'assistant',
        'Machine learning adalah cabang AI di mana sistem belajar pola dari '
            'data tanpa diprogram secara eksplisit. Contoh: klasifikasi gambar, '
            'prediksi harga, dan natural language processing.',
        base.subtract(const Duration(hours: 49, minutes: 58))),
    ];
  }

  Map<String, dynamic> _msg(
    String id,
    String convId,
    String role,
    String content,
    DateTime createdAt,
  ) {
    return {
      'id': id,
      'conversationId': convId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'status': 'completed',
    };
  }
}

/// Runs [SeedData.seedIfNeeded] after storage is initialized.
final seedDataProvider = FutureProvider<void>((ref) async {
  await ref.watch(storageInitProvider.future);
  final db = AppDatabase.instance;
  return SeedData(db, ref.watch(hashUtilProvider)).seedIfNeeded();
});
