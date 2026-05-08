package com.botai.agenda.application.usecase.business;

import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.BusinessHours;
import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
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

    public RegisterBusinessUseCase(BusinessRepository businessRepository,
                                   BusinessSettingsRepository settingsRepository,
                                   SaveBusinessHoursUseCase saveBusinessHours) {
        this.businessRepository = businessRepository;
        this.settingsRepository = settingsRepository;
        this.saveBusinessHours = saveBusinessHours;
    }

    @Transactional
    public Business execute(String tenantId,
                            String nombre,
                            String descripcion,
                            UUID ownerUserId,
                            List<String> searchTags) {
        UUID newId = UUID.randomUUID();
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
                null,  // publicSlug
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
                new BusinessHours(UUID.randomUUID(), saved.getId(), 0, LocalTime.of(9, 0), LocalTime.of(18, 0), false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 1, LocalTime.of(9, 0), LocalTime.of(18, 0), false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 2, LocalTime.of(9, 0), LocalTime.of(18, 0), false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 3, LocalTime.of(9, 0), LocalTime.of(18, 0), false),
                new BusinessHours(UUID.randomUUID(), saved.getId(), 4, LocalTime.of(9, 0), LocalTime.of(18, 0), false),
                // sábado 09:00-13:00
                new BusinessHours(UUID.randomUUID(), saved.getId(), 5, LocalTime.of(9, 0), LocalTime.of(13, 0), false),
                // domingo cerrado
                new BusinessHours(UUID.randomUUID(), saved.getId(), 6, LocalTime.of(9, 0), LocalTime.of(13, 0), true)
        );
        saveBusinessHours.execute(tenantId, saved.getId(), defaultHours);

        log.info("AGENDA: negocio registrado id={} tenantId={}", saved.getId(), tenantId);
        return saved;
    }
}
