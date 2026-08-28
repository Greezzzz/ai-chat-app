import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Password hashing for mock mode.
///
/// Uses SHA-256 with a per-user salt. Production must move password
/// verification entirely to the backend; the client never stores passwords.
class HashUtil {
  const HashUtil();

  String hash(String password, {String salt = ''}) {
    final digest = sha256.convert(utf8.encode('$salt:$password'));
    return digest.toString();
  }

  bool verify(String password, String hashed, {String salt = ''}) {
    return hash(password, salt: salt) == hashed;
  }
}
