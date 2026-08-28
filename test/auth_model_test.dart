// Unit tests for auth remote model parsing (backend int ids vs mock strings).

import 'package:flutter_test/flutter_test.dart';

import 'package:chat_app/features/auth/data/models/user_model.dart';

void main() {
  test('parses numeric id from the backend /me response', () {
    final model = UserModel.fromJson(const {
      'id': 1,
      'username': 'johndoe',
      'email': 'john@example.com',
    });
    expect(model.id, '1');
    expect(model.username, 'johndoe');
  });

  test('parses string id from mock storage', () {
    final model = UserModel.fromJson(const {
      'id': 'user_001',
      'username': 'john_doe',
      'email': 'john@example.com',
    });
    expect(model.id, 'user_001');
  });
}
