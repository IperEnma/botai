package com.botai.application.agenda.usecase.loyalty;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.LoyaltySuggestion;
import com.botai.domain.agenda.model.LoyaltySuggestionEstado;
import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.domain.agenda.model.NotificationTemplate;
import com.botai.domain.agenda.notification.NotificationPort;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.LoyaltySuggestionRepository;
import com.botai.domain.agenda.repository.NotificationTemplateRepository;
import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/**
 * Envía una notificación in-app al usuario referenciado por una {@link LoyaltySuggestion}
 * y marca la sugerencia como {@code SENT}.
 *
 * <p>Solo acepta sugerencias en estado {@code PENDING}. Si ya fue enviada o descartada
 * lanza {@link IllegalStateException}.</p>
 *
 * <p>Si el negocio tiene una plantilla configurada para {@code LOYALTY_TRIGGERED + IN_APP},
 * se usa esa. De lo contrario se aplica un mensaje por defecto.</p>
 */
@Service
public class SendLoyaltySuggestionUseCase {

    private static final String DEFAULT_TITULO = "¡Te echamos de menos!";
    private static final String DEFAULT_CUERPO =
            "Has alcanzado un hito de asistencias. Considerá renovar tu plan para seguir disfrutando.";

    private final BusinessRepository businessRepository;
    private final LoyaltySuggestionRepository suggestionRepository;
    private final NotificationTemplateRepository templateRepository;
    private final NotificationPort notificationPort;
    private final MeterRegistry meterRegistry;

    public SendLoyaltySuggestionUseCase(BusinessRepository businessRepository,
                                        LoyaltySuggestionRepository suggestionRepository,
                                        NotificationTemplateRepository templateRepository,
                                        NotificationPort notificationPort,
                                        MeterRegistry meterRegistry) {
        this.businessRepository   = businessRepository;
        this.suggestionRepository = suggestionRepository;
        this.templateRepository   = templateRepository;
        this.notificationPort     = notificationPort;
        this.meterRegistry        = meterRegistry;
    }

    @Transactional
    public LoyaltySuggestion execute(String tenantId, UUID businessId, UUID suggestionId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        LoyaltySuggestion suggestion = suggestionRepository.findById(suggestionId)
                .filter(s -> s.getBusinessId().equals(businessId))
                .orElseThrow(() -> new IllegalArgumentException(
                        "Sugerencia no encontrada: " + suggestionId));

        if (suggestion.getEstado() != LoyaltySuggestionEstado.PENDING) {
            throw new IllegalStateException(
                    "La sugerencia " + suggestionId + " ya fue procesada (estado: " + suggestion.getEstado() + ")");
        }

        String titulo = DEFAULT_TITULO;
        String cuerpo = DEFAULT_CUERPO;

        var template = templateRepository.findByBusinessIdAndCodigoAndCanal(
                businessId, NotificationTemplate.CODIGO_LOYALTY, NotificationCanal.IN_APP);
        if (template.isPresent()) {
            titulo = template.get().getTitulo();
            cuerpo = template.get().getCuerpo();
        }

        notificationPort.send(businessId, suggestion.getUserId(), titulo, cuerpo, NotificationCanal.IN_APP);

        meterRegistry.counter("agenda.loyalty.notifications.sent").increment();
        return suggestionRepository.save(suggestion.withEstado(LoyaltySuggestionEstado.SENT));
    }
}
