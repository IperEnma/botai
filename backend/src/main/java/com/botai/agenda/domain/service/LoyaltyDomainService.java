package com.botai.agenda.domain.service;

import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.model.LoyaltySuggestion;
import com.botai.agenda.domain.model.LoyaltySuggestionEstado;

import java.util.UUID;

/**
 * Reglas de negocio del motor de fidelización.
 *
 * <p>Evalúa si un usuario ha alcanzado el umbral de asistencias configurado
 * en el negocio y, si es así, construye una {@link LoyaltySuggestion} lista
 * para persistir. No persiste nada — el caller ({@code BookingConfirmedEventListener})
 * decide si guardarla.</p>
 */
public class LoyaltyDomainService {

    public static final String TRIGGER_THRESHOLD = "LOYALTY_THRESHOLD_REACHED";

    /**
     * Devuelve {@code true} cuando el conteo de asistencias supera el umbral
     * configurado, indicando que se debe generar una sugerencia.
     *
     * @param asistencias número de reservas CONFIRMED/COMPLETED en la ventana
     * @param settings    configuración del negocio (threshold + ventana)
     */
    public boolean debeGenerarSugerencia(int asistencias, BusinessSettings settings) {
        return asistencias >= settings.getLoyaltyMinAttendances();
    }

    /**
     * Construye una {@link LoyaltySuggestion} en estado {@code PENDING}.
     * Llamar solo cuando {@link #debeGenerarSugerencia} devuelve {@code true}
     * y no existe ya una sugerencia PENDING para el mismo par (business, user).
     */
    public LoyaltySuggestion crearSugerencia(UUID businessId, UUID userId) {
        return new LoyaltySuggestion(
                null, businessId, userId,
                TRIGGER_THRESHOLD,
                LoyaltySuggestionEstado.PENDING,
                null, null
        );
    }
}
