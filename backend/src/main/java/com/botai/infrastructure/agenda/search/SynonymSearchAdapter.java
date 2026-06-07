package com.botai.infrastructure.agenda.search;

import com.botai.domain.agenda.model.BusinessSummary;
import com.botai.domain.agenda.repository.BusinessSearchRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import jakarta.persistence.Query;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Repository
public class SynonymSearchAdapter implements BusinessSearchRepository {

    private static final Logger log = LoggerFactory.getLogger(SynonymSearchAdapter.class);

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    @Transactional(readOnly = true)
    public List<BusinessSummary> searchByTerm(String term, String tenantId, int limit, int offset) {
        if (term == null || term.isBlank()) {
            return findAllActive(tenantId, limit, offset);
        }

        boolean hasTenant = tenantId != null && !tenantId.isBlank();
        String sql = "SELECT b.id, b.tenant_id, b.nombre, b.descripcion,"
                + " ARRAY_AGG(DISTINCT c.slug) FILTER (WHERE c.slug IS NOT NULL) AS categories,"
                + " b.logo_url, b.public_slug"
                + " FROM agenda_businesses b"
                + " LEFT JOIN agenda_business_categories bc ON bc.business_id = b.id"
                + " LEFT JOIN agenda_categories c ON c.id = bc.category_id"
                + " WHERE ("
                + "   c.synonyms @> to_jsonb(CAST(:term AS text))"
                + "   OR b.search_tags @> to_jsonb(CAST(:term AS text))"
                + "   OR unaccent(LOWER(b.nombre)) LIKE unaccent(LOWER('%' || :term || '%'))"
                + "   OR unaccent(LOWER(c.nombre)) LIKE unaccent(LOWER('%' || :term || '%'))"
                + " )"
                + " AND b.activo = TRUE"
                + " AND b.deleted_at IS NULL"
                + (hasTenant ? " AND b.tenant_id = :tenantId" : "")
                + " GROUP BY b.id, b.tenant_id, b.nombre, b.descripcion, b.logo_url, b.public_slug"
                + " ORDER BY b.nombre ASC"
                + " LIMIT :lim OFFSET :off";

        Query query = entityManager.createNativeQuery(sql);
        query.setParameter("term", term);
        if (hasTenant) query.setParameter("tenantId", tenantId);
        query.setParameter("lim", Math.max(1, Math.min(limit, 100)));
        query.setParameter("off", Math.max(offset, 0));

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();
        return mapRows(rows);
    }

    @Override
    @Transactional(readOnly = true)
    public List<BusinessSummary> findByCategorySlug(String slug, int limit, int offset) {
        if (slug == null || slug.isBlank()) {
            return List.of();
        }
        String sql = "SELECT b.id, b.tenant_id, b.nombre, b.descripcion,"
                + " ARRAY_AGG(DISTINCT c2.slug) FILTER (WHERE c2.slug IS NOT NULL) AS categories,"
                + " b.logo_url, b.public_slug"
                + " FROM agenda_businesses b"
                + " JOIN agenda_business_categories bc ON bc.business_id = b.id"
                + " JOIN agenda_categories c ON c.id = bc.category_id"
                + " LEFT JOIN agenda_business_categories bc2 ON bc2.business_id = b.id"
                + " LEFT JOIN agenda_categories c2 ON c2.id = bc2.category_id"
                + " WHERE c.slug = :slug"
                + " AND b.activo = TRUE"
                + " AND b.deleted_at IS NULL"
                + " GROUP BY b.id, b.tenant_id, b.nombre, b.descripcion, b.logo_url, b.public_slug"
                + " ORDER BY b.nombre ASC"
                + " LIMIT :lim OFFSET :off";

        Query query = entityManager.createNativeQuery(sql);
        query.setParameter("slug", slug);
        query.setParameter("lim", Math.max(1, Math.min(limit, 100)));
        query.setParameter("off", Math.max(offset, 0));

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();
        return mapRows(rows);
    }

    @Override
    @Transactional(readOnly = true)
    public BusinessSummary findPublicById(UUID businessId) {
        if (businessId == null) {
            return null;
        }
        String sql = "SELECT b.id, b.tenant_id, b.nombre, b.descripcion,"
                + " ARRAY_AGG(DISTINCT c.slug) FILTER (WHERE c.slug IS NOT NULL) AS categories,"
                + " b.logo_url, b.public_slug"
                + " FROM agenda_businesses b"
                + " LEFT JOIN agenda_business_categories bc ON bc.business_id = b.id"
                + " LEFT JOIN agenda_categories c ON c.id = bc.category_id"
                + " WHERE b.id = :id"
                + " AND b.activo = TRUE"
                + " AND b.deleted_at IS NULL"
                + " GROUP BY b.id, b.tenant_id, b.nombre, b.descripcion, b.logo_url, b.public_slug";

        Query query = entityManager.createNativeQuery(sql);
        query.setParameter("id", businessId);

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();
        List<BusinessSummary> result = mapRows(rows);
        return result.isEmpty() ? null : result.get(0);
    }

    private List<BusinessSummary> findAllActive(String tenantId, int limit, int offset) {
        boolean hasTenant = tenantId != null && !tenantId.isBlank();
        String sql = "SELECT b.id, b.tenant_id, b.nombre, b.descripcion,"
                + " ARRAY_AGG(DISTINCT c.slug) FILTER (WHERE c.slug IS NOT NULL) AS categories,"
                + " b.logo_url, b.public_slug"
                + " FROM agenda_businesses b"
                + " LEFT JOIN agenda_business_categories bc ON bc.business_id = b.id"
                + " LEFT JOIN agenda_categories c ON c.id = bc.category_id"
                + " WHERE b.activo = TRUE"
                + " AND b.deleted_at IS NULL"
                + (hasTenant ? " AND b.tenant_id = :tenantId" : "")
                + " GROUP BY b.id, b.tenant_id, b.nombre, b.descripcion, b.logo_url, b.public_slug"
                + " ORDER BY b.nombre ASC"
                + " LIMIT :lim OFFSET :off";

        Query query = entityManager.createNativeQuery(sql);
        if (hasTenant) query.setParameter("tenantId", tenantId);
        query.setParameter("lim", Math.max(1, Math.min(limit, 100)));
        query.setParameter("off", Math.max(offset, 0));

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();
        return mapRows(rows);
    }

    private List<BusinessSummary> mapRows(List<Object[]> rows) {
        List<BusinessSummary> result = new ArrayList<>(rows.size());
        for (Object[] row : rows) {
            UUID id = row[0] instanceof UUID u ? u : UUID.fromString(row[0].toString());
            String tenantId = (String) row[1];
            String nombre = (String) row[2];
            String descripcion = (String) row[3];
            List<String> slugs = toSlugList(row[4]);
            String logoUrl = row.length > 5 ? (String) row[5] : null;
            String publicSlug = row.length > 6 ? (String) row[6] : null;
            result.add(new BusinessSummary(id, tenantId, nombre, descripcion, slugs, logoUrl, publicSlug));
        }
        return result;
    }

    private List<String> toSlugList(Object raw) {
        if (raw == null) {
            return List.of();
        }
        if (raw instanceof String[] arr) {
            return List.of(arr);
        }
        if (raw instanceof Object[] arr) {
            List<String> list = new ArrayList<>(arr.length);
            for (Object o : arr) {
                if (o != null) list.add(o.toString());
            }
            return list;
        }
        log.warn("SynonymSearchAdapter: tipo inesperado para columna de slugs: {}", raw.getClass());
        return List.of();
    }
}
