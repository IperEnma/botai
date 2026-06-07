package com.botai.domain.agenda.service;

import java.util.Optional;

/**
 * Puerto de salida para persistir y leer imágenes subidas de Agenda.
 *
 * <p>El dominio no sabe si los bytes viven en Postgres o en disco: eso lo
 * resuelve el adapter activo en Spring ({@code database} por defecto en prod).</p>
 */
public interface AgendaMediaStoragePort {

    /**
     * @param storageKey path relativo sin {@code /uploads/} (ej. {@code businesses/{id}/file.jpg})
     * @return URL pública relativa {@code /uploads/…}
     */
    String store(String storageKey, byte[] data, String contentType);

    /**
     * @param storageKey mismo formato que en {@link #store}
     */
    Optional<AgendaStoredMedia> find(String storageKey);
}
