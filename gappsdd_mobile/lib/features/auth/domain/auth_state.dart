import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { client, gardener, admin, superAdmin, companyAdmin }

class AuthState {
  const AuthState({
    required this.userId,
    required this.role,
    required this.displayName,
    this.email,
    this.companyId,
  });

  final String userId;
  final UserRole role;
  final String displayName;
  final String? email;
  final String? companyId;

  bool get isClient => role == UserRole.client;
  bool get isGardener => role == UserRole.gardener;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isCompanyAdmin => role == UserRole.companyAdmin;
}

UserRole _parseRole(String? role) {
  switch (role?.toUpperCase()) {
    case 'GARDENER':
    case 'MANAGER':
      return UserRole.gardener;
    case 'SUPER_ADMIN':
      return UserRole.superAdmin;
    case 'COMPANY_ADMIN':
      return UserRole.companyAdmin;
    case 'ADMIN':
      return UserRole.admin;
    default:
      return UserRole.client;
  }
}

const _kCachedUserId = 'auth_cached_user_id';
const _kCachedRole = 'auth_cached_role';
const _kCachedDisplayName = 'auth_cached_display_name';
const _kCachedCompanyId = 'auth_cached_company_id';

class AuthNotifier extends StateNotifier<AuthState?> {
  AuthNotifier() : super(null) {
    // Restore session on app restart — fetch role from DB, fall back to cache
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _loadFromProfile(session.user);
    }

    // Only handle sign-out; sign-in is handled explicitly by signInWithEmail
    // to avoid a race where the stream fires with no role in JWT metadata
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        _clearCache();
        state = null;
      }
    });
  }

  Future<void> _loadFromProfile(User user) async {
    try {
      final profile = await Supabase.instance.client
          .from('user_profiles')
          .select('role, display_name, company_id')
          .eq('id', user.id)
          .maybeSingle();

      final authState = AuthState(
        userId: user.id,
        role: _parseRole(profile?['role'] as String?),
        displayName: profile?['display_name'] as String? ?? user.email ?? 'User',
        email: user.email,
        companyId: profile?['company_id'] as String?,
      );

      await _saveCache(authState);
      state = authState;
    } catch (_) {
      // No network — restore from local cache if the session belongs to the same user
      final cached = await _loadCache();
      if (cached != null && cached.userId == user.id) {
        state = cached;
      }
    }
  }

  Future<void> _saveCache(AuthState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCachedUserId, s.userId);
    await prefs.setString(_kCachedRole, s.role.name);
    await prefs.setString(_kCachedDisplayName, s.displayName);
    if (s.companyId != null) {
      await prefs.setString(_kCachedCompanyId, s.companyId!);
    } else {
      await prefs.remove(_kCachedCompanyId);
    }
  }

  Future<AuthState?> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kCachedUserId);
    final roleName = prefs.getString(_kCachedRole);
    final displayName = prefs.getString(_kCachedDisplayName);
    final companyId = prefs.getString(_kCachedCompanyId);
    if (userId == null || roleName == null) return null;
    return AuthState(
      userId: userId,
      role: _parseRole(roleName),
      displayName: displayName ?? 'User',
      companyId: companyId,
    );
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCachedUserId);
    await prefs.remove(_kCachedRole);
    await prefs.remove(_kCachedDisplayName);
    await prefs.remove(_kCachedCompanyId);
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
      await _loadFromProfile(response.user!);
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    await _clearCache();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState?>((ref) {
  return AuthNotifier();
});
