import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import '../models/user.dart';
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
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? AppConfig.googleClientIdWeb : null,
      // Evita depender de Google People API (profile/photo). Para login alcanza con email + openid (idToken).
      scopes: ['email', 'openid'],
    );
  }

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<User?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        final clientId = AppConfig.googleClientIdWeb.trim();
        if (clientId.isEmpty) {
          throw StateError(
            'Falta GOOGLE_CLIENT_ID_WEB en frontend/.env (OAuth Client ID tipo "Web application").',
          );
        }

        // En Web, signInSilently puede quedar colgado por bloqueo de third‑party cookies o popups.
        // Preferimos disparar el flujo interactivo y poner timeout para no dejar UI cargando infinito.
        googleUser = await _googleSignIn
            .signIn()
            .timeout(const Duration(seconds: 45));
      } else {
        googleUser = await _googleSignIn
            .signIn()
            .timeout(const Duration(seconds: 45));
      }
      
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication
          .timeout(const Duration(seconds: 45));
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      final user = User(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        // Preferimos ID token (JWT) para backend Resource Server; accessToken es para APIs Google.
        accessToken: idToken ?? accessToken ?? 'google_auth_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _storage.write(key: 'access_token', value: user.accessToken);
      await _storage.write(key: 'user_id', value: user.id);
      await _storage.write(key: 'user_email', value: user.email);
      await _storage.write(key: 'user_name', value: user.name);
      await _storage.write(key: 'user_photo', value: user.photoUrl);

      return user;
    } on TimeoutException catch (_) {
      throw StateError(
        'Google Sign-In no respondió a tiempo. En Web: habilita popups/terceros cookies para este sitio y reintenta.',
      );
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<User?> handleGoogleSignInAccount(GoogleSignInAccount? googleUser) async {
    if (googleUser == null) return null;
    
    final googleAuth = await googleUser.authentication;
    
    final user = User(
      id: googleUser.id,
      email: googleUser.email,
      name: googleUser.displayName,
      photoUrl: googleUser.photoUrl,
      // Mismo criterio que signInWithGoogle: Bearer debe ser ID token para el Resource Server.
      accessToken: googleAuth.idToken ?? googleAuth.accessToken ?? 'google_auth',
    );
    
    await _storage.write(key: 'access_token', value: user.accessToken);
    await _storage.write(key: 'user_id', value: user.id);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_name', value: user.name);
    await _storage.write(key: 'user_photo', value: user.photoUrl);

    return user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.deleteAll();
  }

  Future<User?> getCurrentUser() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) return null;

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
    final token = await getAccessToken();
    return token != null;
  }
}
