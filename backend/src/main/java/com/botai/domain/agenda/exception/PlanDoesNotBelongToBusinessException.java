package com.botai.domain.agenda.exception;

import java.util.UUID;

/**
 * Se lanza cuando un caso de uso recibe un plan cuya {@code businessId} no
 * coincide con el {@code businessId} del path ({@code /tenants/.../businesses/{businessId}/plans/{planId}}).
 *
 * <p>Semántica HTTP: se mapea a {@code 404 NOT_FOUND} en el
 * {@code AgendaGlobalExceptionHandler} para no revelar existencia de planes
 * entre negocios. Desde la perspectiva del cliente es "plan no visible bajo
 * este negocio".</p>
 */
public class PlanDoesNotBelongToBusinessException extends AgendaDomainException {
    public PlanDoesNotBelongToBusinessException(UUID planId, UUID businessId) {
        super("El plan " + planId + " no pertenece al negocio " + businessId);
    }
}
