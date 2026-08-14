import 'package:firebase_auth/firebase_auth.dart';
class AuthRepository {
  AuthRepository(this.auth); final FirebaseAuth auth;
  Stream<User?> watch() => auth.authStateChanges();
  Future<void> signIn(String email, String password) async => auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> register(String email, String password, {required String displayName}) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(displayName.trim());
  }
  Future<void> reset(String email) => auth.sendPasswordResetEmail(email: email.trim());
  Future<void> logout() => auth.signOut();
}
