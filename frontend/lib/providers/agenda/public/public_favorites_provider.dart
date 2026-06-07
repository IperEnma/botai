import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/agenda_phone.dart';

/// Favoritos del cliente público (local), indexados por teléfono verificado.
class PublicFavoritesStorage {
  static String _key(String phone) =>
      'agenda_public_favorites_${normalizeAgendaPhoneDigits(phone)}';

  Future<Set<String>> loadSlugs(String phone) async {
    final normalized = normalizeAgendaPhoneDigits(phone);
    if (normalized.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(normalized));
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = (jsonDecode(raw) as List<dynamic>).map((e) => e.toString()).toList();
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> isFavorite({required String phone, required String slug}) async {
    final set = await loadSlugs(phone);
    return set.contains(slug);
  }

  Future<bool> toggle({required String phone, required String slug}) async {
    final normalized = normalizeAgendaPhoneDigits(phone);
    if (normalized.isEmpty) return false;
    final set = await loadSlugs(normalized);
    final nowFavorite = !set.contains(slug);
    if (nowFavorite) {
      set.add(slug);
    } else {
      set.remove(slug);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(normalized), jsonEncode(set.toList()));
    return nowFavorite;
  }
}

final publicFavoritesStorageProvider =
    Provider<PublicFavoritesStorage>((ref) => PublicFavoritesStorage());
