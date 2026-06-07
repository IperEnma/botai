package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.BusinessSummary;

import java.util.List;
import java.util.UUID;

/**
 * Puerto del buscador público. El adapter resuelve la query contra
 * {@code agenda_categories.synonyms}, {@code agenda_business_tags} y
 * el nombre del negocio.
 */
public interface BusinessSearchRepository {

    /**
     * Busca negocios por término libre (ej. "uñas"). Aplica:
     * <ol>
     *   <li>Match contra sinónimos del catálogo global.</li>
     *   <li>Match contra etiquetas tipadas del negocio ({@code agenda_business_tags}).</li>
     *   <li>Match por nombre con unaccent + ILIKE.</li>
     * </ol>
     * Filtra activos y no borrados. Opcionalmente acota por tenantId.
     */
    List<BusinessSummary> searchByTerm(String term, String tenantId, int limit, int offset);

    /** Lista negocios de una categoría (por slug del catálogo global). */
    List<BusinessSummary> findByCategorySlug(String slug, int limit, int offset);

    /** Detalle público de un negocio (incluye sus categorías). */
    BusinessSummary findPublicById(UUID businessId);
}
