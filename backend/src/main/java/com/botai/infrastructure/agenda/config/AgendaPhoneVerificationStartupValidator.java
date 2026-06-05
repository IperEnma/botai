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
 * Falla el arranque en perfil prod si el pepper de hash OTP/sesión sigue siendo el de desarrollo
 * o si las URLs públicas no usan HTTPS.
 */
@Component
public class AgendaPhoneVerificationStartupValidator implements ApplicationListener<ApplicationReadyEvent> {

    private static final Logger log = LoggerFactory.getLogger(AgendaPhoneVerificationStartupValidator.class);

    private final boolean prodGuardEnabled;
    private final AgendaSecurityHasher hasher;
    private final String activeProfiles;
    private final String publicBackendUrl;
    private final String publicFrontendUrl;

    public AgendaPhoneVerificationStartupValidator(
            @Value("${agenda.phone.verification.prod-guard-enabled:true}") boolean prodGuardEnabled,
            AgendaSecurityHasher hasher,
            @Value("${spring.profiles.active:}") String activeProfiles,
            @Value("${urls.backend:}") String publicBackendUrl,
            @Value("${urls.frontend:}") String publicFrontendUrl) {
        this.prodGuardEnabled = prodGuardEnabled;
        this.hasher = hasher;
        this.activeProfiles = activeProfiles;
        this.publicBackendUrl = publicBackendUrl;
        this.publicFrontendUrl = publicFrontendUrl;
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
        assertHttpsPublicUrl("urls.backend (PUBLIC_BACKEND_URL)", publicBackendUrl);
        assertHttpsPublicUrl("urls.frontend (PUBLIC_FRONTEND_URL)", publicFrontendUrl);
        log.info("Agenda phone verification prod guard OK (pepper={}, backend={}, frontend={})",
                hasher.pepperForDiagnostics(), maskUrl(publicBackendUrl), maskUrl(publicFrontendUrl));
    }

    private static void assertHttpsPublicUrl(String label, String url) {
        if (url == null || url.isBlank()) {
            throw new IllegalStateException("Configurá " + label + " con https:// en producción.");
        }
        String trimmed = url.trim();
        if (!trimmed.regionMatches(true, 0, "https://", 0, 8)) {
            throw new IllegalStateException(label + " debe usar HTTPS en producción (valor actual: " + trimmed + ").");
        }
    }

    private static String maskUrl(String url) {
        if (url == null || url.isBlank()) {
            return "-";
        }
        return url.trim().replaceAll("(?<=https://)[^/]+", "***");
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
