import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/widgets.dart';

@immutable
class AuthUser {
  final String? email;
  const AuthUser(this.email);
  factory AuthUser.fromFirebase(User user) {
    return AuthUser(user.email);
  }
}
