package com.botai.domain.agenda.model;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

/**
 * Categoría del catálogo global (sin tenant_id). Centraliza los sinónimos
 * maestros que usa el buscador.
 */
public final class Category {

    private final UUID id;
    private final String nombre;
    private final String slug;
    private final String icono;
    private final List<String> synonyms;
    private final boolean activo;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public Category(UUID id, String nombre, String slug, String icono,
                    List<String> synonyms, boolean activo,
                    LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.nombre = Objects.requireNonNull(nombre, "nombre");
        this.slug = Objects.requireNonNull(slug, "slug");
        this.icono = icono;
        this.synonyms = synonyms == null ? List.of() : List.copyOf(synonyms);
        this.activo = activo;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public String getNombre() { return nombre; }
    public String getSlug() { return slug; }
    public String getIcono() { return icono; }
    public List<String> getSynonyms() { return synonyms; }
    public boolean isActivo() { return activo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
