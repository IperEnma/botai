package com.botai.application.chatbot.service.knowledge;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Prefijos de {@code knowledge_chunk.topic} para acotar retrieval (Fase 1).
 * Alineado con topics de {@code AgendaRagSourceSync}.
 */
public final class RagTopicHintService {

    public static final String TOPIC_NEGOCIO = "Agenda: Información del negocio";
    public static final String TOPIC_SERVICIOS = "Agenda: Servicios";
    public static final String TOPIC_HORARIOS = "Agenda: Horarios";
    public static final String TOPIC_POLITICAS = "Agenda: Políticas";

    private RagTopicHintService() {}

    /**
     * @return prefijos de topic (sin duplicados); vacío = sin filtro adicional.
     */
    public static List<String> topicPrefixesForQuery(String query) {
        String n = normalize(query);
        if (n.isBlank()) {
            return List.of();
        }
        Set<String> prefixes = new LinkedHashSet<>();
        if (matchesHours(n)) {
            prefixes.add(TOPIC_HORARIOS);
        }
        if (matchesServices(n)) {
            prefixes.add(TOPIC_SERVICIOS);
        }
        if (matchesBusinessInfo(n)) {
            prefixes.add(TOPIC_NEGOCIO);
        }
        if (matchesPolicies(n)) {
            prefixes.add(TOPIC_POLITICAS);
        }
        return new ArrayList<>(prefixes);
    }

    private static boolean matchesHours(String n) {
        return containsAny(n,
                "horario", "horarios", "abren", "cierran", "apertura", "cierre", "atienden",
                "abre", "cierra", "sabado", "domingo", "lunes", "martes", "miercoles", "jueves", "viernes",
                "feriado", "festivo", "hoy abren", "hasta que hora", "a que hora");
    }

    private static boolean matchesServices(String n) {
        return containsAny(n,
                "servicio", "servicios", "precio", "precios", "corte", "cortes", "tratamiento",
                "duracion", "catalogo", "ofrecen", "hacen", "cuanto cuesta", "valor", "tarifa");
    }

    private static boolean matchesBusinessInfo(String n) {
        return containsAny(n,
                "nombre", "llaman", "negocio", "direccion", "ubicacion", "donde estan", "donde quedan",
                "como se llaman", "quienes son", "descripcion", "telefono del local", "email del negocio");
    }

    private static boolean matchesPolicies(String n) {
        return containsAny(n,
                "politica", "politicas", "cancelacion", "cancelar cita", "reprogramar", "senia", "deposito",
                "no show", "inasistencia", "devolucion");
    }

    private static boolean containsAny(String haystack, String... needles) {
        for (String needle : needles) {
            if (haystack.contains(needle)) {
                return true;
            }
        }
        return false;
    }

    static String normalize(String text) {
        if (text == null) {
            return "";
        }
        return Normalizer.normalize(text, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .trim();
    }
}
