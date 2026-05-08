import 'agenda_json.dart';

/// Negocio completo (vista admin de tenant). Espejo de `BusinessResponse`.
class Business {
  final String id;
  final String tenantId;
  final String nombre;
  final String? descripcion;
  final String? ownerUserId;
  final List<String> searchTags;
  final List<String> categorias;
  final bool activo;
  final String? logoUrl;
  final String? colorPrimario;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? facebookUrl;
  final String? colorFondo;
  final String? fontFamily;
  /// PK del bot en el backend (`bot.id`); mismo workspace que [tenantId].
  final int? botId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.fontFamily,
    this.botId,
    this.createdAt,
    this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: AgendaJson.parseString(json['id']),
      tenantId: AgendaJson.parseString(json['tenantId']),
      nombre: AgendaJson.parseString(json['nombre']),
      descripcion: AgendaJson.parseStringOrNull(json['descripcion']),
      ownerUserId: AgendaJson.parseStringOrNull(json['ownerUserId']),
      searchTags: AgendaJson.parseStringList(json['searchTags']),
      categorias: AgendaJson.parseStringList(json['categorias']),
      activo: AgendaJson.parseBool(json['activo'], fallback: true),
      logoUrl: AgendaJson.parseStringOrNull(json['logoUrl']),
      colorPrimario: AgendaJson.parseStringOrNull(json['colorPrimario']),
      instagramUrl: AgendaJson.parseStringOrNull(json['instagramUrl']),
      tiktokUrl: AgendaJson.parseStringOrNull(json['tiktokUrl']),
      facebookUrl: AgendaJson.parseStringOrNull(json['facebookUrl']),
      colorFondo: AgendaJson.parseStringOrNull(json['colorFondo']),
      fontFamily: AgendaJson.parseStringOrNull(json['fontFamily']),
      botId: AgendaJson.parseIntOrNull(json['botId']),
      createdAt: AgendaJson.parseDateTimeOrNull(json['createdAt']),
      updatedAt: AgendaJson.parseDateTimeOrNull(json['updatedAt']),
    );
  }

  Business copyWith({
    String? nombre,
    String? descripcion,
    List<String>? searchTags,
    List<String>? categorias,
    bool? activo,
    Object? logoUrl = _sentinel,
    Object? colorPrimario = _sentinel,
    Object? instagramUrl = _sentinel,
    Object? tiktokUrl = _sentinel,
    Object? facebookUrl = _sentinel,
    Object? colorFondo = _sentinel,
    Object? fontFamily = _sentinel,
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
      fontFamily: identical(fontFamily, _sentinel) ? this.fontFamily : fontFamily as String?,
      botId: botId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static const _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Business && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
