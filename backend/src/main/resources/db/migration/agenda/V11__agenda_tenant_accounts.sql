-- Cuenta de tenant: alta por correo (`email`) o por WhatsApp (`numero`, solo dígitos).
-- Exactamente uno de los dos debe estar presente. `google_linked_email` vincula sesión Google (opcional).

CREATE TABLE agenda_tenant_accounts (
    tenant_id           VARCHAR(64)  NOT NULL,
    nombre_propietario  VARCHAR(255) NOT NULL,
    email               VARCHAR(255),
    numero              VARCHAR(32),
    google_linked_email VARCHAR(320),
    telefono            VARCHAR(32),
    access_code         VARCHAR(8)   NOT NULL,
    activo              BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at          TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_tenant_accounts PRIMARY KEY (tenant_id),
    CONSTRAINT uk_agenda_tenant_accounts_access_code UNIQUE (access_code),
    CONSTRAINT ck_agenda_tenant_accounts_access_code
        CHECK (access_code ~ '^[A-Z0-9]{8}$'),
    CONSTRAINT ck_agenda_tenant_accounts_login
        CHECK (numero IS NOT NULL OR email IS NOT NULL),
    CONSTRAINT ck_agenda_tenant_accounts_email
        CHECK (email IS NULL OR email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    CONSTRAINT ck_agenda_tenant_accounts_google_linked_email
        CHECK (google_linked_email IS NULL OR google_linked_email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    CONSTRAINT ck_agenda_tenant_accounts_numero
        CHECK (numero IS NULL OR numero ~ '^[0-9]{8,32}$')
);

CREATE UNIQUE INDEX uk_agenda_tenant_accounts_email
    ON agenda_tenant_accounts (email)
    WHERE email IS NOT NULL;

CREATE UNIQUE INDEX uk_agenda_tenant_accounts_numero
    ON agenda_tenant_accounts (numero)
    WHERE numero IS NOT NULL;

CREATE UNIQUE INDEX uk_agenda_tenant_accounts_google_linked_email
    ON agenda_tenant_accounts (google_linked_email)
    WHERE google_linked_email IS NOT NULL;

CREATE INDEX idx_agenda_tenant_accounts_access_code ON agenda_tenant_accounts (access_code);
