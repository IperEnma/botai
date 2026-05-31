package com.botai.infrastructure.agenda.payment;

import com.botai.domain.agenda.service.PaymentPort;
import com.botai.domain.agenda.service.PaymentResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Implementación de juguete de {@link PaymentPort}. No habla con ningún
 * gateway real: sirve para desarrollo, tests e2e y demos.
 *
 * <p>Comportamiento controlable por configuración:
 * <pre>
 * agenda:
 *   payment:
 *     stub:
 *       auto-approve: true     # si false, rechaza todo con "STUB_REJECT"
 *       reject-amount-over: 0  # si &gt; 0, rechaza cobros mayores a ese monto
 * </pre>
 *
 * <p>Esto deja hacer tests del unhappy path sin cambiar el adapter.</p>
 */
@Component
public class StubPaymentAdapter implements PaymentPort {

    private static final Logger log = LoggerFactory.getLogger(StubPaymentAdapter.class);

    private final boolean autoApprove;
    private final BigDecimal rejectAmountOver;

    public StubPaymentAdapter(
            @Value("${payment.stub.auto-approve:true}") boolean autoApprove,
            @Value("${payment.stub.reject-amount-over:0}") BigDecimal rejectAmountOver) {
        this.autoApprove = autoApprove;
        this.rejectAmountOver = rejectAmountOver == null ? BigDecimal.ZERO : rejectAmountOver;
    }

    @Override
    public PaymentResult charge(UUID userId, BigDecimal amount, String currency, String reference) {
        if (!autoApprove) {
            log.info("AGENDA: StubPayment RECHAZA por flag auto-approve=false · ref={}", reference);
            return PaymentResult.rejected("STUB_REJECT");
        }
        if (rejectAmountOver.signum() > 0 && amount.compareTo(rejectAmountOver) > 0) {
            log.info("AGENDA: StubPayment RECHAZA por monto {} > límite {} · ref={}",
                    amount, rejectAmountOver, reference);
            return PaymentResult.rejected("AMOUNT_OVER_LIMIT");
        }
        String txId = "stub-" + UUID.randomUUID();
        log.info("AGENDA: StubPayment APRUEBA userId={} amount={} {} ref={} txId={}",
                userId, amount, currency, reference, txId);
        return PaymentResult.ok(txId);
    }
}
