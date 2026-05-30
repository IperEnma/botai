class PublicClient {
  final String id;
  final String nombre;
  final String? email;
  final String? telefono;

  const PublicClient({
    required this.id,
    required this.nombre,
    this.email,
    this.telefono,
  });

  factory PublicClient.fromJson(Map<String, dynamic> json) => PublicClient(
        id: json['id']?.toString() ?? '',
        nombre: json['nombre']?.toString() ?? '',
        email: json['email']?.toString(),
        telefono: json['telefono']?.toString(),
      );
}
