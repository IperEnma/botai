package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

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

    private StaffMember(Builder b) {
        if (b.businessId == null) throw new IllegalArgumentException("businessId no puede ser nulo");
        if (b.nombre == null || b.nombre.isBlank()) throw new IllegalArgumentException("nombre no puede ser nulo ni vacío");
        this.id             = b.id;
        this.businessId     = b.businessId;
        this.nombre         = b.nombre;
        this.rol            = b.rol;
        this.avatarUrl      = b.avatarUrl;
        this.telefono       = b.telefono;
        this.email          = b.email;
        this.bio            = b.bio;
        this.color          = b.color;
        this.status         = b.status != null ? b.status : "ACTIVO";
        this.customSchedule = b.customSchedule;
        this.serviceIds     = b.serviceIds != null ? List.copyOf(b.serviceIds) : List.of();
        this.deletedAt      = b.deletedAt;
        this.createdAt      = b.createdAt;
        this.updatedAt      = b.updatedAt;
    }

    public static Builder builder() { return new Builder(); }

    public static final class Builder {
        private UUID id;
        private UUID businessId;
        private String nombre;
        private String rol;
        private String avatarUrl;
        private String telefono;
        private String email;
        private String bio;
        private String color;
        private String status;
        private String customSchedule;
        private List<UUID> serviceIds;
        private LocalDateTime deletedAt;
        private LocalDateTime createdAt;
        private LocalDateTime updatedAt;

        public Builder id(UUID v)                       { this.id = v;             return this; }
        public Builder businessId(UUID v)               { this.businessId = v;     return this; }
        public Builder nombre(String v)                 { this.nombre = v;         return this; }
        public Builder rol(String v)                    { this.rol = v;            return this; }
        public Builder avatarUrl(String v)              { this.avatarUrl = v;      return this; }
        public Builder telefono(String v)               { this.telefono = v;       return this; }
        public Builder email(String v)                  { this.email = v;          return this; }
        public Builder bio(String v)                    { this.bio = v;            return this; }
        public Builder color(String v)                  { this.color = v;          return this; }
        public Builder status(String v)                 { this.status = v;         return this; }
        public Builder customSchedule(String v)         { this.customSchedule = v; return this; }
        public Builder serviceIds(List<UUID> v)         { this.serviceIds = v;     return this; }
        public Builder deletedAt(LocalDateTime v)       { this.deletedAt = v;      return this; }
        public Builder createdAt(LocalDateTime v)       { this.createdAt = v;      return this; }
        public Builder updatedAt(LocalDateTime v)       { this.updatedAt = v;      return this; }

        public StaffMember build() { return new StaffMember(this); }
    }

    public UUID getId()                  { return id; }
    public UUID getBusinessId()          { return businessId; }
    public String getNombre()            { return nombre; }
    public String getRol()               { return rol; }
    public String getAvatarUrl()         { return avatarUrl; }
    public String getTelefono()          { return telefono; }
    public String getEmail()             { return email; }
    public String getBio()               { return bio; }
    public String getColor()             { return color; }
    public String getStatus()            { return status; }
    public boolean isActivo()            { return "ACTIVO".equals(status); }
    public String getCustomSchedule()    { return customSchedule; }
    public List<UUID> getServiceIds()    { return serviceIds; }
    public LocalDateTime getDeletedAt()  { return deletedAt; }
    public LocalDateTime getCreatedAt()  { return createdAt; }
    public LocalDateTime getUpdatedAt()  { return updatedAt; }
}
