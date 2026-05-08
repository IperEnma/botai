package com.botai.application.agenda.usecase.subscription;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.PaymentFailedException;
import com.botai.domain.agenda.exception.PlanDoesNotBelongToBusinessException;
import com.botai.domain.agenda.exception.PlanNotActiveException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.model.CreditMotivo;
import com.botai.domain.agenda.model.CreditTransaction;
import com.botai.domain.agenda.model.Plan;
import com.botai.domain.agenda.model.PlanTipo;
import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.CreditTransactionRepository;
import com.botai.domain.agenda.repository.PlanRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import com.botai.domain.agenda.service.PaymentPort;
import com.botai.domain.agenda.service.PaymentResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Compra una suscripción para un usuario final contra un plan de un negocio.
 *
 * <p>Flujo:
 * <ol>
 *   <li>Validar que el negocio pertenezca al tenant.</li>
 *   <li>Validar que el plan exista, pertenezca al negocio y esté activo.</li>
 *   <li>Cobrar vía {@link PaymentPort}. Si rechaza → {@code PaymentFailedException}.</li>
 *   <li>Crear {@link UserSubscription} con saldo inicial {@code totalCreditos}
 *       del plan (0 si es ilimitado/solo reserva) y vigencia {@code validezDias}.</li>
 *   <li>Grabar {@link CreditTransaction} motivo {@code COMPRA} por el monto inicial.</li>
 * </ol>
 *
 * <p>Todo esto corre en una transacción — si el {@code save} de la transacción
 * falla, la suscripción rollbackea y no queda plata cobrada sin billetera
 * (al menos del lado de la DB; el cobro real ya fue, por eso el adapter de
 * payments debe ser idempotente en la v real).</p>
 */
@Service
public class PurchaseSubscriptionUseCase {

    private static final Logger log = LoggerFactory.getLogger(PurchaseSubscriptionUseCase.class);
    private static final String CURRENCY = "ARS";

    private final PlanRepository planRepository;
    private final BusinessRepository businessRepository;
    private final UserSubscriptionRepository subscriptionRepository;
    private final CreditTransactionRepository transactionRepository;
    private final PaymentPort paymentPort;
    private final Clock clock;

    public PurchaseSubscriptionUseCase(PlanRepository planRepository,
                                       BusinessRepository businessRepository,
                                       UserSubscriptionRepository subscriptionRepository,
                                       CreditTransactionRepository transactionRepository,
                                       PaymentPort paymentPort,
                                       Clock clock) {
        this.planRepository = planRepository;
        this.businessRepository = businessRepository;
        this.subscriptionRepository = subscriptionRepository;
        this.transactionRepository = transactionRepository;
        this.paymentPort = paymentPort;
        this.clock = clock;
    }

    @Transactional
    public UserSubscription execute(String tenantId,
                                    UUID businessId,
                                    UUID userId,
                                    UUID planId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));

        Plan plan = planRepository.findById(planId)
                .orElseThrow(() -> new PlanNotFoundException(planId));
        if (!plan.getBusinessId().equals(businessId)) {
            throw new PlanDoesNotBelongToBusinessException(planId, businessId);
        }
        if (!plan.isActivo()) {
            throw new PlanNotActiveException(planId);
        }

        // Referencia que después seteamos al guardar: arrancamos con un uuid
        // generado acá para poder pasárselo al gateway ANTES de persistir (así
        // el id de la suscripción sirve como clave de idempotencia externa).
        String paymentReference = UUID.randomUUID().toString();
        PaymentResult result = paymentPort.charge(userId, plan.getPrecio(), CURRENCY, paymentReference);
        if (!result.approved()) {
            log.info("AGENDA: compra rechazada · userId={} planId={} reason={}",
                    userId, planId, result.reason());
            throw new PaymentFailedException(result.reason());
        }

        int saldoInicial = saldoInicialFor(plan);
        LocalDateTime now = LocalDateTime.now(clock);
        LocalDateTime expiracion = now.plusDays(plan.getValidezDias());

        UserSubscription newSub = new UserSubscription(
                null, userId, planId, businessId,
                saldoInicial, now, expiracion,
                SubscriptionEstado.ACTIVE,
                null, null
        );
        UserSubscription saved = subscriptionRepository.save(newSub);

        // Solo registramos movimiento si hay créditos: para ILIMITADO_MENSUAL o
        // SOLO_RESERVA la billetera arranca vacía y no hay nada que "cargar".
        if (saldoInicial > 0) {
            CreditTransaction tx = new CreditTransaction(
                    null, saved.getId(), saldoInicial,
                    CreditMotivo.COMPRA, null, null
            );
            transactionRepository.save(tx);
        }

        log.info("AGENDA: suscripción creada id={} userId={} planId={} saldoInicial={} txRef={}",
                saved.getId(), userId, planId, saldoInicial, result.transactionId());
        return saved;
    }

    /**
     * Para tipos con créditos, arrancamos la billetera con {@code totalCreditos}.
     * Para ilimitado / solo reserva, no hay saldo (el acceso se valida por
     * estado {@code ACTIVE} + vigencia en Sprint 3).
     */
    private static int saldoInicialFor(Plan plan) {
        PlanTipo tipo = plan.getTipo();
        return switch (tipo) {
            case POR_CREDITOS, MIXTO -> plan.getTotalCreditos();
            case ILIMITADO_MENSUAL, SOLO_RESERVA -> 0;
        };
    }
}
