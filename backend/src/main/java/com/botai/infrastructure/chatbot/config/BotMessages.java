package com.botai.infrastructure.chatbot.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Mensajes del bot configurables vía bot.messages.* (application.yml o .env).
 * Evita textos hardcodeados y permite personalizar por entorno.
 */
@Component
@ConfigurationProperties(prefix = "bot.messages")
public class BotMessages {

    /** Mala intención detectada (clasificador). */
    private String badIntent = "No puedo responder a eso. ¿En qué puedo ayudarte con el negocio?";
    /** Guardrail bloqueó (jailbreak/regex) o salida con código. */
    private String guardrailBlock = "Solo puedo ayudarte con temas del negocio. ¿En qué más puedo ayudarte?";
    /** Sin match en menú/FAQ/acción ni IA. */
    private String noMatch = "No tengo una respuesta para eso. Revisa servicios, horario y conocimiento en el panel (y menú si usas FAQ).";
    /** No se pudo identificar el negocio (tenant ausente). */
    private String tenantUnknown = "No se pudo identificar el negocio. Revisa la configuración del bot.";
    /** RAG devolvió 0 chunks; no se llama al LLM. */
    private String noRagInfo = "No tenemos esa información disponible. ¿En qué más podemos ayudarte?";
    /** Error al llamar al modelo (detalle técnico solo en logs). */
    private String aiError = "En este momento estamos fuera de servicio. Por favor, intenta de nuevo más tarde.";
    /** Hint bajo el menú cuando la IA está activa. */
    private String aiHint = "💬 También puedes escribir tu pregunta y te responderé.";
    /** Saludo cuando solo está activa la IA (sin menú/FAQ); ej. usuario dice "Hola". */
    private String greeting = "Hola, ¿en qué podemos ayudarte?";
    /** Usuario pidió agendar/ver citas pero acciones están desactivadas para el tenant. */
    private String actionsDisabled = "Por el momento no manejamos reservas o citas por aquí. ¿Quieres saber horarios o servicios?";

    /** Pregunta al cliente al cerrar la conversación. */
    private String feedbackQuestion = "¿Te resultó útil esta conversación? Respondé Sí o No.";
    private String feedbackThanksPositive = "¡Gracias! Nos alegra haberte ayudado.";
    private String feedbackThanksNegative = "Gracias por contarnos. Trabajaremos para mejorar.";
    private String feedbackThanksUnclear = "Respondé Sí o No para saber si te fue útil.";

    public String getBadIntent() { return badIntent; }
    public void setBadIntent(String badIntent) { this.badIntent = badIntent; }
    public String getGuardrailBlock() { return guardrailBlock; }
    public void setGuardrailBlock(String guardrailBlock) { this.guardrailBlock = guardrailBlock; }
    public String getNoMatch() { return noMatch; }
    public void setNoMatch(String noMatch) { this.noMatch = noMatch; }
    public String getTenantUnknown() { return tenantUnknown; }
    public void setTenantUnknown(String tenantUnknown) { this.tenantUnknown = tenantUnknown; }
    public String getNoRagInfo() { return noRagInfo; }
    public void setNoRagInfo(String noRagInfo) { this.noRagInfo = noRagInfo; }
    public String getAiError() { return aiError; }
    public void setAiError(String aiError) { this.aiError = aiError; }
    public String getAiHint() { return aiHint; }
    public void setAiHint(String aiHint) { this.aiHint = aiHint; }
    public String getGreeting() { return greeting; }
    public void setGreeting(String greeting) { this.greeting = greeting; }
    public String getActionsDisabled() { return actionsDisabled; }
    public void setActionsDisabled(String actionsDisabled) { this.actionsDisabled = actionsDisabled; }
    public String getFeedbackQuestion() { return feedbackQuestion; }
    public void setFeedbackQuestion(String feedbackQuestion) { this.feedbackQuestion = feedbackQuestion; }
    public String getFeedbackThanksPositive() { return feedbackThanksPositive; }
    public void setFeedbackThanksPositive(String feedbackThanksPositive) { this.feedbackThanksPositive = feedbackThanksPositive; }
    public String getFeedbackThanksNegative() { return feedbackThanksNegative; }
    public void setFeedbackThanksNegative(String feedbackThanksNegative) { this.feedbackThanksNegative = feedbackThanksNegative; }
    public String getFeedbackThanksUnclear() { return feedbackThanksUnclear; }
    public void setFeedbackThanksUnclear(String feedbackThanksUnclear) { this.feedbackThanksUnclear = feedbackThanksUnclear; }
}
