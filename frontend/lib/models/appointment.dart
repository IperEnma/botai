class Appointment {
  final String? id;
  final String tenantId;
  final String customerName;
  final String? customerDocument;
  final String serviceName;
  final String appointmentDate;
  final String appointmentTime;
  final String status;

  Appointment({
    this.id,
    required this.tenantId,
    required this.customerName,
    this.customerDocument,
    required this.serviceName,
    required this.appointmentDate,
    required this.appointmentTime,
    this.status = 'scheduled',
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id']?.toString(),
      tenantId: json['tenantId'] as String,
      customerName: json['customerName'] as String? ?? '',
      customerDocument: json['customerDocument'] as String?,
      serviceName: json['serviceName'] as String? ?? '',
      appointmentDate: json['appointmentDate'] as String? ?? '',
      appointmentTime: json['appointmentTime'] as String? ?? '',
      status: json['status'] as String? ?? 'scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'customerName': customerName,
      if (customerDocument != null) 'customerDocument': customerDocument,
      'serviceName': serviceName,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'status': status,
    };
  }
}
