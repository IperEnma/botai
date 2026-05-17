DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'excl_agenda_bookings_slot'
    ) THEN
        ALTER TABLE agenda_bookings
            ADD CONSTRAINT excl_agenda_bookings_slot
            EXCLUDE USING gist (
                business_id   WITH =,
                service_id    WITH =,
                tsrange(fecha_hora_inicio, fecha_hora_fin, '[)') WITH &&
            ) WHERE (estado IN ('PENDING', 'CONFIRMED'));
    END IF;
END $$;
