import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { client, gardener, admin }

class AuthState {
  const AuthState({
    required this.userId,
    required this.role,
    required this.displayName,
    this.email,
  });

  final String userId;
  final UserRole role;
  final String displayName;
  final String? email;

  bool get isClient => role == UserRole.client;
  bool get isGardener => role == UserRole.gardener;
  bool get isAdmin => role == UserRole.admin;
}

UserRole _parseRole(String? role) {
  switch (role?.toUpperCase()) {
    case 'GARDENER':
      return UserRole.gardener;
    case 'ADMIN':
      return UserRole.admin;
    default:
      return UserRole.client;
  }
}

class AuthNotifier extends StateNotifier<AuthState?> {
  AuthNotifier() : super(null) {
    // Check if already logged in
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _setStateFromUser(Supabase.instance.client.auth.currentUser!);
    }

    // Listen for auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _setStateFromUser(data.session!.user);
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });
  }

  void _setStateFromUser(User user) {
    final metadata = user.userMetadata ?? {};
    state = AuthState(
      userId: user.id,
      role: _parseRole(metadata['role'] as String?),
      displayName: metadata['display_name'] as String? ?? user.email ?? 'User',
      email: user.email,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Fetch role from user_profiles
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('role, display_name')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile != null) {
        state = AuthState(
          userId: response.user!.id,
          role: _parseRole(profile['role'] as String?),
          displayName: profile['display_name'] as String? ?? email,
          email: email,
        );
      }
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState?>((ref) {
  return AuthNotifier();
});
