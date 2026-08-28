import '../../domain/entities/user.dart';

/// Data-layer representation of a user, including password material
/// used only in mock mode.
class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.passwordHash,
    this.salt,
  });

  factory UserModel.fromJson(Map<dynamic, dynamic> json) => UserModel(
        // The backend returns numeric ids (`"id": 1`); mock stores strings.
        id: json['id'].toString(),
        username: json['username'] as String,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String?,
        salt: json['salt'] as String?,
      );

  final String id;
  final String username;
  final String email;
  final String? passwordHash;
  final String? salt;

  User toEntity() => User(id: id, username: username, email: email);

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        if (passwordHash != null) 'passwordHash': passwordHash,
        if (salt != null) 'salt': salt,
      };
}
