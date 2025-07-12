import 'package:academify/services/auth/auth_user.dart';

abstract class AuthProvider {
  Future<void> initialize();
  AuthUser? get currentUser;
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser> logIn({required String email, required String password});
  Future<AuthUser> createUser({
    required String email,
    required String password,
  });
  Future<void> logOut();
}
