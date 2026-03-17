package com.botai.chatbot.application.service;

import com.botai.chatbot.application.dto.IntentClassification;
import com.botai.chatbot.domain.context.TenantContext;
import com.botai.chatbot.domain.model.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.Message;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * IA con RAG siempre activo: en cada request se hace búsqueda semántica (embeddings),
 * se inyecta horario, servicios y fragmentos relevantes en el system prompt y se llama al LLM.
 * Sin tools: la única fuente de conocimiento es el contexto inyectado.
 */
public class HybridAiService {

    private static final Logger log = LoggerFactory.getLogger(HybridAiService.class);

    private final ChatModel chatModel;
    private final ChatClient chatClientWithTools;
    private final AiContextBuilder aiContextBuilder;
    private final ResponseValidator responseValidator;
    private final MessageHistoryService messageHistoryService;
    private final String messageTenantUnknown;
    private final String messageNoRagInfo;
    private final String messageAiError;

    public HybridAiService(ChatModel chatModel,
                           AiContextBuilder aiContextBuilder,
                           ResponseValidator responseValidator,
                           MessageHistoryService messageHistoryService,
                           String messageTenantUnknown,
                           String messageNoRagInfo,
                           String messageAiError) {
        this(chatModel, null, aiContextBuilder, responseValidator, messageHistoryService, messageTenantUnknown, messageNoRagInfo, messageAiError);
    }

