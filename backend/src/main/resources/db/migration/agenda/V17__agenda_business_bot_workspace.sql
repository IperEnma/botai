-- Vincula cada negocio Agenda al bot del workspace (valor = bot.id). Un bot puede tener varios negocios;
-- cada negocio tiene como mucho un bot. Mismo tenant_id en bot y agenda_businesses.
-- Sin FK a bot: las migraciones agenda corren en entornos donde la tabla bot aún no existe (orden Flyway/Hibernate).
ALTER TABLE agenda_businesses
    ADD COLUMN IF NOT EXISTS bot_id BIGINT NULL;

CREATE INDEX IF NOT EXISTS idx_agenda_businesses_bot_id ON agenda_businesses (bot_id);

-- Alinear datos existentes solo si ya existe la tabla bot (p. ej. producción / esquema completo).
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = current_schema() AND table_name = 'bot') THEN
        UPDATE agenda_businesses ab
        SET bot_id = b.id
        FROM bot b
        WHERE ab.bot_id IS NULL
          AND ab.tenant_id = b.tenant_id;
    END IF;
END $$;
