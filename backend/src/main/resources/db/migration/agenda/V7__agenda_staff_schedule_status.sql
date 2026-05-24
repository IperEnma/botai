-- V7: agrega columnas status y custom_schedule a agenda_staff_members

ALTER TABLE agenda_staff_members
    ADD COLUMN IF NOT EXISTS status          VARCHAR(20),
    ADD COLUMN IF NOT EXISTS custom_schedule TEXT;

UPDATE agenda_staff_members
    SET status = CASE WHEN activo = true THEN 'ACTIVO' ELSE 'ARCHIVADO' END;

ALTER TABLE agenda_staff_members
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN status SET DEFAULT 'ACTIVO';

ALTER TABLE agenda_staff_members
    ADD CONSTRAINT IF NOT EXISTS chk_staff_status
    CHECK (status IN ('ACTIVO', 'PAUSADO', 'ARCHIVADO'));
