import 'agenda_json.dart';
import 'agenda_search_tag.dart';
import '../../core/agenda_media_url.dart';

/// Negocio completo (vista admin de tenant). Espejo de `BusinessResponse`.
class Business {
  final String id;
  final String tenantId;
  final String nombre;
  final String? descripcion;
  final String? ownerUserId;
  final List<AgendaSearchTag> searchTags;
  final List<String> categorias;
  final bool activo;
  final String? logoUrl;
  final String? colorPrimario;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? facebookUrl;
  final String? colorFondo;
  final String? colorTarjeta;
  final String? fontFamily;
  /// Slug para `/reservar/{publicSlug}` (respuesta pública del backend).
  final String? publicSlug;
  /// PK del bot en el backend (`bot.id`); mismo workspace que [tenantId].
  final int? botId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? direccion;
  final String? bannerUrl;
  /// Promedio de reseñas (null si aún no hay reseñas).
  final double? rating;
  /// Cantidad total de reseñas.
  final int reviewCount;
  /// True si el JSON traía logo/banner que no son paths de upload (p. ej. dirección).
  final bool hadInvalidMediaUrls;
  /// True si banner/dirección venían intercambiados en BD (bug backend corregido).
  final bool needsFieldRepair;

  const Business({
    required this.id,
    required this.tenantId,
    required this.nombre,
    this.descripcion,
    this.ownerUserId,
    required this.searchTags,
    this.categorias = const [],
    required this.activo,
    this.logoUrl,
    this.colorPrimario,
    this.instagramUrl,
    this.tiktokUrl,
    this.facebookUrl,
    this.colorFondo,
    this.colorTarjeta,
    this.fontFamily,
    this.publicSlug,
    this.botId,
    this.createdAt,
    this.updatedAt,
    this.direccion,
    this.bannerUrl,
    this.rating,
    this.reviewCount = 0,
    this.hadInvalidMediaUrls = false,
    this.needsFieldRepair = false,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    final rawLogo = AgendaJson.parseStringOrNull(json['logoUrl']);
    final rawBanner = AgendaJson.parseStringOrNull(json['bannerUrl']);
    final rawDireccion = AgendaJson.parseStringOrNull(json['direccion']);
    final bannerInDireccion = sanitizeAgendaMediaUrl(rawDireccion);
    final addressInBanner = (rawBanner != null && !isAgendaMediaUrl(rawBanner))
        ? rawBanner.trim()
        : null;
    final hadInvalidMedia = (rawLogo != null && !isAgendaMediaUrl(rawLogo)) ||
        (rawBanner != null && !isAgendaMediaUrl(rawBanner));
    final needsRepair = bannerInDireccion != null || addressInBanner != null;

    return Business(
      id: AgendaJson.parseString(json['id']),
      tenantId: AgendaJson.parseString(json['tenantId']),
      nombre: AgendaJson.parseString(json['nombre']),
      descripcion: AgendaJson.parseStringOrNull(json['descripcion']),
      ownerUserId: AgendaJson.parseStringOrNull(json['ownerUserId']),
      searchTags: AgendaJson.parseSearchTagList(json['searchTags']),
      categorias: AgendaJson.parseStringList(json['categorias']),
      activo: AgendaJson.parseBool(json['activo'], fallback: true),
      logoUrl: sanitizeAgendaMediaUrl(rawLogo),
      colorPrimario: AgendaJson.parseStringOrNull(json['colorPrimario']),
      instagramUrl: AgendaJson.parseStringOrNull(json['instagramUrl']),
      tiktokUrl: AgendaJson.parseStringOrNull(json['tiktokUrl']),
      facebookUrl: AgendaJson.parseStringOrNull(json['facebookUrl']),
      colorFondo: AgendaJson.parseStringOrNull(json['colorFondo']),
      colorTarjeta: AgendaJson.parseStringOrNull(json['colorTarjeta']),
      fontFamily: AgendaJson.parseStringOrNull(json['fontFamily']),
      publicSlug: AgendaJson.parseStringOrNull(json['publicSlug']),
      botId: AgendaJson.parseIntOrNull(json['botId']),
      createdAt: AgendaJson.parseDateTimeOrNull(json['createdAt']),
      updatedAt: AgendaJson.parseDateTimeOrNull(json['updatedAt']),
      direccion: sanitizeBusinessDireccion(rawDireccion) ?? addressInBanner,
      bannerUrl: sanitizeAgendaMediaUrl(rawBanner) ?? bannerInDireccion,
      rating: AgendaJson.parseDoubleOrNull(json['rating']),
      reviewCount: AgendaJson.parseInt(json['reviewCount']),
      hadInvalidMediaUrls: hadInvalidMedia,
      needsFieldRepair: needsRepair,
    );
  }

  Business copyWith({
    String? nombre,
    String? descripcion,
    List<AgendaSearchTag>? searchTags,
    List<String>? categorias,
    bool? activo,
    Object? logoUrl = _sentinel,
    Object? colorPrimario = _sentinel,
    Object? instagramUrl = _sentinel,
    Object? tiktokUrl = _sentinel,
    Object? facebookUrl = _sentinel,
    Object? colorFondo = _sentinel,
    Object? colorTarjeta = _sentinel,
    Object? fontFamily = _sentinel,
    Object? direccion = _sentinel,
    Object? bannerUrl = _sentinel,
  }) {
    return Business(
      id: id,
      tenantId: tenantId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      ownerUserId: ownerUserId,
      searchTags: searchTags ?? this.searchTags,
      categorias: categorias ?? this.categorias,
      activo: activo ?? this.activo,
      logoUrl: identical(logoUrl, _sentinel) ? this.logoUrl : logoUrl as String?,
      colorPrimario: identical(colorPrimario, _sentinel) ? this.colorPrimario : colorPrimario as String?,
      instagramUrl: identical(instagramUrl, _sentinel) ? this.instagramUrl : instagramUrl as String?,
      tiktokUrl: identical(tiktokUrl, _sentinel) ? this.tiktokUrl : tiktokUrl as String?,
      facebookUrl: identical(facebookUrl, _sentinel) ? this.facebookUrl : facebookUrl as String?,
      colorFondo: identical(colorFondo, _sentinel) ? this.colorFondo : colorFondo as String?,
      colorTarjeta: identical(colorTarjeta, _sentinel) ? this.colorTarjeta : colorTarjeta as String?,
      fontFamily: identical(fontFamily, _sentinel) ? this.fontFamily : fontFamily as String?,
      direccion: identical(direccion, _sentinel) ? this.direccion : direccion as String?,
      bannerUrl: identical(bannerUrl, _sentinel) ? this.bannerUrl : bannerUrl as String?,
      botId: botId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rating: rating,
      reviewCount: reviewCount,
      hadInvalidMediaUrls: hadInvalidMediaUrls,
      needsFieldRepair: needsFieldRepair,
    );
  }

  static const _sentinel = Object();

  List<String> get profileTagLabels =>
      searchTags.where((t) => t.isProfile).map((t) => t.value).toList();

  List<AgendaSearchTag> get locationTags =>
      searchTags.where((t) => t.isLocation).toList(growable: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Business && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
