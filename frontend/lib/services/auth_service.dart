import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../core/config.dart';
import 'api_service.dart';

class AuthService {
  late final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _storage;
  final ApiService _apiService;

  AuthService({ApiService? apiService})
      : _storage = const FlutterSecureStorage(),
        _apiService = apiService ?? ApiService() {
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? AppConfig.googleClientIdWeb : null,
      scopes: ['email', 'profile', 'openid'],
    );
  }

  GoogleSignIn get googleSignIn => _googleSignIn;

  Future<User?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      
      if (kIsWeb) {
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          googleUser = await _googleSignIn.signIn();
        }
      } else {
        googleUser = await _googleSignIn.signIn();
      }
      
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      final user = User(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
        accessToken: accessToken ?? idToken ?? 'google_auth_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _storage.write(key: 'access_token', value: user.accessToken);
      await _storage.write(key: 'user_id', value: user.id);
      await _storage.write(key: 'user_email', value: user.email);
      await _storage.write(key: 'user_name', value: user.name);
      await _storage.write(key: 'user_photo', value: user.photoUrl);

      return user;
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
      accessToken: googleAuth.accessToken ?? googleAuth.idToken ?? 'google_auth',
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
