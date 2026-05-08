package com.botai.application.agenda.dto;

public record PublicAgendaLinkResponse(
        String slug,
        String url,
        String businessId
) {
}

