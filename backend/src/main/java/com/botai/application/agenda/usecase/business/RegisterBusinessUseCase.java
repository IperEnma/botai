package com.botai.application.agenda.usecase.business;

import com.botai.application.agenda.support.AgendaPublicSlug;
import com.botai.application.agenda.support.CompanySlugSupport;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.BusinessHours;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.repository.BotWorkspaceRegistry;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

/**
 * Registra un nuevo negocio en el tenant indicado y crea sus settings
 * por defecto en la misma transacción.
 */
@Service
public class RegisterBusinessUseCase {

    private static final Logger log = LoggerFactory.getLogger(RegisterBusinessUseCase.class);

    private final BusinessRepository businessRepository;
    private final BusinessSettingsRepository settingsRepository;
    private final SaveBusinessHoursUseCase saveBusinessHours;
    private final BotWorkspaceRegistry botWorkspaceRegistry;

    public RegisterBusinessUseCase(BusinessRepository businessRepository,
                                   BusinessSettingsRepository settingsRepository,
                                   SaveBusinessHoursUseCase saveBusinessHours,
                                   BotWorkspaceRegistry botWorkspaceRegistry) {
        this.businessRepository = businessRepository;
        this.settingsRepository = settingsRepository;
        this.saveBusinessHours = saveBusinessHours;
        this.botWorkspaceRegistry = botWorkspaceRegistry;
    }

    @Transactional
    public Business execute(String tenantId,
                            String nombre,
                            String descripcion,
                            UUID ownerUserId,
                            List<String> searchTags) {
        UUID newId = UUID.randomUUID();
        Long botId = botWorkspaceRegistry.findBotIdByWorkspaceTenantId(tenantId).orElse(null);
        String publicSlug = AgendaPublicSlug.forNewBusiness(newId, nombre);
        String companySlug = CompanySlugSupport.resolveForNewBusiness(businessRepository, tenantId, nombre);
        Business business = new Business(
                newId,
                tenantId,
                nombre,
                descripcion,
                ownerUserId,
                searchTags == null ? List.of() : searchTags,
                true,
                null,  // logoUrl
                null,  // colorPrimario
                null,  // instagramUrl
                null,  // tiktokUrl
                null,  // facebookUrl
                null,  // colorFondo
                null,  // fontFamily
                publicSlug,
                companySlug,
                botId,
                null,
                null,
                null
        );
        Business saved = businessRepository.save(business);
        settingsRepository.save(BusinessSettings.defaults(saved.getId()));

        // Horarios default para que el negocio tenga disponibilidad pública inicial.
        // El admin puede reemplazarlos desde el panel privado.
        List<BusinessHours> defaultHours = List.of(
                // lun-vie 09:00-18:00
                new BusinessHours(UUID.randomUUID(), saved.getId(), 0, LocalTime.of(9, 0), LocalTime.of(18, 0), null, null, false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 1, LocalTime.of(9, 0), LocalTime.of(18, 0), null, null, false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 2, LocalTime.of(9, 0), LocalTime.of(18, 0), null, null, false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 3, LocalTime.of(9, 0), LocalTime.of(18, 0), null, null, false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 4, LocalTime.of(9, 0), LocalTime.of(18, 0), null, null, false),
                // sábado 09:00-13:00
                new BusinessHours(UUID.randomUUID(), saved.getId(), 5, LocalTime.of(9, 0), LocalTime.of(13, 0), null, null, false),
                // domingo cerrado
                new BusinessHours(UUID.randomUUID(), saved.getId(), 6, LocalTime.of(9, 0), LocalTime.of(13, 0), null, null, true)
        );
        saveBusinessHours.execute(tenantId, saved.getId(), defaultHours);

        log.info("AGENDA: negocio registrado id={} tenantId={}", saved.getId(), tenantId);
        return saved;
    }
}
