import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/agenda_api_service.dart';

/// Debe coincidir con `agenda.phone.verification.session-minutes` del backend.
const publicClientSessionTtl = Duration(minutes: 15);

/// Sesión OTP reutilizable en la web pública de un negocio (por slug).
class StoredPublicClientSession {
  const StoredPublicClientSession({
    required this.token,
    required this.businessId,
    required this.phone,
    required this.needsName,
    required this.expiresAtEpochMs,
    this.nombre,
  });

  final String token;
  final String businessId;
  final String phone;
  final bool needsName;
  final int expiresAtEpochMs;
  final String? nombre;

  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAtEpochMs;

  factory StoredPublicClientSession.fresh({
    required String token,
    required String businessId,
    required String phone,
    required bool needsName,
    String? nombre,
    Duration ttl = publicClientSessionTtl,
  }) {
    return StoredPublicClientSession(
      token: token,
      businessId: businessId,
      phone: phone,
      needsName: needsName,
      nombre: nombre,
      expiresAtEpochMs:
          DateTime.now().add(ttl).millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'businessId': businessId,
        'phone': phone,
        'needsName': needsName,
        'expiresAtEpochMs': expiresAtEpochMs,
        if (nombre != null) 'nombre': nombre,
      };

  factory StoredPublicClientSession.fromJson(Map<String, dynamic> json) {
    return StoredPublicClientSession(
      token: json['token']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      needsName: json['needsName'] == true,
      expiresAtEpochMs: json['expiresAtEpochMs'] is int
          ? json['expiresAtEpochMs'] as int
          : 0,
      nombre: json['nombre']?.toString(),
    );
  }

  StoredPublicClientSession copyWith({
    String? token,
    String? businessId,
    String? phone,
    bool? needsName,
    int? expiresAtEpochMs,
    String? nombre,
  }) {
    return StoredPublicClientSession(
      token: token ?? this.token,
      businessId: businessId ?? this.businessId,
      phone: phone ?? this.phone,
      needsName: needsName ?? this.needsName,
      expiresAtEpochMs: expiresAtEpochMs ?? this.expiresAtEpochMs,
      nombre: nombre ?? this.nombre,
    );
  }
}

class PublicClientSessionStorage {
  static const sessionHeader = AgendaApiService.publicClientSessionHeader;

  static String _key(String slug) => 'agenda_public_client_session_$slug';

  Future<StoredPublicClientSession?> load(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(slug));
    if (raw == null || raw.isEmpty) return null;
    try {
      final session = StoredPublicClientSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (session.isExpired || session.expiresAtEpochMs <= 0) {
        await clear(slug);
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String slug, StoredPublicClientSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(slug), jsonEncode(session.toJson()));
  }

  Future<void> clear(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(slug));
  }
}

final publicClientSessionStorageProvider =
    Provider<PublicClientSessionStorage>((ref) => PublicClientSessionStorage());

final publicClientSessionProvider =
    FutureProvider.family<StoredPublicClientSession?, String>((ref, slug) async {
  return ref.read(publicClientSessionStorageProvider).load(slug);
});
