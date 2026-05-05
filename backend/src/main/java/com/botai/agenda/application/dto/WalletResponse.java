package com.botai.agenda.application.dto;

import java.util.List;

/**
 * Respuesta del endpoint "mi billetera": la suscripción + todo su libro mayor.
 */
public record WalletResponse(SubscriptionResponse subscription,
                             List<CreditTransactionResponse> transactions) {
}
