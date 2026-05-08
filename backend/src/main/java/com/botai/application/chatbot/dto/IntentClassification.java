package com.botai.application.chatbot.dto;

import java.util.Optional;

/**
 * Resultado del clasificador unificado: saludo, acción CRM, pregunta general o mala intención.
 * Sirve para orquestar menú (saludo), acciones (agendar, ver citas) y filtrar abuso.
 */
public sealed interface IntentClassification {

    /** Saludo (ej. "Hola") → el router puede mostrar el menú */
    record Greeting() implements IntentClassification {}

    /** Acción CRM (agendar, ver citas, etc.) → actionId para el dispatcher */
    record CrmAction(String actionId) implements IntentClassification {}

    /** Pregunta general → sigue flujo normal (FAQ / IA) */
    record GeneralQuestion() implements IntentClassification {}

    /** Mala intención (insultos, abuso) → bloquear con mensaje fijo */
    record BadIntent() implements IntentClassification {}

    /** Error del clasificador (ej. LLM no disponible) → mensaje único al cliente, sin fallback */
    record ServiceError() implements IntentClassification {}

    default boolean isGreeting() { return this instanceof Greeting; }
    default boolean isCrmAction() { return this instanceof CrmAction; }
    default boolean isGeneralQuestion() { return this instanceof GeneralQuestion; }
    default boolean isBadIntent() { return this instanceof BadIntent; }
    default boolean isServiceError() { return this instanceof ServiceError; }

    default Optional<String> getActionId() {
        return this instanceof CrmAction c ? Optional.of(c.actionId()) : Optional.empty();
    }
}
