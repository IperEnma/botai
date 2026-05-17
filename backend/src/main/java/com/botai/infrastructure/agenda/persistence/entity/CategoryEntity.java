package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(
        name = "agenda_categories",
        uniqueConstraints = @UniqueConstraint(name = "uk_agenda_categories_slug", columnNames = "slug"))
public class CategoryEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "nombre", nullable = false, length = 120)
    private String nombre;

    @Column(name = "slug", nullable = false, length = 120)
    private String slug;

    @Column(name = "icono", length = 64)
    private String icono;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "synonyms", nullable = false, columnDefinition = "jsonb")
    private List<String> synonyms = new ArrayList<>();

    @Column(name = "activo", nullable = false)
    private boolean activo = true;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    public String getSlug() { return slug; }
    public void setSlug(String slug) { this.slug = slug; }
    public String getIcono() { return icono; }
    public void setIcono(String icono) { this.icono = icono; }
    public List<String> getSynonyms() { return synonyms; }
    public void setSynonyms(List<String> synonyms) { this.synonyms = synonyms; }
    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }
}
