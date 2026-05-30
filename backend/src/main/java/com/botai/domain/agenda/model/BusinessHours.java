package com.botai.domain.agenda.model;

import java.time.LocalTime;
import java.util.UUID;

/** Horario de atención de un negocio para un día de la semana. Inmutable. */
public final class BusinessHours {

    /** 0 = lunes, 6 = domingo (ISO-like, empieza en lunes). */
    private final UUID id;
    private final UUID businessId;
    private final int diaSemana;
    private final LocalTime apertura;
    private final LocalTime cierre;
    /** Second range start (after a break). Null when there is no break. */
    private final LocalTime apertura2;
    /** Second range end (after a break). Null when there is no break. */
    private final LocalTime cierre2;
    private final boolean cerrado;

    public BusinessHours(UUID id, UUID businessId, int diaSemana,
                         LocalTime apertura, LocalTime cierre,
                         LocalTime apertura2, LocalTime cierre2,
                         boolean cerrado) {
        if (diaSemana < 0 || diaSemana > 6) {
            throw new IllegalArgumentException("diaSemana debe estar entre 0 y 6");
        }
        this.id = id;
        this.businessId = businessId;
        this.diaSemana = diaSemana;
        this.apertura = apertura;
        this.cierre = cierre;
        this.apertura2 = apertura2;
        this.cierre2 = cierre2;
        this.cerrado = cerrado;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public int getDiaSemana() { return diaSemana; }
    public LocalTime getApertura() { return apertura; }
    public LocalTime getCierre() { return cierre; }
    public LocalTime getApertura2() { return apertura2; }
    public LocalTime getCierre2() { return cierre2; }
    public boolean isCerrado() { return cerrado; }
}
