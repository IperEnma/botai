import '../models/business_category.dart';
import '../models/service_group.dart';

class ServiceGroupCatalog {
  ServiceGroupCatalog._();

  static List<ServiceGroup> forCategory(BusinessCategory c) =>
      _catalog[c] ?? [];

  static const _catalog = <BusinessCategory, List<ServiceGroup>>{
    BusinessCategory.peluqueria: [
      ServiceGroup(
        id: 'pelo',
        name: 'Pelo',
        parentCategory: BusinessCategory.peluqueria,
        order: 0,
      ),
      ServiceGroup(
        id: 'barba',
        name: 'Barba',
        parentCategory: BusinessCategory.peluqueria,
        order: 1,
      ),
      ServiceGroup(
        id: 'manos_pies',
        name: 'Manos y pies',
        parentCategory: BusinessCategory.peluqueria,
        order: 2,
      ),
      ServiceGroup(
        id: 'estetica',
        name: 'Estética',
        parentCategory: BusinessCategory.peluqueria,
        order: 3,
      ),
    ],
    BusinessCategory.barberia: [
      ServiceGroup(
        id: 'barba',
        name: 'Barba',
        parentCategory: BusinessCategory.barberia,
        order: 0,
      ),
      ServiceGroup(
        id: 'pelo',
        name: 'Pelo',
        parentCategory: BusinessCategory.barberia,
        order: 1,
      ),
      ServiceGroup(
        id: 'complementos',
        name: 'Complementos',
        parentCategory: BusinessCategory.barberia,
        order: 2,
      ),
    ],
    BusinessCategory.manicure: [
      ServiceGroup(
        id: 'manos',
        name: 'Manos',
        parentCategory: BusinessCategory.manicure,
        order: 0,
      ),
      ServiceGroup(
        id: 'esmalte',
        name: 'Esmalte',
        parentCategory: BusinessCategory.manicure,
        order: 1,
      ),
      ServiceGroup(
        id: 'nail_art',
        name: 'Nail Art',
        parentCategory: BusinessCategory.manicure,
        order: 2,
      ),
    ],
    BusinessCategory.pedicure: [
      ServiceGroup(
        id: 'pies',
        name: 'Pies',
        parentCategory: BusinessCategory.pedicure,
        order: 0,
      ),
      ServiceGroup(
        id: 'cuidado',
        name: 'Cuidado',
        parentCategory: BusinessCategory.pedicure,
        order: 1,
      ),
    ],
    BusinessCategory.spa: [
      ServiceGroup(
        id: 'masajes',
        name: 'Masajes',
        parentCategory: BusinessCategory.spa,
        order: 0,
      ),
      ServiceGroup(
        id: 'tratamientos',
        name: 'Tratamientos',
        parentCategory: BusinessCategory.spa,
        order: 1,
      ),
      ServiceGroup(
        id: 'aromaterapia',
        name: 'Aromaterapia',
        parentCategory: BusinessCategory.spa,
        order: 2,
      ),
    ],
    BusinessCategory.estetica: [
      ServiceGroup(
        id: 'facial',
        name: 'Facial',
        parentCategory: BusinessCategory.estetica,
        order: 0,
      ),
      ServiceGroup(
        id: 'corporal',
        name: 'Corporal',
        parentCategory: BusinessCategory.estetica,
        order: 1,
      ),
      ServiceGroup(
        id: 'depilacion',
        name: 'Depilación',
        parentCategory: BusinessCategory.estetica,
        order: 2,
      ),
    ],
    BusinessCategory.yogaPilates: [
      ServiceGroup(
        id: 'clases',
        name: 'Clases',
        parentCategory: BusinessCategory.yogaPilates,
        order: 0,
      ),
      ServiceGroup(
        id: 'bienestar',
        name: 'Bienestar',
        parentCategory: BusinessCategory.yogaPilates,
        order: 1,
      ),
    ],
    BusinessCategory.otra: [
      ServiceGroup(
        id: 'general',
        name: 'General',
        parentCategory: BusinessCategory.otra,
        order: 0,
      ),
    ],
  };
}
