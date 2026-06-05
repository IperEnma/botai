package com.botai.application.agenda.support;

import com.botai.domain.agenda.event.BookingConfirmedEvent;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.OutboxEvent;
import com.botai.domain.agenda.repository.OutboxEventRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * Encola {@link BookingConfirmedEvent} vía outbox (mismo patrón que suscripción).
 */
@Component
public class BookingConfirmedOutboxService {

    private static final Logger log = LoggerFactory.getLogger(BookingConfirmedOutboxService.class);

    private final OutboxEventRepository outboxEventRepository;
    private final ObjectMapper objectMapper;

    public BookingConfirmedOutboxService(OutboxEventRepository outboxEventRepository,
                                         ObjectMapper objectMapper) {
        this.outboxEventRepository = outboxEventRepository;
        this.objectMapper = objectMapper;
    }

    public void enqueue(Booking booking) {
        try {
            String payload = objectMapper.writeValueAsString(new BookingConfirmedEvent(
                    booking.getId(),
                    booking.getBusinessId(),
                    booking.getUserId(),
                    booking.getSubscriptionId(),
                    booking.getFechaHoraInicio()));
            outboxEventRepository.save(new OutboxEvent(
                    null,
                    BookingConfirmedEvent.class.getSimpleName(),
                    payload,
                    OutboxEvent.STATUS_PENDING,
                    null,
                    null));
        } catch (Exception ex) {
            log.error("AGENDA: error serializando outbox event para booking={}", booking.getId(), ex);
        }
    }
}
