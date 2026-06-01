-- Modo de agenda por servicio: GENERAL (sin elegir profesional) o BY_STAFF.

ALTER TABLE agenda_services
    ADD COLUMN IF NOT EXISTS scheduling_mode VARCHAR(20) NOT NULL DEFAULT 'GENERAL';

ALTER TABLE agenda_services
    DROP CONSTRAINT IF EXISTS chk_agenda_services_scheduling_mode;

ALTER TABLE agenda_services
    ADD CONSTRAINT chk_agenda_services_scheduling_mode
        CHECK (scheduling_mode IN ('GENERAL', 'BY_STAFF'));
