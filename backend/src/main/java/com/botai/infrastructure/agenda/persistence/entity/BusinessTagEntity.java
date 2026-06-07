package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.util.UUID;

/**
 * Etiqueta tipada de un negocio ({@code profile}, {@code location}, …).
 * Esquema generado por Hibernate; sin migración Flyway de CREATE TABLE.
 */
@Entity
@Table(
        name = "agenda_business_tags",
        indexes = {
                @Index(name = "idx_agenda_business_tags_business", columnList = "business_id"),
                @Index(name = "idx_agenda_business_tags_value", columnList = "value")
        },
        uniqueConstraints = @UniqueConstraint(
                name = "ux_agenda_business_tags_business_value_type",
                columnNames = {"business_id", "value", "type"}
        )
)
public class BusinessTagEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "business_id", nullable = false, updatable = false)
    private UUID businessId;

    @Column(name = "value", nullable = false, length = 100, updatable = false)
    private String value;

    @Column(name = "type", nullable = false, length = 32, updatable = false)
    private String type;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public String getValue() { return value; }
    public void setValue(String value) { this.value = value; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
}
