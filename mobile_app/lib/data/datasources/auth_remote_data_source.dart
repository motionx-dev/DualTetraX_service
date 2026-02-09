import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/auth_user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUserModel> loginWithEmail(String email, String password);
  Future<AuthUserModel> signupWithEmail(String email, String password);
  Future<AuthUserModel> loginWithGoogle();
  Future<AuthUserModel> loginWithApple();
  Future<void> logout();
  Future<AuthUserModel?> getCurrentUser();
  Future<void> resetPassword(String email);
  Stream<AuthUserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient _supabase;
  final ApiClient _apiClient;

  AuthRemoteDataSourceImpl({
    required ApiClient apiClient,
  })  : _supabase = Supabase.instance.client,
        _apiClient = apiClient;

  AuthUserModel _userFromSupabase(User user) {
    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
      role: user.userMetadata?['role'] as String? ?? 'user',
    );
  }

  @override
  Future<AuthUserModel> loginWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Login failed');
    }
    return _userFromSupabase(response.user!);
  }

  @override
  Future<AuthUserModel> signupWithEmail(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Signup failed');
    }
    return _userFromSupabase(response.user!);
  }

  @override
  Future<AuthUserModel> loginWithGoogle() async {
    final response = await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.dualtetrax://login-callback/',
    );
    if (!response) {
      throw Exception('Google login failed');
    }
    // Wait for auth state change
    final completer = await _supabase.auth.onAuthStateChange.firstWhere(
      (data) => data.event == AuthChangeEvent.signedIn,
    );
    if (completer.session?.user == null) {
      throw Exception('Google login failed');
    }
    return _userFromSupabase(completer.session!.user);
  }

  @override
  Future<AuthUserModel> loginWithApple() async {
    final response = await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.dualtetrax://login-callback/',
    );
    if (!response) {
      throw Exception('Apple login failed');
    }
    final completer = await _supabase.auth.onAuthStateChange.firstWhere(
      (data) => data.event == AuthChangeEvent.signedIn,
    );
    if (completer.session?.user == null) {
      throw Exception('Apple login failed');
    }
    return _userFromSupabase(completer.session!.user);
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  @override
  Future<AuthUserModel?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _userFromSupabase(user);
  }

  @override
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Stream<AuthUserModel?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return _userFromSupabase(user);
    });
  }
}
