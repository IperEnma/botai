package com.botai.application.chatbot.service.admin;

import com.botai.infrastructure.chatbot.persistence.entity.ServiceEntity;
import com.botai.infrastructure.chatbot.persistence.jpa.ServiceJpaRepository;
import com.botai.infrastructure.chatbot.rag.RagSourceSync;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;
import java.util.Optional;

/**
 * Casos de uso de administración de servicios del negocio (corte, tintura, etc.).
 * Persiste y sincroniza los chunks RAG (vectores) para el tenant.
 */
@Service
public class BusinessServiceAdminService {

    private final ServiceJpaRepository serviceRepository;
    private final RagSourceSync ragSourceSync;

    public BusinessServiceAdminService(ServiceJpaRepository serviceRepository,
                                        RagSourceSync ragSourceSync) {
        this.serviceRepository = serviceRepository;
        this.ragSourceSync = ragSourceSync;
    }

    public java.util.List<ServiceEntity> getByTenant(String tenantId) {
        return serviceRepository.findByTenantIdOrderBySortOrderAsc(tenantId);
    }

    @Transactional
    public ServiceEntity create(String tenantId, Map<String, Object> body) {
        ServiceEntity e = new ServiceEntity();
        e.setTenantId(tenantId);
        e.setName(body.get("name") != null ? body.get("name").toString() : "");
        e.setSortOrder(body.get("sortOrder") != null ? ((Number) body.get("sortOrder")).intValue() : 0);
        e.setActive(true);
        ServiceEntity saved = serviceRepository.save(e);
        ragSourceSync.refreshForTenant(tenantId);
        return saved;
    }

    @Transactional
    public Optional<ServiceEntity> update(String tenantId, Long serviceId, Map<String, Object> body) {
        return serviceRepository.findById(serviceId)
            .filter(s -> tenantId.equals(s.getTenantId()))
            .map(s -> {
                if (body.get("name") != null) s.setName(body.get("name").toString());
                if (body.get("sortOrder") != null) s.setSortOrder(((Number) body.get("sortOrder")).intValue());
                if (body.get("active") != null) s.setActive(Boolean.TRUE.equals(body.get("active")));
                ServiceEntity saved = serviceRepository.save(s);
                ragSourceSync.refreshForTenant(tenantId);
                return saved;
            });
    }

    @Transactional
    public boolean delete(String tenantId, Long serviceId) {
        boolean removed = serviceRepository.findById(serviceId)
            .filter(s -> tenantId.equals(s.getTenantId()))
            .map(s -> {
                serviceRepository.deleteById(serviceId);
                return true;
            })
            .orElse(false);
        if (removed) {
            ragSourceSync.refreshForTenant(tenantId);
        }
        return removed;
    }
}
