CREATE TABLE agenda_tenant_accounts (
    tenant_id          VARCHAR(64)  NOT NULL,
    nombre_propietario VARCHAR(255) NOT NULL,
    email              VARCHAR(255) NOT NULL,
    telefono           VARCHAR(32),
    access_code        VARCHAR(8)   NOT NULL,
    activo             BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP    NOT NULL DEFAULT now(),
    updated_at         TIMESTAMP    NOT NULL DEFAULT now(),
    CONSTRAINT pk_agenda_tenant_accounts PRIMARY KEY (tenant_id),
    CONSTRAINT uk_agenda_tenant_accounts_email UNIQUE (email),
    CONSTRAINT uk_agenda_tenant_accounts_access_code UNIQUE (access_code),
    CONSTRAINT ck_agenda_tenant_accounts_email
        CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    CONSTRAINT ck_agenda_tenant_accounts_access_code
        CHECK (access_code ~ '^[A-Z0-9]{8}$')
);
CREATE INDEX idx_agenda_tenant_accounts_email ON agenda_tenant_accounts (email);
CREATE INDEX idx_agenda_tenant_accounts_access_code ON agenda_tenant_accounts (access_code);
