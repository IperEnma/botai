import 'agenda_json.dart';

class PublicCompanyBranch {
  const PublicCompanyBranch({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.publicSlug,
    this.logoUrl,
    this.colorPrimario,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String publicSlug;
  final String? logoUrl;
  final String? colorPrimario;

  factory PublicCompanyBranch.fromJson(Map<String, dynamic> json) {
    return PublicCompanyBranch(
      id: AgendaJson.parseString(json['id']),
      nombre: AgendaJson.parseString(json['nombre']),
      descripcion: AgendaJson.parseStringOrNull(json['descripcion']),
      publicSlug: AgendaJson.parseString(json['publicSlug']),
      logoUrl: AgendaJson.parseStringOrNull(json['logoUrl']),
      colorPrimario: AgendaJson.parseStringOrNull(json['colorPrimario']),
    );
  }
}

class PublicCompany {
  const PublicCompany({
    required this.companySlug,
    required this.brandName,
    this.tagline,
    this.logoUrl,
    this.colorPrimario,
    this.colorFondo,
    this.fontFamily,
    required this.branches,
  });

  final String companySlug;
  final String brandName;
  final String? tagline;
  final String? logoUrl;
  final String? colorPrimario;
  final String? colorFondo;
  final String? fontFamily;
  final List<PublicCompanyBranch> branches;

  factory PublicCompany.fromJson(Map<String, dynamic> json) {
    return PublicCompany(
      companySlug: AgendaJson.parseString(json['companySlug']),
      brandName: AgendaJson.parseString(json['brandName']),
      tagline: AgendaJson.parseStringOrNull(json['tagline']),
      logoUrl: AgendaJson.parseStringOrNull(json['logoUrl']),
      colorPrimario: AgendaJson.parseStringOrNull(json['colorPrimario']),
      colorFondo: AgendaJson.parseStringOrNull(json['colorFondo']),
      fontFamily: AgendaJson.parseStringOrNull(json['fontFamily']),
      branches: (json['branches'] as List<dynamic>? ?? const [])
          .map((e) => PublicCompanyBranch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
