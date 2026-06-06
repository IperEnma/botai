import 'agenda_json.dart';

/// Reseña de un negocio dejada por un cliente público.
/// Espejo de `ReviewResponse` del backend.
class AgendaReview {
  final String id;
  final String businessId;
  final String bookingId;
  final String? staffMemberId;
  /// Puntuación de 1 a 5.
  final int rating;
  final String? comentario;
  final DateTime createdAt;

  const AgendaReview({
    required this.id,
    required this.businessId,
    required this.bookingId,
    this.staffMemberId,
    required this.rating,
    this.comentario,
    required this.createdAt,
  });

  factory AgendaReview.fromJson(Map<String, dynamic> json) => AgendaReview(
        id: AgendaJson.parseString(json['id']),
        businessId: AgendaJson.parseString(json['businessId']),
        bookingId: AgendaJson.parseString(json['bookingId']),
        staffMemberId: AgendaJson.parseStringOrNull(json['staffMemberId']),
        rating: AgendaJson.parseInt(json['rating']),
        comentario: AgendaJson.parseStringOrNull(json['comentario']),
        createdAt: AgendaJson.parseDateTime(json['createdAt']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AgendaReview && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
