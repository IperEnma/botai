package com.botai.infrastructure.chatbot.rag;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

class AgendaRagSourceSyncContentTest {

    @Test
    void negocioChunk_incluyeNombreComercialExplicito() {
        String content = AgendaRagSourceSync.buildNegocioKnowledgeContent(
            "Peluquería Zemi",
            "Corte y color",
            "peluqueria-zemi-abc12345",
            "https://app.example.com/#/reservar/peluqueria-zemi-abc12345",
            null,
            null);
        assertTrue(content.contains("Nombre comercial del negocio: Peluquería Zemi"));
        assertTrue(content.contains("El negocio se llama Peluquería Zemi"));
        assertTrue(content.contains("Descripción: Corte y color"));
        assertTrue(content.contains("Enlace oficial para reservar cita nueva"));
        assertTrue(content.contains("https://app.example.com/#/reservar/peluqueria-zemi-abc12345"));
    }
}
