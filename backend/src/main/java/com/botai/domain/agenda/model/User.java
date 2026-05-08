package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Usuario final del módulo AGENDA (admin de negocio o cliente).
 * POJO inmutable.
 */
public final class User {

    private final UUID id;
    private final String tenantId;
    private final String nombre;
    private final String email;
    private final String telefono;
    private final UserType tipoUsuario;
    private final boolean activo;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public User(UUID id, String tenantId, String nombre, String email, String telefono,
                UserType tipoUsuario, boolean activo,
                LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
        this.nombre = Objects.requireNonNull(nombre, "nombre");
        this.email = email;
        this.telefono = telefono;
        this.tipoUsuario = Objects.requireNonNull(tipoUsuario, "tipoUsuario");
        this.activo = activo;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public String getTenantId() { return tenantId; }
    public String getNombre() { return nombre; }
    public String getEmail() { return email; }
    public String getTelefono() { return telefono; }
    public UserType getTipoUsuario() { return tipoUsuario; }
    public boolean isActivo() { return activo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
