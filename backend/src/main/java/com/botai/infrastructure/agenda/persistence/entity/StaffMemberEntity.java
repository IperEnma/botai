package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;

@Entity(name = "AgendaStaffMemberEntity")
@Table(name = "agenda_staff_members")
public class StaffMemberEntity extends BaseAuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "nombre", nullable = false, length = 100)
    private String nombre;

    @Column(name = "rol", length = 100)
    private String rol;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(name = "telefono", length = 50)
    private String telefono;

    @Column(name = "email", length = 200)
    private String email;

    @Column(name = "bio", columnDefinition = "TEXT")
    private String bio;

    @Column(name = "color", length = 7)
    private String color;

    @Column(name = "activo", nullable = false)
    private boolean activo;

    @Column(name = "status", nullable = false, columnDefinition = "varchar(20) not null default 'ACTIVO'")
    private String status;

    @Column(name = "custom_schedule", columnDefinition = "TEXT")
    private String customSchedule;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "agenda_staff_services", joinColumns = @JoinColumn(name = "staff_member_id"))
    @Column(name = "service_id")
    private Set<UUID> serviceIds = new LinkedHashSet<>();

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public String getRol() { return rol; }
    public void setRol(String rol) { this.rol = rol; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }

    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCustomSchedule() { return customSchedule; }
    public void setCustomSchedule(String customSchedule) { this.customSchedule = customSchedule; }

    public LocalDateTime getDeletedAt() { return deletedAt; }
    public void setDeletedAt(LocalDateTime deletedAt) { this.deletedAt = deletedAt; }

    public Set<UUID> getServiceIds() { return serviceIds; }
    public void setServiceIds(Set<UUID> serviceIds) { this.serviceIds = serviceIds; }
}
