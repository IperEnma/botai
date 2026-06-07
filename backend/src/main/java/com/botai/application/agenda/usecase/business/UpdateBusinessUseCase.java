package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/** Actualiza campos editables de un negocio del tenant. */
@Service
public class UpdateBusinessUseCase {

    private static final Logger log = LoggerFactory.getLogger(UpdateBusinessUseCase.class);

    private final BusinessRepository businessRepository;

    public UpdateBusinessUseCase(BusinessRepository businessRepository) {
        this.businessRepository = businessRepository;
    }

    @Transactional
    public Business execute(String tenantId,
                            UUID businessId,
                            String nombre,
                            String descripcion,
                            List<String> searchTags,
                            Boolean activo,
                            String logoUrl,
                            String colorPrimario,
                            String instagramUrl,
                            String tiktokUrl,
                            String facebookUrl,
                            String colorFondo,
                            String fontFamily,
                            String bannerUrl,
                            String direccion) {
        Business existing = businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Business updated = new Business(
                existing.getId(),
                existing.getTenantId(),
                nombre == null ? existing.getNombre() : nombre,
                descripcion == null ? existing.getDescripcion() : descripcion,
                existing.getOwnerUserId(),
                searchTags == null ? existing.getSearchTags() : searchTags,
                activo == null ? existing.isActivo() : activo,
                logoUrl == null ? existing.getLogoUrl() : blankToNull(logoUrl),
                colorPrimario == null ? existing.getColorPrimario() : colorPrimario,
                instagramUrl == null ? existing.getInstagramUrl() : instagramUrl,
                tiktokUrl == null ? existing.getTiktokUrl() : tiktokUrl,
                facebookUrl == null ? existing.getFacebookUrl() : facebookUrl,
                colorFondo == null ? existing.getColorFondo() : colorFondo,
                fontFamily == null ? existing.getFontFamily() : fontFamily,
                existing.getPublicSlug(),
                existing.getCompanySlug(),
                existing.getBotId(),
                bannerUrl == null ? existing.getBannerUrl() : blankToNull(bannerUrl),
                direccion == null ? existing.getDireccion() : direccion,
                existing.getDeletedAt(),
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        );
        Business saved = businessRepository.save(updated);
        log.info("AGENDA: negocio actualizado id={} tenantId={}", saved.getId(), tenantId);
        return saved;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
