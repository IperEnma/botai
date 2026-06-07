import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../models/user.dart';
import '../core/auth_bearer_token.dart';
import '../core/config.dart';
import 'api_service.dart';

class AuthService {
  late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _storage;
  // Kept for future backend auth exchange; currently unused.
  // ignore: unused_field
  final ApiService _apiService;

  AuthService({ApiService? apiService})
      : _storage = const FlutterSecureStorage(),
        _apiService = apiService ?? ApiService() {
    final webClientId = AppConfig.googleClientIdWeb.trim();
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb && webClientId.isNotEmpty ? webClientId : null,
      // google_sign_in_web exige serverClientId == null (assert en initWithParams).
      // En móvil, el Web client ID como serverClientId ayuda a obtener id_token para el backend.
      serverClientId:
          !kIsWeb && webClientId.isNotEmpty ? webClientId : null,
      scopes: const ['email', 'openid'],
    );
  }

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        throw StateError(
          'En web el inicio de sesión usa el botón oficial de Google (GIS). '
          'No llames a signInWithGoogle(); el flujo lo arma WebGoogleSignInScope + renderButton.',
        );
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(const Duration(seconds: 45));

      // En móvil, al volver del selector a veces signIn() devuelve null pero currentUser ya está.
      final account = googleUser ?? _googleSignIn.currentUser;
      if (account == null) return null;

      return handleGoogleSignInAccount(account);
    } on TimeoutException catch (_) {
      throw StateError(
        'Google Sign-In no respondió a tiempo. Reintentá o revisá la conexión.',
      );
    }
  }

  Future<User?> handleGoogleSignInAccount(GoogleSignInAccount? googleUser) async {
    if (googleUser == null) return null;
    
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final at = googleAuth.accessToken;
    final candidate = normalizeGoogleBearer(idToken) ??
        (isGoogleIdJwtShape(at ?? '') ? normalizeGoogleBearer(at) : null);
    if (candidate == null || !isUsableGoogleIdToken(candidate)) {
      throw StateError(
        'Google no devolvió id_token válido. Revisá configuración OAuth (GOOGLE_CLIENT_ID_WEB / serverClientId).',
      );
    }
    final bearer = candidate;

    final user = User(
      id: googleUser.id,
      email: googleUser.email,
      name: googleUser.displayName,
      photoUrl: googleUser.photoUrl,
      accessToken: bearer,
    );
    
    await _storage.write(key: 'access_token', value: user.accessToken);
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_name', value: user.name);
    await _storage.write(key: 'user_photo', value: user.photoUrl);

    return user;
  }

  /// Intenta renovar el `id_token` de Google sin UI (sesión existente).
  ///
  /// Esto es lo más cercano a un "refresh" en nuestro setup actual, porque
  /// estamos usando Google ID tokens como Bearer en el backend.
  Future<User?> refreshSessionSilently() async {
    try {
      final account = _googleSignIn.currentUser ??
          await _googleSignIn.signInSilently().timeout(
                const Duration(seconds: 20),
              );
      if (account == null) return null;
      return await handleGoogleSignInAccount(account);
    } on TimeoutException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.deleteAll();
  }

  Future<User?> getCurrentUser() async {
    final raw = await _storage.read(key: 'access_token');
    final accessToken = normalizeGoogleBearer(raw);
    if (accessToken == null || !isUsableGoogleIdToken(accessToken)) {
      if (raw != null && raw.trim().isNotEmpty) {
        await _storage.deleteAll();
      }
      return null;
    }

    final userId = await _storage.read(key: 'user_id');
    final email = await _storage.read(key: 'user_email');
    final name = await _storage.read(key: 'user_name');
    final photoUrl = await _storage.read(key: 'user_photo');

    if (userId == null || email == null) return null;

    return User(
      id: userId,
      email: email,
      name: name,
      photoUrl: photoUrl,
      accessToken: accessToken,
    );
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
