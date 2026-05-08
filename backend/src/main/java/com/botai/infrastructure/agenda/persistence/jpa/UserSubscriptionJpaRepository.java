package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.infrastructure.agenda.persistence.entity.UserSubscriptionEntity;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserSubscriptionJpaRepository extends JpaRepository<UserSubscriptionEntity, UUID> {

    List<UserSubscriptionEntity> findAllByUserId(UUID userId);

    List<UserSubscriptionEntity> findAllByUserIdAndEstado(UUID userId, SubscriptionEstado estado);

    List<UserSubscriptionEntity> findAllByBusinessIdAndEstado(UUID businessId, SubscriptionEstado estado);

    /**
     * {@code SELECT ... FOR UPDATE} sobre la fila de la suscripción. Lo usa
     * {@code CreateBookingUseCase} para impedir el doble descuento cuando
     * dos requests concurrentes quieren usar el último crédito.
     *
     * <p>El lock se libera al terminar la transacción del use case. Fuera de
     * una transacción Spring devuelve una {@code TransactionRequiredException}
     * — es intencional para forzar que el caller la invoque con
     * {@code @Transactional}.</p>
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select s from UserSubscriptionEntity s where s.id = :id")
    Optional<UserSubscriptionEntity> findByIdForUpdate(@Param("id") UUID id);

    @Query("""
            select s from UserSubscriptionEntity s
            where s.estado = com.botai.domain.agenda.model.SubscriptionEstado.ACTIVE
              and s.fechaExpiracion >= :desde
              and s.fechaExpiracion <= :hasta
            """)
    List<UserSubscriptionEntity> findAllActiveExpiringSoon(
            @Param("desde") LocalDateTime desde,
            @Param("hasta") LocalDateTime hasta);

    @Query("""
            select s from UserSubscriptionEntity s
            where s.estado = com.botai.domain.agenda.model.SubscriptionEstado.ACTIVE
              and s.saldoActual <= :maxSaldo
            """)
    List<UserSubscriptionEntity> findAllActiveWithLowBalance(@Param("maxSaldo") int maxSaldo);
}
