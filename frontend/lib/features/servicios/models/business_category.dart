enum BusinessCategory {
  peluqueria,
  barberia,
  manicure,
  pedicure,
  spa,
  estetica,
  yogaPilates,
  otra;

  static BusinessCategory fromSlug(String slug) => switch (slug.toLowerCase()) {
        'peluqueria' => BusinessCategory.peluqueria,
        'barberia' => BusinessCategory.barberia,
        'manicure' => BusinessCategory.manicure,
        'pedicure' => BusinessCategory.pedicure,
        'spa' => BusinessCategory.spa,
        'estetica' => BusinessCategory.estetica,
        'yoga' => BusinessCategory.yogaPilates,
        _ => BusinessCategory.otra,
      };

  String get displayName => switch (this) {
        BusinessCategory.peluqueria => 'Peluquería',
        BusinessCategory.barberia => 'Barbería',
        BusinessCategory.manicure => 'Manicure',
        BusinessCategory.pedicure => 'Pedicure',
        BusinessCategory.spa => 'Spa',
        BusinessCategory.estetica => 'Estética',
        BusinessCategory.yogaPilates => 'Yoga / Pilates',
        BusinessCategory.otra => 'Otra',
      };

  String get typicalServices => switch (this) {
        BusinessCategory.peluqueria => 'CORTE · COLOR · TRATAMIENTOS',
        BusinessCategory.barberia => 'CORTE · BARBA · AFEITADO',
        BusinessCategory.manicure => 'MANOS · ESMALTE',
        BusinessCategory.pedicure => 'PIES · CUIDADO',
        BusinessCategory.spa => 'MASAJES · TRATAMIENTOS',
        BusinessCategory.estetica => 'FACIAL · CORPORAL',
        BusinessCategory.yogaPilates => 'CLASES · BIENESTAR',
        BusinessCategory.otra => 'CONFIGURÁS A MEDIDA',
      };
}
