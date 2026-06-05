import 'agenda_json.dart';

class BusinessSettings {
  final String businessId;
  final int hoursCancellationLimit;
  final int loyaltyMinAttendances;
  final int loyaltyWindowDays;
  final int expirationAlertDays;
  final int expirationAlertCredits;
  final bool autoNotifyEnabled;
  final bool requireBookingConfirmation;

  const BusinessSettings({
    required this.businessId,
    required this.hoursCancellationLimit,
    required this.loyaltyMinAttendances,
    required this.loyaltyWindowDays,
    required this.expirationAlertDays,
    required this.expirationAlertCredits,
    required this.autoNotifyEnabled,
    this.requireBookingConfirmation = true,
  });

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      businessId: AgendaJson.parseString(json['businessId']),
      hoursCancellationLimit: AgendaJson.parseInt(json['hoursCancellationLimit']),
      loyaltyMinAttendances: AgendaJson.parseInt(json['loyaltyMinAttendances']),
      loyaltyWindowDays: AgendaJson.parseInt(json['loyaltyWindowDays']),
      expirationAlertDays: AgendaJson.parseInt(json['expirationAlertDays']),
      expirationAlertCredits: AgendaJson.parseInt(json['expirationAlertCredits']),
      autoNotifyEnabled: AgendaJson.parseBool(json['autoNotifyEnabled']),
      requireBookingConfirmation:
          AgendaJson.parseBool(json['requireBookingConfirmation'], fallback: true),
    );
  }

  BusinessSettings copyWith({
    int? hoursCancellationLimit,
    int? loyaltyMinAttendances,
    int? loyaltyWindowDays,
    int? expirationAlertDays,
    int? expirationAlertCredits,
    bool? autoNotifyEnabled,
    bool? requireBookingConfirmation,
  }) {
    return BusinessSettings(
      businessId: businessId,
      hoursCancellationLimit: hoursCancellationLimit ?? this.hoursCancellationLimit,
      loyaltyMinAttendances: loyaltyMinAttendances ?? this.loyaltyMinAttendances,
      loyaltyWindowDays: loyaltyWindowDays ?? this.loyaltyWindowDays,
      expirationAlertDays: expirationAlertDays ?? this.expirationAlertDays,
      expirationAlertCredits: expirationAlertCredits ?? this.expirationAlertCredits,
      autoNotifyEnabled: autoNotifyEnabled ?? this.autoNotifyEnabled,
      requireBookingConfirmation:
          requireBookingConfirmation ?? this.requireBookingConfirmation,
    );
  }

  Map<String, dynamic> toRequestJson() => {
        'hoursCancellationLimit': hoursCancellationLimit,
        'loyaltyMinAttendances': loyaltyMinAttendances,
        'loyaltyWindowDays': loyaltyWindowDays,
        'expirationAlertDays': expirationAlertDays,
        'expirationAlertCredits': expirationAlertCredits,
        'autoNotifyEnabled': autoNotifyEnabled,
        'requireBookingConfirmation': requireBookingConfirmation,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessSettings && other.businessId == businessId);

  @override
  int get hashCode => businessId.hashCode;
}
