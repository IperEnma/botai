import 'package:flutter/material.dart';

/// Catálogo de iconos Material para categorías y servicios de Agenda.
///
/// Las claves (`scissors`, `stethoscope`, …) se persisten en `agenda_categories.icono`.
abstract final class AgendaIconRegistry {
  static const defaultKey = 'store';

  static IconData forKey(String? key) {
    if (key == null || key.isEmpty) return _material[defaultKey]!;
    return _material[key] ?? _material[defaultKey]!;
  }

  static IconData forCategory({String? slug, String? icono}) {
    if (icono != null && icono.isNotEmpty) {
      final byIcon = _material[icono];
      if (byIcon != null) return byIcon;
    }
    if (slug == null || slug.isEmpty) return forKey(defaultKey);
    return forKey(_slugFallback[slug.toLowerCase()] ?? slug.toLowerCase());
  }

  static IconData forService(
    String serviceName, {
    Iterable<String>? categorySlugs,
    Iterable<String>? categoryIconKeys,
  }) {
    final normalized = _normalize(serviceName);

    for (final rule in _serviceRules) {
      if (rule.keywords.any(normalized.contains)) {
        return forKey(rule.iconKey);
      }
    }

    if (categoryIconKeys != null) {
      for (final key in categoryIconKeys) {
        if (key.isNotEmpty) return forKey(key);
      }
    }

    if (categorySlugs != null) {
      for (final slug in categorySlugs) {
        if (slug.isNotEmpty) return forCategory(slug: slug);
      }
    }

    return forKey(defaultKey);
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll('á', 'a').replaceAll('é', 'e').replaceAll(
          'í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('ñ', 'n');

  static const Map<String, IconData> _material = {
    'scissors': Icons.content_cut_rounded,
    'razor': Icons.cut_rounded,
    'hand': Icons.back_hand_outlined,
    'foot': Icons.directions_walk_outlined,
    'sparkles': Icons.spa_outlined,
    'lotus': Icons.self_improvement_outlined,
    'dumbbell': Icons.fitness_center_outlined,
    'needle': Icons.colorize_outlined,
    'hands': Icons.volunteer_activism_outlined,
    'mirror': Icons.face_retouching_natural_outlined,
    'stethoscope': Icons.medical_services_outlined,
    'healing': Icons.healing_outlined,
    'psychology': Icons.psychology_outlined,
    'nutrition': Icons.restaurant_menu_outlined,
    'physiotherapy': Icons.accessibility_new_outlined,
    'paw': Icons.pets_outlined,
    'makeup': Icons.brush_outlined,
    'eyebrows': Icons.visibility_outlined,
    'wax': Icons.water_drop_outlined,
    'facial': Icons.face_3_outlined,
    'pilates': Icons.sports_gymnastics_outlined,
    'crossfit': Icons.sports_martial_arts_outlined,
    'personal_training': Icons.directions_run_outlined,
    'school': Icons.school_outlined,
    'language': Icons.translate_outlined,
    'music': Icons.music_note_outlined,
    'camera': Icons.photo_camera_outlined,
    'event': Icons.event_outlined,
    'restaurant': Icons.restaurant_outlined,
    'coworking': Icons.work_outline_outlined,
    'cleaning': Icons.cleaning_services_outlined,
    'wrench': Icons.car_repair_outlined,
    'gavel': Icons.gavel_outlined,
    'calculator': Icons.calculate_outlined,
    'home': Icons.home_work_outlined,
    'beauty': Icons.auto_awesome_outlined,
    'acupuncture': Icons.adjust_outlined,
    'chiropractic': Icons.chair_alt_outlined,
    'store': Icons.storefront_outlined,
  };

  static const Map<String, String> _slugFallback = {
    'peluqueria': 'scissors',
    'barberia': 'razor',
    'manicure': 'hand',
    'pedicure': 'foot',
    'spa': 'sparkles',
    'yoga': 'lotus',
    'gimnasio': 'dumbbell',
    'tatuajes': 'needle',
    'masajes': 'hands',
    'estetica': 'mirror',
    'salud': 'stethoscope',
    'medicina': 'stethoscope',
    'consultorio': 'stethoscope',
    'odontologia': 'healing',
    'psicologia': 'psychology',
    'terapia': 'psychology',
    'nutricion': 'nutrition',
    'fisioterapia': 'physiotherapy',
    'kinesiologia': 'physiotherapy',
    'veterinaria': 'paw',
    'podologia': 'foot',
    'depilacion': 'wax',
    'maquillaje': 'makeup',
    'cejas': 'eyebrows',
    'pestanas': 'eyebrows',
    'pilates': 'pilates',
    'crossfit': 'crossfit',
    'entrenamiento': 'personal_training',
    'clases': 'school',
    'idiomas': 'language',
    'musica': 'music',
    'fotografia': 'camera',
    'eventos': 'event',
    'gastronomia': 'restaurant',
    'restaurante': 'restaurant',
    'coworking': 'coworking',
    'limpieza': 'cleaning',
    'mecanica': 'wrench',
    'legal': 'gavel',
    'contabilidad': 'calculator',
    'inmobiliaria': 'home',
    'belleza': 'beauty',
    'acupuntura': 'acupuncture',
    'quiropractica': 'chiropractic',
    'fitness': 'dumbbell',
    'gym': 'dumbbell',
    'unas': 'hand',
  };

  static const List<({List<String> keywords, String iconKey})> _serviceRules = [
    (keywords: ['barba', 'afeitado', 'barber', 'fade'], iconKey: 'razor'),
    (keywords: ['corte', 'peluquer', 'peinado', 'tintura', 'coloracion', 'mechas', 'balayage'], iconKey: 'scissors'),
    (keywords: ['manicur', 'unas', 'nail', 'gel', 'semipermanente'], iconKey: 'hand'),
    (keywords: ['pedicur', 'pies', 'podolog'], iconKey: 'foot'),
    (keywords: ['masaje', 'descontractur', 'relajacion'], iconKey: 'hands'),
    (keywords: ['facial', 'limpieza facial', 'hidratacion'], iconKey: 'facial'),
    (keywords: ['depil', 'cera', 'laser'], iconKey: 'wax'),
    (keywords: ['maquillaje', 'makeup'], iconKey: 'makeup'),
    (keywords: ['ceja', 'pestaña', 'pestaña', 'lifting'], iconKey: 'eyebrows'),
    (keywords: ['tatuaj', 'piercing', 'microblading'], iconKey: 'needle'),
    (keywords: ['consulta', 'medico', 'doctor', 'clinica', 'turno medico'], iconKey: 'stethoscope'),
    (keywords: ['odont', 'dental', 'blanqueamiento'], iconKey: 'healing'),
    (keywords: ['psicolog', 'terapia', 'counsel', 'mental'], iconKey: 'psychology'),
    (keywords: ['nutric', 'dieta', 'alimentacion'], iconKey: 'nutrition'),
    (keywords: ['fisioter', 'kinesi', 'rehabilit'], iconKey: 'physiotherapy'),
    (keywords: ['quiropr', 'columna'], iconKey: 'chiropractic'),
    (keywords: ['acupunt'], iconKey: 'acupuncture'),
    (keywords: ['veterin', 'mascota', 'perro', 'gato'], iconKey: 'paw'),
    (keywords: ['yoga', 'meditacion', 'mindfulness'], iconKey: 'lotus'),
    (keywords: ['pilates'], iconKey: 'pilates'),
    (keywords: ['crossfit', 'funcional'], iconKey: 'crossfit'),
    (keywords: ['personal', 'entrenamiento', 'gym', 'gimnasio'], iconKey: 'personal_training'),
    (keywords: ['clase', 'curso', 'taller', 'capacitacion'], iconKey: 'school'),
    (keywords: ['idioma', 'ingles', 'portugues'], iconKey: 'language'),
    (keywords: ['musica', 'canto', 'instrumento'], iconKey: 'music'),
    (keywords: ['foto', 'sesion', 'retrato'], iconKey: 'camera'),
    (keywords: ['evento', 'fiesta', 'salon'], iconKey: 'event'),
    (keywords: ['mesa', 'restaurant', 'cena', 'almuerzo', 'reserva mesa'], iconKey: 'restaurant'),
    (keywords: ['cowork', 'oficina', 'sala reunion'], iconKey: 'coworking'),
    (keywords: ['limpieza', 'higiene', 'sanitiz'], iconKey: 'cleaning'),
    (keywords: ['mecan', 'auto', 'vehiculo', 'service auto'], iconKey: 'wrench'),
    (keywords: ['abogad', 'legal', 'notarial'], iconKey: 'gavel'),
    (keywords: ['contab', 'impuesto', 'finanz'], iconKey: 'calculator'),
    (keywords: ['inmobil', 'propiedad', 'visita prop'], iconKey: 'home'),
    (keywords: ['spa', 'wellness', 'aromater'], iconKey: 'sparkles'),
    (keywords: ['estetica', 'belleza', 'tratamiento'], iconKey: 'mirror'),
  ];
}
