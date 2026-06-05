-- Confirmación manual de reservas por negocio (JPA también crea la columna con ddl-auto).
ALTER TABLE agenda_business_settings
    ADD COLUMN IF NOT EXISTS require_booking_confirmation BOOLEAN NOT NULL DEFAULT TRUE;
