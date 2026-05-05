-- ============================================================================
-- V2__agenda_seed_categories.sql
-- Seed del catálogo global de categorías con sus sinónimos maestros.
-- Idempotente vía ON CONFLICT (slug) DO NOTHING — tolera reruns.
-- ============================================================================

INSERT INTO agenda_categories (id, nombre, slug, icono, synonyms) VALUES
    (gen_random_uuid(), 'Peluquería',  'peluqueria',  'scissors',
        '["peluqueria","peluquero","peluquera","pelu","corte de pelo","cabello","salón de belleza","salon"]'::jsonb),
    (gen_random_uuid(), 'Barbería',    'barberia',    'razor',
        '["barberia","barbero","barba","afeitado","corte masculino"]'::jsonb),
    (gen_random_uuid(), 'Manicure',    'manicure',    'hand',
        '["manicure","manicura","uñas","uñitas","mani","esmalte","nail","nails"]'::jsonb),
    (gen_random_uuid(), 'Pedicure',    'pedicure',    'foot',
        '["pedicure","pedicura","pies","uñas de los pies","pedi"]'::jsonb),
    (gen_random_uuid(), 'Spa',         'spa',         'sparkles',
        '["spa","relax","relajacion","relajación","jacuzzi","sauna","wellness"]'::jsonb),
    (gen_random_uuid(), 'Yoga',        'yoga',        'lotus',
        '["yoga","yogui","meditación","meditacion","pilates","mindfulness"]'::jsonb),
    (gen_random_uuid(), 'Gimnasio',    'gimnasio',    'dumbbell',
        '["gimnasio","gym","fitness","entrenamiento","pesas","crossfit","funcional"]'::jsonb),
    (gen_random_uuid(), 'Tatuajes',    'tatuajes',    'needle',
        '["tatuajes","tatuaje","tattoo","tatuador","piercing"]'::jsonb),
    (gen_random_uuid(), 'Masajes',     'masajes',     'hands',
        '["masajes","masaje","masajista","masoterapia","terapéutico","descontracturante"]'::jsonb),
    (gen_random_uuid(), 'Estética',    'estetica',    'mirror',
        '["estetica","estética","belleza","facial","tratamiento facial","depilacion","depilación"]'::jsonb)
ON CONFLICT (slug) DO NOTHING;
