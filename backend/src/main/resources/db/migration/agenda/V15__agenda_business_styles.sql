ALTER TABLE agenda_businesses
    ADD COLUMN IF NOT EXISTS color_fondo  VARCHAR(20),
    ADD COLUMN IF NOT EXISTS font_family  VARCHAR(100);
