package com.botai.application.agenda.support;

import java.text.Normalizer;
import java.util.Locale;
import java.util.UUID;

/**
 * Slug estable para URL pública {@code /#/agenda/&lt;slug&gt;}. Mismo criterio que
 * {@link com.botai.application.agenda.usecase.business.GetOrCreatePublicAgendaLinkUseCase} para filas nuevas o sin slug.
 */
public final class AgendaPublicSlug {

    private AgendaPublicSlug() {}

    /**
     * {@code slugify(nombre) + "-" + primeros 8 hex del id} (único por negocio gracias al UUID).
     */
    public static String forNewBusiness(UUID businessId, String nombreNegocio) {
        return slugify(nombreNegocio) + "-" + businessId.toString().substring(0, 8);
    }

    public static String slugify(String raw) {
        if (raw == null || raw.isBlank()) {
            return "agenda";
        }
        String normalized = Normalizer.normalize(raw, Normalizer.Form.NFD)
            .replaceAll("\\p{InCombiningDiacriticalMarks}+", "");
        String ascii = normalized.toLowerCase(Locale.ROOT);
        ascii = ascii.replaceAll("[^a-z0-9]+", "-");
        ascii = ascii.replaceAll("(^-+)|(-+$)", "");
        if (ascii.isBlank()) {
            return "agenda";
        }
        return ascii.length() > 80 ? ascii.substring(0, 80) : ascii;
    }
}
