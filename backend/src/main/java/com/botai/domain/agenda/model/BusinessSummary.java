package com.botai.domain.agenda.model;

import java.util.List;
import java.util.UUID;

/**
 * Proyección liviana de un negocio para respuestas de búsqueda pública.
 * Solo incluye lo que la UI del buscador necesita, sin exponer campos internos.
 */
public final class BusinessSummary {

    private final UUID id;
    private final String tenantId;
    private final String nombre;
    private final String descripcion;
    private final List<String> categorySlugs;
    private final String logoUrl;

    public BusinessSummary(UUID id, String tenantId, String nombre, String descripcion,
                           List<String> categorySlugs, String logoUrl) {
        this.id = id;
        this.tenantId = tenantId;
        this.nombre = nombre;
        this.descripcion = descripcion;
        this.categorySlugs = categorySlugs == null ? List.of() : List.copyOf(categorySlugs);
        this.logoUrl = logoUrl;
    }

    public UUID getId() { return id; }
    public String getTenantId() { return tenantId; }
    public String getNombre() { return nombre; }
    public String getDescripcion() { return descripcion; }
    public List<String> getCategorySlugs() { return categorySlugs; }
    public String getLogoUrl() { return logoUrl; }
}
