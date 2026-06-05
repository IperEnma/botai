package com.botai.infrastructure.agenda.config;

import com.botai.application.agenda.support.AgendaSecurityHasher;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.stereotype.Component;

import java.util.Arrays;

/**
 * Falla el arranque en perfil prod si el pepper de hash OTP/sesión sigue siendo el de desarrollo.
 */
@Component
public class AgendaPhoneVerificationStartupValidator implements ApplicationListener<ApplicationReadyEvent> {

    private static final Logger log = LoggerFactory.getLogger(AgendaPhoneVerificationStartupValidator.class);

    private final boolean prodGuardEnabled;
    private final AgendaSecurityHasher hasher;
    private final String activeProfiles;

    public AgendaPhoneVerificationStartupValidator(
            @Value("${agenda.phone.verification.prod-guard-enabled:true}") boolean prodGuardEnabled,
            AgendaSecurityHasher hasher,
            @Value("${spring.profiles.active:}") String activeProfiles) {
        this.prodGuardEnabled = prodGuardEnabled;
        this.hasher = hasher;
        this.activeProfiles = activeProfiles;
    }

    @Override
    public void onApplicationEvent(ApplicationReadyEvent event) {
        if (!prodGuardEnabled || !isProdProfile()) {
            return;
        }
        if (hasher.isDevPepper()) {
            throw new IllegalStateException(
                    "Configurá agenda.phone.verification.hash-pepper (AGENDA_PHONE_VERIFICATION_HASH_PEPPER) "
                            + "con un valor único en producción.");
        }
        log.info("Agenda phone verification prod guard OK (pepper={})", hasher.pepperForDiagnostics());
    }

    private boolean isProdProfile() {
        if (activeProfiles == null || activeProfiles.isBlank()) {
            return false;
        }
        return Arrays.stream(activeProfiles.split(","))
                .map(String::trim)
                .anyMatch(p -> p.equalsIgnoreCase("prod") || p.equalsIgnoreCase("production"));
    }
}
