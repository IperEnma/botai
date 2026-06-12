package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.exception.BookingSlotTakenException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.infrastructure.agenda.persistence.entity.BookingEntity;
import com.botai.infrastructure.agenda.persistence.mapper.BookingMapper;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;


@Repository
public class JpaBookingRepository implements BookingRepository {

    private static final String SLOT_CONSTRAINT = "excl_agenda_bookings_staff_slot";

    private final BookingJpaRepository jpa;

    public JpaBookingRepository(BookingJpaRepository jpa) {
        this.jpa = jpa;
    }

    /**
     * Persiste el booking y fuerza el flush inmediato para que el constraint
     * {@code excl_agenda_bookings_slot} se evalúe dentro de la transacción
     * actual. Si hay solapamiento con otra reserva activa, PostgreSQL lanza
     * una violación que se convierte en {@link BookingSlotTakenException}.
     *
     * <p>Usar {@code saveAndFlush} en lugar de {@code save} es intencional:
     * si se usara {@code save}, el INSERT se diferiría al commit y la
     * {@code DataIntegrityViolationException} llegaría envuelta en
     * {@code TransactionSystemException}, fuera del ámbito donde podemos
     * convertirla limpiamente.</p>
     */
    @Override
    public Booking save(Booking booking) {
        BookingEntity entity = BookingMapper.toEntity(booking);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        try {
            BookingEntity saved = jpa.saveAndFlush(entity);
            return BookingMapper.toDomain(saved);
        } catch (DataIntegrityViolationException ex) {
            if (isSlotExclusionViolation(ex)) {
                throw new BookingSlotTakenException();
            }
            throw ex;
        } catch (RuntimeException ex) {
            // Defensive: handle cases where the JPA exception was not translated
            // to DataIntegrityViolationException (e.g. raw ConstraintViolationException
            // from Hibernate propagating before the PersistenceExceptionTranslationInterceptor).
            if (isSlotExclusionViolation(ex)) {
                throw new BookingSlotTakenException();
            }
            throw ex;
        }
    }

    @Override
    public Optional<Booking> findById(UUID id) {
        return jpa.findById(id).map(BookingMapper::toDomain);
    }

    @Override
    public List<Booking> findOverlapping(UUID businessId,
                                         UUID serviceId,
                                         LocalDateTime desde,
                                         LocalDateTime hasta) {
        return jpa.findOverlapping(businessId, serviceId, desde, hasta).stream()
                .map(BookingMapper::toDomain)
                .toList();
    }

    @Override
    public List<Booking> findOverlappingForStaff(UUID staffMemberId,
                                                  LocalDateTime desde,
                                                  LocalDateTime hasta) {
        return jpa.findOverlappingForStaff(staffMemberId, desde, hasta).stream()
                .map(BookingMapper::toDomain)
                .toList();
    }

    @Override
    public List<Booking> findAllByUserId(UUID userId) {
        return jpa.findAllByUserId(userId).stream()
                .map(BookingMapper::toDomain)
                .toList();
    }

    @Override
    public List<Booking> findAllByUserIdAndEstado(UUID userId, BookingEstado estado) {
        return jpa.findAllByUserIdAndEstado(userId, estado).stream()
                .map(BookingMapper::toDomain)
                .toList();
    }

    @Override
    public List<Booking> findAllByBusinessIdAndFecha(UUID businessId,
                                                     LocalDateTime desde,
                                                     LocalDateTime hasta) {
        return jpa.findAllByBusinessIdAndFechaHoraInicioBetween(businessId, desde, hasta).stream()
                .map(BookingMapper::toDomain)
                .toList();
    }

    @Override
    public List<Booking> findAllByBusinessIdAndStaffMemberIdAndFecha(UUID businessId,
                                                                    UUID staffMemberId,
                                                                    LocalDateTime desde,
                                                                    LocalDateTime hasta) {
        return jpa.findAllByBusinessIdAndStaffMemberIdAndFechaHoraInicioBetween(
                        businessId, staffMemberId, desde, hasta).stream()
                .map(BookingMapper::toDomain)
                .toList();
    }

    @Override
    public int countConfirmedInWindow(UUID userId, UUID businessId, LocalDateTime desde) {
        return jpa.countConfirmedInWindow(userId, businessId, desde);
    }

    private boolean isSlotExclusionViolation(Throwable ex) {
        Throwable cause = ex;
        while (cause != null) {
            if (cause.getMessage() != null && cause.getMessage().contains(SLOT_CONSTRAINT)) {
                return true;
            }
            cause = cause.getCause();
        }
        return false;
    }
}
