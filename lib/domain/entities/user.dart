import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.createdAt,
    this.lastLogin,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return username;
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    createdAt,
    lastLogin,
  ];
}
