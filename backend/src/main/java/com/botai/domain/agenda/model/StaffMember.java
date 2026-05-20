package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Miembro del equipo de trabajo de un negocio.
 *
 * <p>POJO inmutable. Toda la lógica de activación/desactivación vive en
 * {@code ManageStaffUseCase}; este objeto solo mantiene invariantes estructurales.</p>
 *
 * <p>El campo {@code status} reemplaza al booleano {@code activo} como fuente de verdad.
 * Los valores válidos son: {@code ACTIVO}, {@code PAUSADO}, {@code ARCHIVADO}.
 * El método {@link #isActivo()} es un getter derivado para compatibilidad.</p>
 */
public final class StaffMember {

    private final UUID id;
    private final UUID businessId;
    private final String nombre;
    private final String rol;
    private final String avatarUrl;
    private final String telefono;
    private final String email;
    private final String bio;
    private final String color;
    private final String status;
    private final String customSchedule;
    private final List<UUID> serviceIds;
    private final LocalDateTime deletedAt;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public StaffMember(UUID id,
                       UUID businessId,
                       String nombre,
                       String rol,
                       String avatarUrl,
                       String telefono,
                       String email,
                       String bio,
                       String color,
                       String status,
                       String customSchedule,
                       List<UUID> serviceIds,
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
        this.telefono = telefono;
        this.email = email;
        this.bio = bio;
        this.color = color;
        this.status = status != null ? status : "ACTIVO";
        this.customSchedule = customSchedule;
        this.serviceIds = serviceIds != null ? List.copyOf(serviceIds) : List.of();
        this.deletedAt = deletedAt;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public String getNombre() { return nombre; }
    public String getRol() { return rol; }
    public String getAvatarUrl() { return avatarUrl; }
    public String getTelefono() { return telefono; }
    public String getEmail() { return email; }
    public String getBio() { return bio; }
    public String getColor() { return color; }
    public String getStatus() { return status; }
    public String getCustomSchedule() { return customSchedule; }

    /** Getter derivado: true si {@code status} es {@code "ACTIVO"}. */
    public boolean isActivo() { return "ACTIVO".equals(status); }

    public List<UUID> getServiceIds() { return serviceIds; }
    public LocalDateTime getDeletedAt() { return deletedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
