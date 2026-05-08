package com.botai.application.agenda.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/**
 * Payload para comprar una suscripción. El {@code userId} <b>no</b> viene acá:
 * se toma del header {@code X-User-Id}.
 */
public record PurchaseSubscriptionRequest(@NotNull UUID planId) {
}
