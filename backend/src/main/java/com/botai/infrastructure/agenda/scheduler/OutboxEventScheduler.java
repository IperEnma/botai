package com.botai.infrastructure.agenda.scheduler;

import com.botai.domain.agenda.event.BookingConfirmedEvent;
import com.botai.domain.agenda.model.OutboxEvent;
import com.botai.domain.agenda.repository.OutboxEventRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Publica eventos pendientes del outbox y los marca como PROCESSED.
 *
 * <p>Corre cada 10 segundos. Al publicar cada evento invoca
 * {@link ApplicationEventPublisher}, que dispara los mismos
 * {@code @TransactionalEventListener} que el flujo rápido usaría.</p>
 *
 * <p>Los listeners son idempotentes: si el evento ya fue procesado en el
 * camino rápido (e.g., el listener de loyalty ya creó la sugerencia),
 * el segundo disparo simplemente no hace nada.</p>
 */
@Component
@ConditionalOnProperty(name = "agenda.outbox.scheduler.enabled", havingValue = "true", matchIfMissing = true)
public class OutboxEventScheduler {

    private static final Logger log = LoggerFactory.getLogger(OutboxEventScheduler.class);

    private final OutboxEventRepository outboxRepository;
    private final ApplicationEventPublisher eventPublisher;
    private final ObjectMapper objectMapper;

    public OutboxEventScheduler(OutboxEventRepository outboxRepository,
                                ApplicationEventPublisher eventPublisher,
                                ObjectMapper objectMapper) {
        this.outboxRepository = outboxRepository;
        this.eventPublisher   = eventPublisher;
        this.objectMapper     = objectMapper;
    }

    @Scheduled(fixedDelay = 10_000)
    @Transactional
    public void processOutbox() {
        List<OutboxEvent> pending = outboxRepository.findPending();
        if (pending.isEmpty()) return;

        log.debug("AGENDA outbox: {} evento(s) pendiente(s)", pending.size());

        for (OutboxEvent event : pending) {
            try {
                publish(event);
                outboxRepository.save(event.markProcessed(LocalDateTime.now()));
            } catch (Exception ex) {
                log.error("AGENDA outbox: error publicando evento id={} tipo={}",
                        event.getId(), event.getEventType(), ex);
            }
        }
    }

    private void publish(OutboxEvent event) throws Exception {
        if (BookingConfirmedEvent.class.getSimpleName().equals(event.getEventType())) {
            BookingConfirmedEvent domainEvent =
                    objectMapper.readValue(event.getPayload(), BookingConfirmedEvent.class);
            eventPublisher.publishEvent(domainEvent);
        } else {
            log.warn("AGENDA outbox: tipo de evento desconocido '{}'", event.getEventType());
        }
    }
}
