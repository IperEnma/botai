package com.botai.application.agenda.dto;

import java.util.List;

/**
 * Respuesta del endpoint "mi billetera": la suscripción + todo su libro mayor.
 */
public record WalletResponse(SubscriptionResponse subscription,
                             List<CreditTransactionResponse> transactions) {
}
