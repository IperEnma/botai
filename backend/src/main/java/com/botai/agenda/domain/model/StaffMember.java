package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Miembro del equipo de trabajo de un negocio.
 *
 * <p>POJO inmutable. Toda la lógica de activación/desactivación vive en
 * {@code ManageStaffUseCase}; este objeto solo mantiene invariantes estructurales.</p>
 */
public final class StaffMember {

    private final UUID id;
    private final UUID businessId;
    private final String nombre;
    private final String rol;
    private final String avatarUrl;
    private final boolean activo;
    private final LocalDateTime deletedAt;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public StaffMember(UUID id,
                       UUID businessId,
                       String nombre,
                       String rol,
                       String avatarUrl,
                       boolean activo,
                       LocalDateTime deletedAt,
                       LocalDateTime createdAt,
                       LocalDateTime updatedAt) {
        if (businessId == null) {
            throw new IllegalArgumentException("businessId no puede ser nulo");
        }
        if (nombre == null || nombre.isBlank()) {
            throw new IllegalArgumentException("nombre no puede ser nulo ni vacío");
        }
        this.id = id;
        this.businessId = businessId;
        this.nombre = nombre;
        this.rol = rol;
        this.avatarUrl = avatarUrl;
        this.activo = activo;
        this.deletedAt = deletedAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public String getNombre() { return nombre; }
    public String getRol() { return rol; }
    public String getAvatarUrl() { return avatarUrl; }
    public boolean isActivo() { return activo; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
