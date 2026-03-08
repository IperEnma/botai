class Service {
  final String? id;
  final String tenantId;
  final String name;
  final int sortOrder;
  final bool active;

  Service({
    this.id,
    required this.tenantId,
    required this.name,
    this.sortOrder = 0,
    this.active = true,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id']?.toString(),
      tenantId: json['tenantId'] as String,
      name: json['name'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'name': name,
      'sortOrder': sortOrder,
      'active': active,
    };
  }
}
