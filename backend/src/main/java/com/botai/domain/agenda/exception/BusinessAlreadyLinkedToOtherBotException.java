package com.botai.domain.agenda.exception;

import java.util.UUID;

/**
 * Un negocio ya tiene {@code bot_id} apuntando a otro bot; la regla es un negocio → un solo bot.
 */
public class BusinessAlreadyLinkedToOtherBotException extends AgendaDomainException {
    public BusinessAlreadyLinkedToOtherBotException(UUID businessId, long otherBotId) {
        super("El negocio " + businessId + " ya está vinculado al bot " + otherBotId
                + ". Desvincúlalo primero o use el mismo bot.");
    }
}
