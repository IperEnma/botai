-- Responsabilidad (V4): UNIQUE parciales que Hibernate no modela. Idempotente.
-- Ver backend/docs/AGENDA_FLYWAY_MIGRATIONS.md

CREATE UNIQUE INDEX IF NOT EXISTS uk_agenda_tenant_accounts_email
    ON agenda_tenant_accounts (email)
    WHERE email IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uk_agenda_tenant_accounts_numero
    ON agenda_tenant_accounts (numero)
    WHERE numero IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uk_agenda_tenant_accounts_google_linked_email
    ON agenda_tenant_accounts (google_linked_email)
    WHERE google_linked_email IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS ux_agenda_businesses_public_slug
    ON agenda_businesses (public_slug)
    WHERE public_slug IS NOT NULL AND public_slug <> '';

-- (tenant_id, telefono): identidad del cliente usada por AgendaClientResolver.
CREATE UNIQUE INDEX IF NOT EXISTS uk_agenda_users_tenant_telefono
    ON agenda_users (tenant_id, telefono)
    WHERE telefono IS NOT NULL AND telefono <> '';
