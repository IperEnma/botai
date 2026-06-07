import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agenda/agenda_search_tag.dart';
import '../../providers/agenda/tenant/businesses_provider.dart';
import 'business_config.dart';

class ConfigKey {
  const ConfigKey(this.tenantId, this.businessId);
  final String tenantId;
  final String businessId;

  @override
  bool operator ==(Object other) =>
      other is ConfigKey && other.tenantId == tenantId && other.businessId == businessId;

  @override
  int get hashCode => Object.hash(tenantId, businessId);
}

class ConfigState {
  const ConfigState({
    required this.config,
    this.saving = false,
    this.nombError,
    this.horasError,
    this.diasError,
    this.creditosError,
    this.whatsappError,
    this.emailError,
  });

  final BusinessConfig config;
  final bool saving;
  final String? nombError;
  final String? horasError;
  final String? diasError;
  final String? creditosError;
  final String? whatsappError;
  final String? emailError;

  bool get canSave =>
      !saving &&
      nombError == null &&
      horasError == null &&
      diasError == null &&
      creditosError == null &&
      whatsappError == null &&
      emailError == null &&
      config.nombre.trim().isNotEmpty;

  ConfigState copyWith({
    BusinessConfig? config,
    bool? saving,
    Object? nombError = _kSentinel,
    Object? horasError = _kSentinel,
    Object? diasError = _kSentinel,
    Object? creditosError = _kSentinel,
    Object? whatsappError = _kSentinel,
    Object? emailError = _kSentinel,
  }) =>
      ConfigState(
        config: config ?? this.config,
        saving: saving ?? this.saving,
        nombError: identical(nombError, _kSentinel)
            ? this.nombError
            : nombError as String?,
        horasError: identical(horasError, _kSentinel)
            ? this.horasError
            : horasError as String?,
        diasError: identical(diasError, _kSentinel)
            ? this.diasError
            : diasError as String?,
        creditosError: identical(creditosError, _kSentinel)
            ? this.creditosError
            : creditosError as String?,
        whatsappError: identical(whatsappError, _kSentinel)
            ? this.whatsappError
            : whatsappError as String?,
        emailError: identical(emailError, _kSentinel)
            ? this.emailError
            : emailError as String?,
      );

  static const _kSentinel = Object();
}

class ConfigController extends StateNotifier<ConfigState> {
  ConfigController(this._ref, this._key, BusinessConfig initial)
      : super(ConfigState(config: initial));

  final Ref _ref;
  final ConfigKey _key;

  void setNombre(String v) {
    final err = v.trim().isEmpty ? 'El nombre es requerido' : null;
    state = state.copyWith(
      config: state.config.copyWith(nombre: v.trim()),
      nombError: err,
    );
  }

  void setDescripcion(String v) {
    state = state.copyWith(
      config: state.config.copyWith(
        descripcion: v.trim().isEmpty ? null : v.trim(),
      ),
    );
  }

  void setDireccion(String v) {
    state = state.copyWith(
      config: state.config.copyWith(
        direccion: v.trim().isEmpty ? null : v.trim(),
      ),
    );
  }

  void setCategorias(List<String> v) {
    state = state.copyWith(config: state.config.copyWith(categorias: v));
  }

  void setRed(SocialKind kind, String? handle) {
    final updated = Map<SocialKind, String?>.from(state.config.redes);
    updated[kind] = handle?.trim().isEmpty == true ? null : handle?.trim();
    state = state.copyWith(config: state.config.copyWith(redes: updated));
  }

  void setWhatsapp(String? v) {
    final trimmed = v?.trim().isEmpty == true ? null : v?.trim();
    final err =
        trimmed != null && !_validPhone(trimmed) ? 'Formato inválido (+598…)' : null;
    state = state.copyWith(
      config: state.config.copyWith(whatsapp: trimmed),
      whatsappError: err,
    );
  }

  void setEmail(String? v) {
    final trimmed = v?.trim().isEmpty == true ? null : v?.trim();
    final err =
        trimmed != null && !_validEmail(trimmed) ? 'Email inválido' : null;
    state = state.copyWith(
      config: state.config.copyWith(email: trimmed),
      emailError: err,
    );
  }

