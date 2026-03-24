package com.botai.chatbot.application.dto;

/**
 * Valores de {@link ConversationRouteResult#intentSource()} para métricas, historial y reglas del core.
 * Evita strings mágicos repartidos por el código.
 */
public final class ConversationIntentSource {

    public static final String AI = "ai";
    public static final String ACTION = "action";
    public static final String ACTIONS_DISABLED = "actions_disabled";
    public static final String FAQ = "faq";
    public static final String MENU = "menu";
    public static final String ERROR = "error";
    public static final String BOT_NOT_READY = "bot_not_ready";
    public static final String CLASSIFIER_ERROR = "classifier_error";
    public static final String BAD_INTENT = "bad_intent";
    public static final String NO_MATCH = "no_match";

    private ConversationIntentSource() {}

    /** La capa IA ya persiste user/assistant vía Spring AI {@code ChatMemory} (misma tabla que el historial). */
    public static boolean historyManagedByAiLayer(String source) {
        return AI.equals(source);
    }

    /** CRM / acciones ya guardaron estado; {@link com.botai.chatbot.application.service.inbound.ConversationCore} no debe pisarlo. */
    public static boolean skipSavingStaleStateAfterRoute(String source) {
        return ACTION.equals(source) || ACTIONS_DISABLED.equals(source);
    }
}
