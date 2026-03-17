package com.botai.chatbot.application.service;

import com.botai.chatbot.infrastructure.persistence.entity.BusinessHoursEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.BusinessHoursJpaRepository;
import com.botai.chatbot.infrastructure.rag.RagSourceSync;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/**
 * Casos de uso de administración de horarios del negocio.
 * Persiste y sincroniza los chunks RAG (vectores) para el tenant.
 */
@Service
public class BusinessHoursAdminService {

    private final BusinessHoursJpaRepository businessHoursRepository;
    private final RagSourceSync ragSourceSync;

    public BusinessHoursAdminService(BusinessHoursJpaRepository businessHoursRepository,
                                      RagSourceSync ragSourceSync) {
        this.businessHoursRepository = businessHoursRepository;
        this.ragSourceSync = ragSourceSync;
    }

    public List<BusinessHoursEntity> getByTenant(String tenantId) {
        return businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId);
    }

    @Transactional
    public List<BusinessHoursEntity> save(String tenantId, List<Map<String, Object>> body) {
        businessHoursRepository.deleteByTenantId(tenantId);
        for (Map<String, Object> row : body) {
            Number dayNum = (Number) row.get("dayOfWeek");
            if (dayNum == null) continue;
            int day = dayNum.intValue();
            if (day < 1 || day > 7) continue;
            String open = row.get("openTime") != null ? row.get("openTime").toString().trim() : null;
            String close = row.get("closeTime") != null ? row.get("closeTime").toString().trim() : null;
            if (open != null && open.isEmpty()) open = null;
            if (close != null && close.isEmpty()) close = null;
            BusinessHoursEntity e = new BusinessHoursEntity();
            e.setTenantId(tenantId);
            e.setDayOfWeek(day);
            e.setOpenTime(open);
            e.setCloseTime(close);
            businessHoursRepository.save(e);
        }
        ragSourceSync.refreshForTenant(tenantId);
        return businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId);
    }
}
