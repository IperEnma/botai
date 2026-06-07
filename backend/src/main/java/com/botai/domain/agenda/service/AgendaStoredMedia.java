package com.botai.domain.agenda.service;

/**
 * Contenido binario de un archivo subido (logo, banner, avatar).
 */
public record AgendaStoredMedia(String contentType, byte[] data) {}
