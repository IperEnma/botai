package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.BookingEstado;
import com.botai.infrastructure.agenda.persistence.entity.BookingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface BookingJpaRepository extends JpaRepository<BookingEntity, UUID> {

    List<BookingEntity> findAllByUserId(UUID userId);

    List<BookingEntity> findAllByUserIdAndEstado(UUID userId, BookingEstado estado);

    List<BookingEntity> findAllByBusinessIdAndFechaHoraInicioBetween(
            UUID businessId, LocalDateTime desde, LocalDateTime hasta);

    /**
     * Devuelve las reservas activas ({@code PENDING} o {@code CONFIRMED}) cuyo
     * intervalo se intersecta con el slot pedido.
     *
     * <p>Regla de solapamiento clásica: dos intervalos {@code [a,b)} y
     * {@code [c,d)} se pisan ssi {@code a < d} y {@code c < b}. Traducido:
     * {@code inicio_existente < fin_pedido AND fin_existente > inicio_pedido}.</p>
     */
    @Query("""
            select b from BookingEntity b
            where b.businessId = :businessId
              and b.serviceId = :serviceId
              and b.estado in (com.botai.domain.agenda.model.BookingEstado.PENDING,
                               com.botai.domain.agenda.model.BookingEstado.CONFIRMED)
              and b.fechaHoraInicio < :hasta
              and b.fechaHoraFin > :desde
            """)
    List<BookingEntity> findOverlapping(@Param("businessId") UUID businessId,
                                        @Param("serviceId") UUID serviceId,
                                        @Param("desde") LocalDateTime desde,
                                        @Param("hasta") LocalDateTime hasta);

    @Query("""
            select count(b) from BookingEntity b
            where b.userId = :userId
              and b.businessId = :businessId
              and b.estado in (com.botai.domain.agenda.model.BookingEstado.CONFIRMED,
                               com.botai.domain.agenda.model.BookingEstado.COMPLETED)
              and b.fechaHoraInicio >= :desde
            """)
    int countConfirmedInWindow(@Param("userId") UUID userId,
                               @Param("businessId") UUID businessId,
                               @Param("desde") LocalDateTime desde);
}
