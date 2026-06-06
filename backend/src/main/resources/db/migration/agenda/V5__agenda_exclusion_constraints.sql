-- Responsabilidad: concurrencia / anti doble-reserva vía EXCLUDE GiST, que
-- Hibernate no modela. Requiere btree_gist (habilitado en V1). Idempotente.

-- Anti doble reserva por negocio+servicio.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'excl_agenda_bookings_slot') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT excl_agenda_bookings_slot
            EXCLUDE USING gist (
                business_id   WITH =,
                service_id    WITH =,
                tsrange(fecha_hora_inicio, fecha_hora_fin, '[)') WITH &&
            ) WHERE (estado IN ('PENDING', 'CONFIRMED'));
    END IF;
END $$;

-- Anti doble reserva por PROFESIONAL: un mismo staff no puede solaparse.
-- JpaBookingRepository espera este nombre para traducir la violación a BookingSlotTakenException.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'excl_agenda_bookings_staff_slot') THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT excl_agenda_bookings_staff_slot
            EXCLUDE USING gist (
                business_id     WITH =,
                staff_member_id WITH =,
                tsrange(fecha_hora_inicio, fecha_hora_fin, '[)') WITH &&
            ) WHERE (estado IN ('PENDING', 'CONFIRMED') AND staff_member_id IS NOT NULL);
    END IF;
END $$;
