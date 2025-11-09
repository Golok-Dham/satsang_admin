import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// Provider for Firebase Auth instance
@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

/// Provider for current user authentication state
@riverpod
Stream<User?> authState(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
}

/// Provider for current user (if authenticated)
@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
}

/// Auth service for login/logout operations
@riverpod
class AuthService extends _$AuthService {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({required String email, required String password}) async {
    final auth = ref.read(firebaseAuthProvider);
    state = const AsyncValue.loading();

    try {
      final credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncValue.data(null);
      return credential;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    final auth = ref.read(firebaseAuthProvider);
    state = const AsyncValue.loading();

    try {
      await auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Get current user's ID token (for API calls)
  Future<String?> getIdToken() async {
    final user = ref.read(currentUserProvider);
    return user?.getIdToken();
  }
}
