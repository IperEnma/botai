package com.botai.application.agenda.dto;

import io.swagger.v3.oas.annotations.media.Schema;

import java.util.List;
import java.util.UUID;

/**
 * Sustituye la lista de negocios de Agenda atendidos por un bot del workspace.
 * Un bot puede tener varios negocios; cada negocio solo puede estar en un bot.
 */
@Schema(description = "Lista de IDs de negocios (agenda_businesses) que este bot debe atender. Vacía = desvincular todos.")
public record LinkBotToAgendaBusinessesRequest(
        @Schema(description = "IDs de negocios del mismo tenant; reemplazo completo de la asignación para este bot")
        List<UUID> businessIds
) {
    public LinkBotToAgendaBusinessesRequest {
        businessIds = businessIds == null ? List.of() : List.copyOf(businessIds);
    }
}
