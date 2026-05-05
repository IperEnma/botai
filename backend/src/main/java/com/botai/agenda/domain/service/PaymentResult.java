package com.botai.agenda.domain.service;

/**
 * Resultado de un intento de cobro vía {@link PaymentPort}.
 *
 * <p>{@code transactionId} es la referencia externa que devuelve el gateway
 * (null si falló). {@code reason} es un mensaje legible para loguear o
 * devolver al cliente.</p>
 */
public record PaymentResult(boolean approved, String transactionId, String reason) {

    public static PaymentResult ok(String transactionId) {
        return new PaymentResult(true, transactionId, "APPROVED");
    }

    public static PaymentResult rejected(String reason) {
        return new PaymentResult(false, null, reason);
    }
}
