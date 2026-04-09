import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { client, gardener }

class AuthState {
  const AuthState({
    required this.userId,
    required this.role,
    required this.displayName,
  });

  final String userId;
  final UserRole role;
  final String displayName;

  bool get isClient => role == UserRole.client;
  bool get isGardener => role == UserRole.gardener;
}

class AuthNotifier extends StateNotifier<AuthState?> {
  AuthNotifier() : super(null);

  void signIn({required UserRole role}) {
    switch (role) {
      case UserRole.client:
        state = const AuthState(
          userId: 'client-001',
          role: UserRole.client,
          displayName: 'Juan Martinez',
        );
      case UserRole.gardener:
        state = const AuthState(
          userId: 'gardener-001',
          role: UserRole.gardener,
          displayName: 'Marc Vidal',
        );
    }
  }

  void signOut() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState?>((ref) {
  return AuthNotifier();
});
