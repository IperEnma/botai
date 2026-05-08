import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(authService, apiService);
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ApiService _apiService;

  AuthNotifier(this._authService, this._apiService) : super(AuthState()) {
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _apiService.setAccessToken(user.accessToken);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _apiService.setAccessToken(user.accessToken);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo iniciar sesión',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Web: after GIS [renderButton] signs the user in, the platform updates [GoogleSignIn.currentUser].
  Future<void> completeGoogleSignInFromAccount(GoogleSignInAccount account) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.handleGoogleSignInAccount(account);
      if (user != null) {
        _apiService.setAccessToken(user.accessToken);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No se pudo iniciar sesión',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.signOut();
      _apiService.setAccessToken(null);
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Renueva el Google ID token (sin UI) y actualiza el estado.
  ///
  /// Devuelve `true` si pudo obtener un token nuevo. Si falla, no cambia la sesión.
  Future<bool> refreshSessionSilently() async {
    try {
      final refreshed = await _authService.refreshSessionSilently();
      if (refreshed == null) return false;

      _apiService.setAccessToken(refreshed.accessToken);
      state = state.copyWith(
        user: refreshed,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
