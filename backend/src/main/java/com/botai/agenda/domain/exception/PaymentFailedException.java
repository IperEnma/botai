package com.botai.agenda.domain.exception;

/**
 * El {@code PaymentPort} devolvió {@code approved=false}. Se mapea a
 * {@code 402 Payment Required} para distinguirlo de un request inválido.
 */
public class PaymentFailedException extends AgendaDomainException {

    private final String reason;

    public PaymentFailedException(String reason) {
        super("El pago fue rechazado: " + (reason == null ? "unknown" : reason));
        this.reason = reason;
    }

    public String getReason() {
        return reason;
    }
}
