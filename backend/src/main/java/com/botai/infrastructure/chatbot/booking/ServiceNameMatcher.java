package com.botai.infrastructure.chatbot.booking;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Empareja nombres de servicio del catálogo con texto libre del usuario (ej. "Corte de cabello para mañana"
 * vs catálogo "Corte cabello"), sin depender de que la subcadena sea idéntica palabra a palabra.
 */
public final class ServiceNameMatcher {

    private static final Set<String> STOPWORDS = Set.of(
        "de", "del", "la", "las", "el", "los", "lo", "para", "por", "un", "una", "unos", "unas",
        "y", "con", "en", "a", "al", "mi", "tu", "su", "que", "quiero", "necesito", "agendar", "agenda",
        "cita", "reserva", "turno", "hola", "buenos", "buenas", "dias", "días", "tardes", "noches",
        "favor", "please", "me", "gustaria", "puedo", "pedir", "solicito", "book"
    );

    private ServiceNameMatcher() {}

    /** Sin acentos ni mayúsculas (NFD + quitar marcas combinantes). */
    public static String normalizeKey(String s) {
        if (s == null) return "";
        return Normalizer.normalize(s, Normalizer.Form.NFD)
            .replaceAll("\\p{M}", "")
            .replaceAll("\\s+", " ")
            .strip()
            .toLowerCase();
    }

    /**
     * Tokens alfanuméricos significativos (stopwords y tokens de 1 letra fuera).
     */
    public static Set<String> significantTokens(String s) {
        String n = normalizeKey(s);
        return Arrays.stream(n.split("[^a-z0-9]+"))
            .map(String::strip)
            .filter(t -> t.length() >= 2)
            .filter(t -> !STOPWORDS.contains(t))
            .collect(Collectors.toCollection(HashSet::new));
    }

    /**
     * True si todos los tokens significativos del nombre en catálogo aparecen en el mensaje del usuario
     * (orden irrelevante). Ej.: catálogo "Corte cabello" → tokens {corte,cabello} ⊆ mensaje "Corte de cabello para mañana".
     */
    public static boolean catalogTokensContainedInMessage(String catalogServiceName, String userMessage) {
        Set<String> need = significantTokens(catalogServiceName);
        if (need.isEmpty()) return false;
        Set<String> have = significantTokens(userMessage);
        return have.containsAll(need);
    }

    /**
     * Mejor ítem del catálogo para el texto del usuario: prioriza coincidencia por tokens, luego subcadena,
     * y en empate el nombre de catálogo más largo (más específico).
     */
    public static <T> Optional<T> bestMatch(String userMessage, List<T> services, Function<T, String> nameGetter) {
        if (userMessage == null || userMessage.isBlank() || services == null || services.isEmpty()) {
            return Optional.empty();
        }
        String normMsg = normalizeKey(userMessage);
        return services.stream()
            .filter(s -> {
                String n = nameGetter.apply(s);
                return n != null && !n.isBlank();
            })
            .filter(s -> matches(normMsg, userMessage, nameGetter.apply(s)))
            .max(Comparator.comparingInt(se -> nameGetter.apply(se).length()));
    }

    private static boolean matches(String normMsg, String rawUserMessage, String catalogName) {
        String sn = normalizeKey(catalogName);
        if (sn.isEmpty()) return false;
        if (catalogTokensContainedInMessage(catalogName, rawUserMessage)) {
            return true;
        }
        if (normMsg.contains(sn)) {
            return true;
        }
        if (sn.contains(normMsg) && normMsg.length() >= 4) {
            return true;
        }
        return false;
    }

    /**
     * Resuelve el nombre canónico en catálogo para guardar en BD / validar tools.
     */
    public static <T> Optional<String> canonicalName(String userOrLlmGuess, List<T> services, Function<T, String> nameGetter) {
        return bestMatch(userOrLlmGuess, services, nameGetter).map(nameGetter);
    }
}
