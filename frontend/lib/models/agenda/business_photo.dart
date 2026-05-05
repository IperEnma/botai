import 'agenda_json.dart';

class BusinessPhoto {
  final String id;
  final String businessId;
  final String url;
  final int orden;

  const BusinessPhoto({
    required this.id,
    required this.businessId,
    required this.url,
    required this.orden,
  });

  factory BusinessPhoto.fromJson(Map<String, dynamic> json) {
    return BusinessPhoto(
      id: AgendaJson.parseString(json['id']),
      businessId: AgendaJson.parseString(json['businessId']),
      url: AgendaJson.parseString(json['url']),
      orden: (json['orden'] as num?)?.toInt() ?? 0,
    );
  }
}
