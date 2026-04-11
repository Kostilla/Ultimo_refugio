import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class AuthRepository {
  Session? get currentSession => supabase.auth.currentSession;
  User? get currentUser => supabase.auth.currentUser;

  Stream<AuthState> authStateChanges() {
    return supabase.auth.onAuthStateChange;
  }

  Future<void> signIn({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