    public HybridAiService(ChatModel chatModel,
                           ChatClient chatClientWithTools,
                           AiContextBuilder aiContextBuilder,
                           ResponseValidator responseValidator,
                           MessageHistoryService messageHistoryService,
                           String messageTenantUnknown,
                           String messageNoRagInfo,
                           String messageAiError) {
        this.chatModel = chatModel;
        this.chatClientWithTools = chatClientWithTools;
        this.aiContextBuilder = aiContextBuilder;
        this.responseValidator = responseValidator;
        this.messageHistoryService = messageHistoryService;
        this.messageTenantUnknown = messageTenantUnknown != null && !messageTenantUnknown.isBlank() ? messageTenantUnknown : "No se pudo identificar el negocio. Revisa la configuración del bot.";
        this.messageNoRagInfo = messageNoRagInfo != null && !messageNoRagInfo.isBlank() ? messageNoRagInfo : "No tenemos esa información disponible. ¿En qué más podemos ayudarte?";
        this.messageAiError = messageAiError != null && !messageAiError.isBlank() ? messageAiError : "No pude conectar con el asistente. Verifica que Ollama esté en marcha.";
    }

    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state) {
        return generateResponse(inbound, state, null);
    }

    /**
     * Llamado final del flujo de 3 pasos (guardrail → clasificador → este).
     * La clasificación se inyecta en el system prompt para que el modelo sepa la intención y decida si usar tools o solo RAG.
     */
    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification) {
        String conversationId = inbound.getConversationId();
        String userText = inbound.getText();
        Object t = inbound.getMetadata() != null ? inbound.getMetadata().get("tenantId") : null;
        String tenantId = t != null ? t.toString().strip() : null;
        if (tenantId != null && tenantId.isEmpty()) tenantId = null;

        messageHistoryService.saveUserMessage(conversationId, userText);

        if (tenantId == null) {
            messageHistoryService.saveAssistantMessage(conversationId, messageTenantUnknown);
            return OutboundMessage.builder().text(messageTenantUnknown).conversationId(conversationId).tenantId(null).build();
        }

        String requiredBookingQuestion = getRequiredBookingQuestion(conversationId, userText, classification, tenantId);
        if (requiredBookingQuestion != null) {
            log.info("[AI] Flujo agendar: respondiendo con pregunta obligatoria (nombre/documento) sin LLM");
            messageHistoryService.saveAssistantMessage(conversationId, requiredBookingQuestion);
            return OutboundMessage.builder()
                .text(requiredBookingQuestion)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build();
        }

        return generateResponseWithRag(conversationId, userText, tenantId, state, classification);
    }

    private static final Pattern TIME_PATTERN = Pattern.compile("^\\s*(\\d{1,2})(?::(\\d{2}))?\\s*$");

    /**
     * Si estamos en flujo de agendar y falta pedir nombre o documento, devuelve la pregunta exacta
     * para no depender del modelo. Así el bot siempre pide nombre y documento.
     * Se usa el historial (último mensaje del asistente) para saber en qué paso estamos.
     */
    private String getRequiredBookingQuestion(String conversationId, String userText, IntentClassification classification, String tenantId) {
        List<String> history = messageHistoryService.getHistory(conversationId);
        String lastAssistant = null;
        for (int i = history.size() - 1; i >= 0; i--) {
            String line = history.get(i);
            if (line.startsWith("assistant:")) {
                lastAssistant = line.substring(9).trim().toLowerCase();
                break;
            }
        }
        if (lastAssistant == null || lastAssistant.isEmpty()) {
            return null;
        }
        String userTrim = userText != null ? userText.trim() : "";
        if (userTrim.isEmpty()) return null;

        boolean lastAskedForDocument = lastAssistant.contains("cédula") || lastAssistant.contains("cedula") || lastAssistant.contains("documento");
        if (lastAskedForDocument) {
            return null;
        }
        boolean lastAskedForName = lastAssistant.contains("nombre completo") || lastAssistant.contains("nombre del cliente");
        if (lastAskedForName) {
            return "¿Cuál es tu número de cédula o documento?";
        }
        boolean lastOfferedHours = lastAssistant.contains("horas disponibles") || lastAssistant.contains("hora de llegada") || lastAssistant.contains("elige una") || lastAssistant.contains("siguientes horas");
        boolean userSaidTime = TIME_PATTERN.matcher(userTrim).matches() || userTrim.matches("\\d{1,2}\\s*:\\s*\\d{2}");
        if (lastOfferedHours && userSaidTime) {
            return "¿Cuál es tu nombre completo?";
        }
        return null;
    }

    /**
     * Cuando el último mensaje del bot pidió documento y el usuario acaba de responder,
     * inyectamos instrucción para que el modelo llame agendarCita con los datos del historial.
     */
    private String getBookingConfirmInject(String conversationId, String userText) {
        if (userText == null || userText.isBlank()) return null;
        List<String> history = messageHistoryService.getHistory(conversationId);
        String lastAssistant = null;
        for (int i = history.size() - 1; i >= 0; i--) {
            String line = history.get(i);
            if (line.startsWith("assistant:")) {
                lastAssistant = line.substring(9).trim().toLowerCase();
                break;
            }
        }
        if (lastAssistant == null) return null;
        boolean lastAskedForDocument = lastAssistant.contains("cédula") || lastAssistant.contains("cedula") || lastAssistant.contains("documento");
        if (!lastAskedForDocument) return null;
        return "IMPORTANTE: El usuario acaba de responder con su documento/cédula. En la conversación ya están la fecha, hora y nombre (mensaje anterior del usuario). DEBES llamar ahora la herramienta agendarCita con: servicio (ej. Depilación), fecha YYYY-MM-DD, hora HH:mm, nombreCliente = el nombre que el usuario escribió en su mensaje anterior, documento = lo que el usuario acaba de escribir. Luego confirma la cita.";
    }

    /**
     * RAG + clasificación: se construye el contexto, se inyecta la clasificación del clasificador (2.º llamado)
     * y se llama al ChatModel (3.º llamado). Con tools conectados, el modelo puede ejecutar o solo responder con RAG.
     */
    private OutboundMessage generateResponseWithRag(String conversationId, String userText, String tenantId,
                                                     ConversationState state, IntentClassification classification) {
        TenantContext.set(tenantId);
        TenantContext.setUserId(state != null ? state.getUserId() : null);
        try {
            BuildContextResult ctxResult = aiContextBuilder.buildContext(state, userText);
            if (!ctxResult.hasRelevantChunks()) {
                log.info("[AI] Sin chunks RAG -> respuesta fija, no se llama al LLM");
                messageHistoryService.saveAssistantMessage(conversationId, messageNoRagInfo);
                return OutboundMessage.builder()
                    .text(messageNoRagInfo)
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build();
            }

            List<String> systemLines = new ArrayList<>(ctxResult.systemPromptLines());
            String classificationLine = formatClassification(classification);
            if (!classificationLine.isEmpty()) {
                systemLines.add(1, classificationLine);
            }
            String bookingInject = getBookingConfirmInject(conversationId, userText);
            if (bookingInject != null) {
                systemLines.add(1, bookingInject);
            }
            String systemText = String.join("\n", systemLines);
            if (!StringUtils.hasText(systemText)) {
                systemText = "Eres el asistente del negocio. Responde en español solo con la información en los fragmentos.";
            }

            List<Message> messages = new ArrayList<>();
            messages.add(new SystemMessage(systemText));
            List<String> history = messageHistoryService.getHistory(conversationId);
            for (String line : history) {
                if (line.startsWith("user:")) {
                    messages.add(new UserMessage(line.substring(4).trim()));
                } else if (line.startsWith("assistant:")) {
                    messages.add(new AssistantMessage(line.substring(9).trim()));
                }
            }
            messages.add(new UserMessage(userText));

            var prompt = new Prompt(messages);
            String rawText;
            if (chatClientWithTools != null) {
                try {
                    rawText = chatClientWithTools.prompt(prompt)
                        .call()
                        .content();
                } catch (Exception e) {
                    log.warn("[AI] ChatClient con tools falló, usando ChatModel sin tools: {}", e.getMessage());
                    var fallback = chatModel.call(prompt);
                    var out = fallback.getResult() != null ? fallback.getResult().getOutput() : null;
                    rawText = out != null ? out.getText() : "";
                }
            } else {
                var response = chatModel.call(prompt);
                var output = response.getResult() != null ? response.getResult().getOutput() : null;
                rawText = output != null ? output.getText() : "";
            }
            if (rawText == null) rawText = "";
            rawText = rawText.strip();
            if (rawText.isEmpty()) {
                log.error("[AI] RAG: respuesta vacía del modelo.");
                messageHistoryService.saveAssistantMessage(conversationId, messageAiError);
                return OutboundMessage.builder()
                    .text(messageAiError)
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build();
            }
            String safeText = responseValidator.validateAndSanitize(rawText);

            messageHistoryService.saveAssistantMessage(conversationId, safeText);
            return OutboundMessage.builder()
                .text(safeText)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build();
        } catch (Exception e) {
            log.error("[AI] RAG failed for conversation {}: {} — {}", conversationId, e.getMessage(), e.getClass().getSimpleName(), e);
            messageHistoryService.saveAssistantMessage(conversationId, messageAiError);
            return OutboundMessage.builder()
                .text(messageAiError)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build();
        } finally {
            TenantContext.clear();
        }
    }

    /**
     * Resultado de construir el contexto para el LLM.
     * hasRelevantChunks=false significa que el RAG no encontró nada relevante → no llamar al LLM.
     */
    public record BuildContextResult(List<String> systemPromptLines, boolean hasRelevantChunks) {
        public static BuildContextResult withChunks(List<String> lines) {
            return new BuildContextResult(lines, true);
        }
        public static BuildContextResult noChunks(List<String> lines) {
            return new BuildContextResult(lines, false);
        }
    }

    /**
     * Builds system prompt and signals if there is relevant RAG context (si no hay, no se llama al LLM).
     */
    public interface AiContextBuilder {
        BuildContextResult buildContext(ConversationState state, String userMessage);
    }

    /**
     * Validates/sanitizes LLM output. Must not invent information.
     */
    private static String formatClassification(IntentClassification c) {
        if (c == null) return "";
        if (c.isGreeting()) return "Clasificación del mensaje actual: SALUDO.";
        if (c.isGeneralQuestion()) return "Clasificación del mensaje actual: PREGUNTA_GENERAL.";
        if (c.isBadIntent()) return "Clasificación del mensaje actual: MALA_INTENCION.";
        if (c.isCrmAction()) {
            String actionId = c.getActionId().orElse("");
            if ("book_appointment".equals(actionId)) {
                return "Clasificación: ACCION_CRM book_appointment. Flujo para agendar: (1) Si el usuario indica una fecha (ej. mañana, el lunes), llama getSlotsDisponibles con esa fecha en YYYY-MM-DD y ofrece las horas disponibles. (2) Cuando el usuario elija hora (ej. 09:00), DEBES preguntar: '¿Cuál es tu nombre completo?' y esperar su respuesta. (3) Cuando el usuario dé su nombre, DEBES preguntar: '¿Cuál es tu número de cédula o documento?' y esperar su respuesta. (4) SOLO después de que el usuario haya escrito su nombre y su documento en el chat, llama agendarCita con esos datos exactos. PROHIBIDO usar 'Cliente WhatsApp', 'Por confirmar' o similares: la herramienta los rechazará. Si llamas agendarCita sin nombre o documento real del usuario, la herramienta te devolverá error y tendrás que preguntar.";
            }
            return "Clasificación del mensaje actual: ACCION_CRM " + actionId + ". Si el usuario quiere agendar, usa getSlotsDisponibles y agendarCita cuando tengas fecha y hora.";
        }
        return "";
    }

    public interface ResponseValidator {
        String validateAndSanitize(String rawResponse);
    }
}
