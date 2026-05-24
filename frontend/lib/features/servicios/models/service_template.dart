class ServiceTemplate {
  final String id;
  final String name;
  final String description;
  final String groupId;
  final int defaultDurationMinutes;
  final bool defaultFlexibleDuration;
  final int defaultPriceUyu;
  final bool defaultPriceFrom;

  const ServiceTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.groupId,
    required this.defaultDurationMinutes,
    this.defaultFlexibleDuration = false,
    required this.defaultPriceUyu,
    this.defaultPriceFrom = false,
  });
}