  void setHorasLimiteCancelacion(String v) {
    final n = int.tryParse(v);
    final err = (n == null || n < 0) ? 'Debe ser ≥ 0' : null;
    state = state.copyWith(
      config: state.config.copyWith(horasLimiteCancelacion: n ?? state.config.horasLimiteCancelacion),
      horasError: err,
    );
  }

  void setDiasAntesDeAlertar(String v) {
    final n = int.tryParse(v);
    final err = (n == null || n < 0) ? 'Debe ser ≥ 0' : null;
    state = state.copyWith(
      config: state.config.copyWith(diasAntesDeAlertar: n ?? state.config.diasAntesDeAlertar),
      diasError: err,
    );
  }

  void setCreditosMinimosAlertar(String v) {
    final n = int.tryParse(v);
    final err = (n == null || n < 0) ? 'Debe ser ≥ 0' : null;
    state = state.copyWith(
      config: state.config.copyWith(creditosMinimosAlertar: n ?? state.config.creditosMinimosAlertar),
      creditosError: err,
    );
  }

  void toggleConfirmarReservas() {
    state = state.copyWith(
      config: state.config.copyWith(
        confirmarReservasManual: !state.config.confirmarReservasManual,
      ),
    );
  }

  void toggleNotificaciones() {
    state = state.copyWith(
      config: state.config.copyWith(
        notificacionesAutomaticas: !state.config.notificacionesAutomaticas,
      ),
    );
  }

  bool validate() {
    final c = state.config;
    final nombErr = c.nombre.trim().isEmpty ? 'El nombre es requerido' : null;
    final horasErr = c.horasLimiteCancelacion < 0 ? 'Debe ser ≥ 0' : null;
    final diasErr = c.diasAntesDeAlertar < 0 ? 'Debe ser ≥ 0' : null;
    final creditosErr = c.creditosMinimosAlertar < 0 ? 'Debe ser ≥ 0' : null;
    final waErr = c.whatsapp != null && c.whatsapp!.isNotEmpty && !_validPhone(c.whatsapp!)
        ? 'Formato inválido (+598…)'
        : null;
    final emailErr = c.email != null && c.email!.isNotEmpty && !_validEmail(c.email!)
        ? 'Email inválido'
        : null;

    state = state.copyWith(
      nombError: nombErr,
      horasError: horasErr,
      diasError: diasErr,
      creditosError: creditosErr,
      whatsappError: waErr,
      emailError: emailErr,
    );

    return nombErr == null &&
        horasErr == null &&
        diasErr == null &&
        creditosErr == null &&
        waErr == null &&
        emailErr == null;
  }

  Future<bool> save() async {
    if (!validate()) return false;
    state = state.copyWith(saving: true);
    try {
      final c = state.config;
      final businesses = _ref.read(businessesProvider(_key.tenantId));
      final business = businesses.items
          .where((b) => b.id == _key.businessId)
          .firstOrNull;
      if (business == null) return false;

      await _ref.read(businessesProvider(_key.tenantId).notifier).update(
            businessId: _key.businessId,
            nombre: c.nombre,
            descripcion: c.descripcion,
            searchTags: mergeAgendaSearchTags(
              existing: business.searchTags,
              profileLabels: c.rubroTags,
            ),
            logoUrl: business.logoUrl,
            colorPrimario: business.colorPrimario,
            instagramUrl: c.redes[SocialKind.instagram],
            tiktokUrl: c.redes[SocialKind.tiktok],
            facebookUrl: c.redes[SocialKind.facebook],
            colorFondo: business.colorFondo,
            fontFamily: business.fontFamily,
            direccion: c.direccion,
            bannerUrl: business.bannerUrl,
          );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) state = state.copyWith(saving: false);
    }
  }

  static bool _validPhone(String v) =>
      RegExp(r'^\+?[0-9\s\-]{7,20}$').hasMatch(v);

  static bool _validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
}

final configControllerProvider = StateNotifierProvider.autoDispose
    .family<ConfigController, ConfigState, ConfigKey>((ref, key) {
  final businesses = ref.read(businessesProvider(key.tenantId));
  final business = businesses.items
      .where((b) => b.id == key.businessId)
      .firstOrNull;
  final initial = business != null
      ? BusinessConfig.fromBusiness(business)
      : const BusinessConfig(nombre: '');
  return ConfigController(ref, key, initial);
});
