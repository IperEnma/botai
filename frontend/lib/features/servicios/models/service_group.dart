import 'business_category.dart';

class ServiceGroup {
  final String id;
  final String name;
  final BusinessCategory parentCategory;
  final int order;

  const ServiceGroup({
    required this.id,
    required this.name,
    required this.parentCategory,
    required this.order,
  });
}
