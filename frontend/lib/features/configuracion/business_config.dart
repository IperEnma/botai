import '../../models/agenda/business.dart';

enum SocialKind { instagram, tiktok, facebook, whatsapp }

class BusinessConfig {
  const BusinessConfig({
    required this.nombre,
    this.descripcion,
    this.direccion,
    this.rubroTags = const [],
    this.activo = true,
    this.categorias = const [],
    this.redes = const {},
    this.whatsapp,
    this.email,
    this.horasLimiteCancelacion = 4,
    this.diasAntesDeAlertar = 7,
    this.creditosMinimosAlertar = 2,
    this.confirmarReservasManual = true,
    this.notificacionesAutomaticas = true,
  });

  final String nombre;
  final String? descripcion;
  final String? direccion;
  final List<String> rubroTags;
  final bool activo;
  final List<String> categorias;
  final Map<SocialKind, String?> redes;
  final String? whatsapp;
  final String? email;
  final int horasLimiteCancelacion;
  final int diasAntesDeAlertar;
  final int creditosMinimosAlertar;
  final bool confirmarReservasManual;
  final bool notificacionesAutomaticas;

  factory BusinessConfig.fromBusiness(Business b) => BusinessConfig(
        nombre: b.nombre,
        descripcion: b.descripcion,
        direccion: b.direccion,
        rubroTags: b.profileTagLabels,
        activo: b.activo,
        categorias: b.categorias,
        redes: {
          SocialKind.instagram: b.instagramUrl,
          SocialKind.tiktok: b.tiktokUrl,
          SocialKind.facebook: b.facebookUrl,
        },
      );

  BusinessConfig copyWith({
    String? nombre,
    Object? descripcion = _kSentinel,
    Object? direccion = _kSentinel,
    List<String>? rubroTags,
    bool? activo,
    List<String>? categorias,
    Map<SocialKind, String?>? redes,
    Object? whatsapp = _kSentinel,
    Object? email = _kSentinel,
    int? horasLimiteCancelacion,
    int? diasAntesDeAlertar,
    int? creditosMinimosAlertar,
    bool? confirmarReservasManual,
    bool? notificacionesAutomaticas,
  }) =>
      BusinessConfig(
        nombre: nombre ?? this.nombre,
        descripcion: identical(descripcion, _kSentinel)
            ? this.descripcion
            : descripcion as String?,
        direccion: identical(direccion, _kSentinel)
            ? this.direccion
            : direccion as String?,
        rubroTags: rubroTags ?? this.rubroTags,
        activo: activo ?? this.activo,
        categorias: categorias ?? this.categorias,
        redes: redes ?? this.redes,
        whatsapp:
            identical(whatsapp, _kSentinel) ? this.whatsapp : whatsapp as String?,
        email: identical(email, _kSentinel) ? this.email : email as String?,
        horasLimiteCancelacion:
            horasLimiteCancelacion ?? this.horasLimiteCancelacion,
        diasAntesDeAlertar: diasAntesDeAlertar ?? this.diasAntesDeAlertar,
        creditosMinimosAlertar:
            creditosMinimosAlertar ?? this.creditosMinimosAlertar,
        confirmarReservasManual:
            confirmarReservasManual ?? this.confirmarReservasManual,
        notificacionesAutomaticas:
            notificacionesAutomaticas ?? this.notificacionesAutomaticas,
      );

  static const _kSentinel = Object();
}
