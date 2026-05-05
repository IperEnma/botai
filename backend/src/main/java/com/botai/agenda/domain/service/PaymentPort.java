package com.botai.agenda.domain.service;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Puerto de salida (outbound) hacia un procesador de pagos.
 *
 * <p>El dominio <b>no sabe</b> cómo se paga: delega en esta interfaz. Hoy hay
 * un {@code StubPaymentAdapter} que siempre aprueba; el día que se integre
 * Mercado Pago / Stripe / etc. se escribe un nuevo adapter y se cambia la
 * config Spring, sin tocar el dominio ni los use cases.</p>
 *
 * <p>Responsabilidades del adapter:
 * <ul>
 *   <li>Hablar con el gateway externo.</li>
 *   <li>Devolver un {@link PaymentResult} con la referencia del cobro o una
 *       razón de rechazo humana.</li>
 *   <li><b>No</b> persistir nada en las tablas de AGENDA — eso lo hace el
 *       use case una vez que este puerto devolvió OK.</li>
 * </ul>
 */
public interface PaymentPort {

    /**
     * Intenta cobrar {@code amount} al {@code userId}. El adapter decide si eso
     * significa tarjeta guardada, redirigir a un checkout, o (en el stub) nada.
     *
     * @param userId     identidad del pagador en AGENDA.
     * @param amount     monto a cobrar (ya en la moneda del negocio).
     * @param currency   p. ej. {@code "ARS"}.
     * @param reference  referencia interna (suele ser el id de suscripción que
     *                   se va a crear, o un uuid generado por el use case).
     */
    PaymentResult charge(UUID userId, BigDecimal amount, String currency, String reference);
}
