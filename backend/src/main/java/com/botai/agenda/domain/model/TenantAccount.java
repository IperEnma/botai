package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Cuenta de tenant registrado en el módulo AGENDA.
 * POJO inmutable — no depende de Spring ni JPA.
 */
public final class TenantAccount {

    private final String tenantId;
    private final String nombrePropietario;
    private final String email;
    private final String telefono;
    private final String accessCode;
    private final boolean activo;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public TenantAccount(String tenantId,
                         String nombrePropietario,
                         String email,
                         String telefono,
                         String accessCode,
                         boolean activo,
                         LocalDateTime createdAt,
                         LocalDateTime updatedAt) {
        this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
        this.nombrePropietario = Objects.requireNonNull(nombrePropietario, "nombrePropietario");
        this.email = Objects.requireNonNull(email, "email");
        this.telefono = telefono;
        this.accessCode = Objects.requireNonNull(accessCode, "accessCode");
        this.activo = activo;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public String getTenantId() { return tenantId; }
    public String getNombrePropietario() { return nombrePropietario; }
    public String getEmail() { return email; }
    public String getTelefono() { return telefono; }
    public String getAccessCode() { return accessCode; }
    public boolean isActivo() { return activo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
