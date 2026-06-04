import 'booking.dart';

class PublicClientProfile {
  const PublicClientProfile({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    required this.needsName,
  });

  final String id;
  final String nombre;
  final String telefono;
  final String? email;
  final bool needsName;

  factory PublicClientProfile.fromJson(Map<String, dynamic> json) {
    return PublicClientProfile(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      email: json['email']?.toString(),
      needsName: json['needsName'] == true,
    );
  }
}

class VerifyPublicPhoneResult {
  const VerifyPublicPhoneResult({
    required this.clientSessionToken,
    required this.client,
    required this.bookings,
  });

  final String clientSessionToken;
  final PublicClientProfile client;
  final List<Booking> bookings;
}
