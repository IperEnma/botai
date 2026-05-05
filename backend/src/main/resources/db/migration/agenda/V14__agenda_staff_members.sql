CREATE TABLE agenda_staff_members (
    id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    business_id UUID         NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    rol         VARCHAR(100),
    avatar_url  VARCHAR(500),
    activo      BOOLEAN      NOT NULL DEFAULT true,
    deleted_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT pk_agenda_staff_members PRIMARY KEY (id),
    CONSTRAINT fk_agenda_staff_members_business
        FOREIGN KEY (business_id) REFERENCES agenda_businesses (id) ON DELETE CASCADE
);

CREATE INDEX idx_agenda_staff_members_business
    ON agenda_staff_members (business_id)
    WHERE deleted_at IS NULL;

ALTER TABLE agenda_bookings
    ADD COLUMN IF NOT EXISTS staff_member_id UUID;

ALTER TABLE agenda_bookings
    ADD CONSTRAINT fk_agenda_bookings_staff
        FOREIGN KEY (staff_member_id) REFERENCES agenda_staff_members (id)
        ON DELETE SET NULL;
