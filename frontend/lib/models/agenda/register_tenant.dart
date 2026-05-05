import 'agenda_json.dart';

class RegisterTenantResponse {
  final String tenantId;
  final String businessId;
  final String accessCode;

  const RegisterTenantResponse({
    required this.tenantId,
    required this.businessId,
    required this.accessCode,
  });

  factory RegisterTenantResponse.fromJson(Map<String, dynamic> json) {
    return RegisterTenantResponse(
      tenantId: AgendaJson.parseString(json['tenantId']),
      businessId: AgendaJson.parseString(json['businessId']),
      accessCode: AgendaJson.parseString(json['accessCode']),
    );
  }
}
