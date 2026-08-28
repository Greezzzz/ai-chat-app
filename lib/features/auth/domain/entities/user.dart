/// A user of the application.
class User {
  const User({required this.id, required this.username, required this.email});

  final String id;
  final String username;
  final String email;

  User copyWith({String? id, String? username, String? email}) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.username == username &&
      other.email == email;

  @override
  int get hashCode => Object.hash(id, username, email);
}
