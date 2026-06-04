package com.botai.domain.agenda.service;

/**
 * Envía el código OTP al teléfono del cliente (p. ej. WhatsApp Cloud API del tenant).
 */
public interface PhoneVerificationDeliveryPort {

    /**
     * @return {@code true} si el canal pudo entregar el mensaje
     */
    boolean sendVerificationCode(String tenantId, String phoneNormalized, String code);
}
