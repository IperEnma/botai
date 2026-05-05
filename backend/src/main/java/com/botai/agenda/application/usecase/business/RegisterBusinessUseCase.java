package com.botai.agenda.application.usecase.business;

import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    public RegisterBusinessUseCase(BusinessRepository businessRepository,
                                   BusinessSettingsRepository settingsRepository) {
        this.businessRepository = businessRepository;
        this.settingsRepository = settingsRepository;
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
                null,
                null,
                null
        );
        Business saved = businessRepository.save(business);
        settingsRepository.save(BusinessSettings.defaults(saved.getId()));
        log.info("AGENDA: negocio registrado id={} tenantId={}", saved.getId(), tenantId);
        return saved;
    }
}
