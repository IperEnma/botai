class WhatsAppWebhookSetupInfo {
  const WhatsAppWebhookSetupInfo({
    required this.webhookUrl,
    required this.verifyToken,
    this.hint,
  });

  final String webhookUrl;
  final String verifyToken;
  final String? hint;

  factory WhatsAppWebhookSetupInfo.fromJson(Map<String, dynamic> json) {
    return WhatsAppWebhookSetupInfo(
      webhookUrl: json['webhookUrl']?.toString() ?? '',
      verifyToken: json['verifyToken']?.toString() ?? '',
      hint: json['hint']?.toString(),
    );
  }
}
