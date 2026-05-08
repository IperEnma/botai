package com.botai.agenda.application.dto;

public record PublicAgendaLinkResponse(
        String slug,
        String url,
        String businessId
) {
}

