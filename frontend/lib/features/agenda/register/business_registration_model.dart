import '../../../models/agenda/category.dart';

class BusinessRegistration {
  String?   name;
  String?   department;
  String?   locality;
  String?   streetAddress;
  List<Category> categories = [];
  /// Etiquetas libres escritas por el usuario (no están en el catálogo global).
  List<String> customCategoryLabels = [];
  String?        description;

  Map<String, dynamic> toJson() => {
    'name':          name,
    'department':    department,
    'locality':      locality,
    'streetAddress': streetAddress,
    'categoryIds':   categories.map((c) => c.id).toList(),
    'categoryNames': categories.map((c) => c.nombre).toList(),
    'customCategoryLabels': customCategoryLabels,
    'description':   description,
  };
}
