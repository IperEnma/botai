-- V5 — Tabla de relación staff-servicios
-- Permite asignar qué servicios puede atender cada miembro del equipo.

CREATE TABLE IF NOT EXISTS agenda_staff_services (
    staff_member_id UUID NOT NULL,
    service_id      UUID NOT NULL,
    PRIMARY KEY (staff_member_id, service_id),
    CONSTRAINT fk_ass_staff    FOREIGN KEY (staff_member_id) REFERENCES agenda_staff_members (id) ON DELETE CASCADE,
    CONSTRAINT fk_ass_service  FOREIGN KEY (service_id)      REFERENCES agenda_services       (id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_agenda_staff_services_staff
    ON agenda_staff_services (staff_member_id);
