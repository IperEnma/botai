package com.botai.application.chatbot.service.conversation.ai;

import com.botai.application.chatbot.dto.AiConversationRequest;
import com.botai.application.chatbot.dto.ConversationIntentSource;
import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.application.chatbot.dto.IntentClassification;
import com.botai.application.chatbot.orchestration.ConversationHandlingContext;
import com.botai.application.chatbot.orchestration.ConversationMode;
import com.botai.application.chatbot.orchestration.ConversationModeHandler;
import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.application.chatbot.service.conversation.common.ConversationActionRouting;
import com.botai.application.chatbot.service.inbound.ChatSessionService;
import com.botai.application.chatbot.support.StandardRouteResponses;
import com.botai.application.chatbot.service.inbound.MessageHistoryService;
import com.botai.application.chatbot.support.InboundMetadata;
import com.botai.application.chatbot.support.InboundTextHeuristics;
import com.botai.infrastructure.common.context.ThreadTenantContext;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.infrastructure.chatbot.ai.memory.ChatMemoryConversationIdCodec;
import com.botai.infrastructure.chatbot.config.BotMessages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.memory.ChatMemory;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.SystemMessage;
import org.springframework.ai.chat.messages.UserMessage;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Stream;

/**
 * <strong>Flujo completo del turno generativo (modo solo IA y segunda capa FAQ+IA).</strong>
 * <ol>
 *   <li><strong>Clasificación</strong> la hace el orquestador; en {@link #handle}: error clasificador/mala intención (LLM si IA activa),
 *       CRM vía {@link ConversationActionRouting}. Con IA activa, {@code book_appointment} no usa el wizard: solo LLM + tools y
 *       línea de sistema fija de agendamiento mientras el intent siga activo.</li>
 *   <li>{@link BotFeatures#AI_ENABLED} → si no, {@link #replyWithLlm} devuelve vacío.</li>
 *   <li>{@link JailbreakInputFilter} → si bloquea, se llama al LLM igualmente con suplementos
 *       {@link BotPrompts.RouterSupplement#jailbreakFilteredLines()}.</li>
 *   <li>Construcción de contexto RAG ({@link AiContextBuilder}), inyección de línea de clasificación + suplementos del router.</li>
 *   <li>Llamada a {@link ChatClient} (tools + memoria Spring AI): el modelo interpreta el mensaje y ejecuta herramientas; si falla, se registra el error y se responde con mensaje fijo de error (sin otros caminos).</li>
 *   <li>{@link ResponseValidator} en salida.</li>
 * </ol>
 * Implementa {@link ConversationModeHandler} para {@link ConversationMode#AI_ONLY}.
 */
@Service
public class RagLlmChatService implements ConversationModeHandler {

    private static final Logger log = LoggerFactory.getLogger(RagLlmChatService.class);
    private final ChatClient chatClientWithTools;
    private final AiContextBuilder aiContextBuilder;
    private final AiContextBuilder defaultAiContextBuilder;
    private final ResponseValidator responseValidator;
    private final MessageHistoryService messageHistoryService;
    private final FeatureFlagService featureFlagService;
    private final JailbreakInputFilter jailbreakInputFilter;
    private final ConversationActionRouting actionRouting;
    private final StandardRouteResponses standardRouteResponses;
    private final ConversationRepository conversationRepository;
    private final ChatMemory chatMemory;
    private final BookingAiFastPathService bookingAiFastPathService;
    private final ChatClient chatClientPlain;
    private final boolean selfReviewEnabled;
    private final String messageTenantUnknown;
    private final String messageAiError;

    public RagLlmChatService(ChatClient chatClientWithTools,
                             AiContextBuilder aiContextBuilder,
                             @Qualifier("defaultAiContextBuilder") AiContextBuilder defaultAiContextBuilder,
                             ResponseValidator responseValidator,
                             MessageHistoryService messageHistoryService,
                             FeatureFlagService featureFlagService,
                             JailbreakInputFilter jailbreakInputFilter,
                             ConversationActionRouting actionRouting,
                             StandardRouteResponses standardRouteResponses,
                             ConversationRepository conversationRepository,
                             ChatMemory chatMemory,
                             BookingAiFastPathService bookingAiFastPathService,
                             @Qualifier("chatClientPlain") ChatClient chatClientPlain,
                             @Value("${bot.rag.self-review-enabled:false}") boolean selfReviewEnabled,
                             BotMessages botMessages) {
        this.chatClientWithTools = chatClientWithTools;
        this.aiContextBuilder = aiContextBuilder;
        this.defaultAiContextBuilder = defaultAiContextBuilder;
        this.responseValidator = responseValidator;
        this.messageHistoryService = messageHistoryService;
        this.featureFlagService = featureFlagService;
        this.jailbreakInputFilter = jailbreakInputFilter;
        this.actionRouting = actionRouting;
        this.standardRouteResponses = standardRouteResponses;
        this.conversationRepository = conversationRepository;
        this.chatMemory = chatMemory;
        this.bookingAiFastPathService = bookingAiFastPathService;
        this.chatClientPlain = chatClientPlain;
        this.selfReviewEnabled = selfReviewEnabled;
        String tu = botMessages.getTenantUnknown();
        String ae = botMessages.getAiError();
        this.messageTenantUnknown = tu != null && !tu.isBlank() ? tu : "No se pudo identificar el negocio. Revisa la configuración del bot.";
        this.messageAiError = ae != null && !ae.isBlank() ? ae : "No pude conectar con el asistente. Verifica que Ollama esté en marcha.";
    }

    @Override
    public ConversationMode mode() {
        return ConversationMode.AI_ONLY;
    }

    @Override
    public Optional<ConversationRouteResult> handle(ConversationHandlingContext ctx) {
        return whenClassifierFailedThenLlm(ctx)
            .or(() -> actionRouting.continueActiveActionIfAny(ctx))
            .or(() -> whenBadIntentThenLlm(ctx))
            .or(() -> actionRouting.startCrmFromClassificationIfEnabled(ctx))
            .or(() -> actionRouting.respondIfCrmIntentButActionsDisabled(ctx))
            .or(() -> replyWithLlm(AiConversationRequest.of(ctx.inbound(), ctx.state(), ctx.classification())));
    }

    private Optional<ConversationRouteResult> whenClassifierFailedThenLlm(ConversationHandlingContext ctx) {
        if (!ctx.classification().isServiceError()) {
            return Optional.empty();
        }
        String tenantId = ctx.tenantId();
        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            log.warn("[AI] Clasificador en error -> LLM");
            return replyWithLlm(new AiConversationRequest(ctx.inbound(), ctx.state(), ctx.classification(),
                BotPrompts.RouterSupplement.classifierFailureLines()));
        }
        log.warn("[AI] Clasificador en error -> mensaje fijo (IA off)");
        return Optional.of(standardRouteResponses.classifierUnavailable(ctx.conversationId(), tenantId));
    }

    private Optional<ConversationRouteResult> whenBadIntentThenLlm(ConversationHandlingContext ctx) {
        if (!ctx.classification().isBadIntent()) {
            return Optional.empty();
        }
        String tenantId = ctx.tenantId();
        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            if (isBookingFlow(ctx.state(), ctx.classification())
                && InboundTextHeuristics.looksLikeNoiseOrCorruptedContent(ctx.text())) {
                log.info("[AI] Mala intencion con ruido/encoding en flujo cita -> LLM sin suplemento hostil");
                return replyWithLlm(AiConversationRequest.of(ctx.inbound(), ctx.state(), ctx.classification()));
            }
            if (isBookingFlow(ctx.state(), ctx.classification())
                && looksLikeUserProvidedBookingData(ctx.text())) {
                // El clasificador a veces marca como "bad intent" un mensaje que en realidad trae datos
                // (documento y/o nombre) para continuar el flujo de citas. Tratamos esto como continuación normal.
                log.info("[AI] Mala intencion pero parece dato de usuario en flujo cita -> LLM sin suplemento hostil");
                return replyWithLlm(AiConversationRequest.of(ctx.inbound(), ctx.state(), ctx.classification()));
            }
            log.info("[AI] Mala intencion -> LLM");
            return replyWithLlm(new AiConversationRequest(ctx.inbound(), ctx.state(), ctx.classification(),
                BotPrompts.RouterSupplement.badIntentLines()));
        }
        log.info("[AI] Mala intencion -> mensaje fijo (IA off)");
        return Optional.of(standardRouteResponses.badIntent(ctx.conversationId(), tenantId));
    }

    private static boolean looksLikeUserProvidedBookingData(String text) {
        if (text == null) return false;
        String s = text.strip();
        if (s.isEmpty()) return false;

        boolean hasLetter = s.chars().anyMatch(Character::isLetter);
        int digitCount = (int) s.chars().filter(Character::isDigit).count();

        // Caso común: documento (solo dígitos o con separadores) enviado como seguimiento.
        if (!hasLetter && digitCount >= 5) {
            return true;
        }

        // Caso común: nombre completo enviado solo (sin documento) como seguimiento.
        if (hasLetter && digitCount == 0) {
            String normalized = s.replaceAll("[^\\p{L}\\s'-]", " ")
                .replaceAll("\\s{2,}", " ")
                .strip();
            int words = normalized.isEmpty() ? 0 : normalized.split("\\s+").length;
            // Umbral conservador para evitar falsos positivos (ej. "hola", "ok").
            return words >= 2 && normalized.length() >= 10;
        }

        // Ejemplo típico mixto: "62995895\nEnmanuel Alejandro Hernández".
        return hasLetter && digitCount >= 5;
    }

    private static String resolveUserIdForTools(InboundMessage inbound, ConversationState state) {
        if (inbound != null) {
            String uid = inbound.getUserId();
            if (uid != null && !uid.isBlank() && !"unknown".equalsIgnoreCase(uid.strip())) {
                return uid;
            }
        }
        return state != null ? state.getUserId() : null;
    }

    /**
     * Punto de entrada del turno LLM: feature IA → jailbreak → RAG + modelo (la clasificación ya viene del router).
     */
    public Optional<ConversationRouteResult> replyWithLlm(AiConversationRequest request) {
        InboundMessage inbound = request.inbound();
        String tenantId = InboundMetadata.tenantId(inbound);
        if (tenantId == null || !featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            return Optional.empty();
        }
        String text = inbound.getText() != null ? inbound.getText() : "";
        var supplemental = request.supplementalSystemLines() != null ? request.supplementalSystemLines() : List.<String>of();

        JailbreakInputFilter.Decision jailbreakDecision = jailbreakInputFilter.evaluate(text, tenantId);
        if (!jailbreakDecision.allowed()) {
            log.info("[RAG-LLM] Jailbreak filtrado -> LLM con contexto de limite");
            List<String> guardSupp = BotPrompts.RouterSupplement.jailbreakFilteredLines();
            OutboundMessage msg = generateResponse(
                inbound, request.state(), request.classification(), mergeLists(guardSupp, supplemental), false);
            return Optional.of(new ConversationRouteResult(msg, ConversationIntentSource.AI, null));
        }

        log.info("[RAG-LLM] Generacion RAG + clasificacion inyectada");
        OutboundMessage out = generateResponse(
            inbound, request.state(), request.classification(), supplemental, true);
        return Optional.of(new ConversationRouteResult(out, ConversationIntentSource.AI, null));
    }

    private static List<String> mergeLists(List<String> a, List<String> b) {
        if (b == null || b.isEmpty()) return a;
        return Stream.concat(a.stream(), b.stream()).toList();
    }

    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state) {
        return generateResponse(inbound, state, null, Collections.emptyList(), true);
    }

    /**
     * Generación con la clasificación del router ya resuelta (inyectada en system prompt vía {@link BotPrompts.InjectedClassification}).
     */
    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification) {
        return generateResponse(inbound, state, classification, Collections.emptyList(), true);
    }

    /**
     * Líneas extra de system (router: clasificador caído, mala intención, etc.).
     */
    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification,
                                           List<String> supplementalSystemLines) {
        return generateResponse(inbound, state, classification, supplementalSystemLines, true);
    }

    /**
     * Igual que {@link #generateResponse(InboundMessage, ConversationState, IntentClassification, List)} con control del
     * atajo determinístico de agendamiento (desactivado p. ej. tras filtro jailbreak).
     */
    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification,
                                           List<String> supplementalSystemLines, boolean allowBookingFastPath) {
        return generateResponse(inbound, state, classification, supplementalSystemLines, aiContextBuilder, allowBookingFastPath);
    }

    /**
     * Misma generación que {@link #generateResponse} pero sin fragmentos RAG (solo reglas mínimas + tools); útil para comparar en diagnóstico.
     */
    public OutboundMessage generateResponseNoRag(InboundMessage inbound, ConversationState state, IntentClassification classification) {
        return generateResponse(inbound, state, classification, Collections.emptyList(), defaultAiContextBuilder, true);
    }

    private OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification,
                                           List<String> supplementalSystemLines, AiContextBuilder contextBuilder,
                                           boolean allowBookingFastPath) {
        String conversationId = inbound.getConversationId();
        String userText = inbound.getText();
        String tenantId = InboundMetadata.tenantId(inbound);

        if (conversationId != null && !conversationId.isBlank()) {
            state = conversationRepository.findByConversationId(conversationId).orElse(state);
        }

        String sessionId = ChatSessionService.sessionIdFrom(state);
        if (tenantId == null) {
            messageHistoryService.saveUserMessage(conversationId, sessionId, userText);
            messageHistoryService.saveAssistantMessage(conversationId, sessionId, messageTenantUnknown);
            return OutboundMessage.builder().text(messageTenantUnknown).conversationId(conversationId).tenantId(null).build();
        }

        return generateResponseWithRag(inbound, conversationId, userText, tenantId, state, classification, supplementalSystemLines, contextBuilder,
            allowBookingFastPath);
    }

    private OutboundMessage generateResponseWithRag(InboundMessage inbound, String conversationId, String userText, String tenantId,
                                                     ConversationState state, IntentClassification classification,
                                                     List<String> supplementalSystemLines,
                                                     AiContextBuilder contextBuilder,
                                                     boolean allowBookingFastPath) {
        String sessionId = ChatSessionService.sessionIdFrom(state);
        String memoryKey = ChatMemoryConversationIdCodec.encode(conversationId, sessionId);
        ThreadTenantContext.setTenantId(tenantId);
        ThreadTenantContext.setUserId(resolveUserIdForTools(inbound, state));
        ThreadTenantContext.setConversationId(conversationId);
        try {
            if (allowBookingFastPath && isBookingFlow(state, classification)) {
                Optional<String> fastPath = bookingAiFastPathService.tryExecute(tenantId, conversationId, sessionId, userText);
                if (fastPath.isPresent()) {
                    String ut = userText != null ? userText : "";
                    String safeText = responseValidator.validateAndSanitize(fastPath.get());
                    chatMemory.add(memoryKey, new UserMessage(ut));
                    chatMemory.add(memoryKey, new AssistantMessage(safeText));
                    log.info("[RAG-LLM] Agendamiento determinístico (sin LLM); conversationId={}", conversationId);
                    return OutboundMessage.builder()
                        .text(safeText)
                        .conversationId(conversationId)
                        .tenantId(tenantId)
                        .build();
                }
            }

            BuildContextResult ctxResult = contextBuilder.buildContext(state, userText);
            List<String> systemLines = new ArrayList<>(ctxResult.systemPromptLines());
            boolean ragEmpty = !ctxResult.hasRelevantChunks();
            if (ragEmpty) {
                log.info("[RAG-LLM] Sin chunks RAG -> LLM con contexto mínimo (fecha + reglas conservadoras)");
                systemLines.add("");
                systemLines.add(BotPrompts.RagChat.NO_CHUNKS_SECTION_TITLE);
                systemLines.add(BotPrompts.RagChat.NO_CHUNKS_LINE_NO_INVENTAR);
                if (isBookingFlow(state, classification)) {
                    systemLines.add(BotPrompts.RagChat.NO_CHUNKS_LINE_BOOKING_USE_TOOLS);
                } else {
                    systemLines.add(BotPrompts.RagChat.NO_CHUNKS_LINE_SIN_DATOS);
                }
                systemLines.add(BotPrompts.RagChat.NO_CHUNKS_LINE_AGENDAR_TOOLS);
            }

            String classificationLine = bookingClassificationLine(state, tenantId, classification);
            int insertAt = 1;
            if (supplementalSystemLines != null && !supplementalSystemLines.isEmpty()) {
                for (int i = supplementalSystemLines.size() - 1; i >= 0; i--) {
                    systemLines.add(insertAt, supplementalSystemLines.get(i));
                }
                insertAt += supplementalSystemLines.size();
            }
            if (!classificationLine.isEmpty()) {
                systemLines.add(insertAt, classificationLine);
            }
            String systemText = String.join("\n", systemLines);
            if (!StringUtils.hasText(systemText)) {
                systemText = BotPrompts.RagChat.FALLBACK_SYSTEM_WHEN_BLANK;
            }

            String ut = userText != null ? userText : "";
            Prompt turnPrompt = new Prompt(List.of(new SystemMessage(systemText), new UserMessage(ut)));

            if (chatClientWithTools == null) {
                log.error("[RAG-LLM] ChatClient no configurado (null); conversationId={}", conversationId);
                messageHistoryService.saveAssistantMessage(conversationId, sessionId, messageAiError);
                return OutboundMessage.builder()
                    .text(messageAiError)
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build();
            }

            String rawText = chatClientWithTools.prompt(turnPrompt)
                .advisors(a -> a.param(ChatMemory.CONVERSATION_ID, memoryKey))
                .call()
                .content();
            if (rawText == null) rawText = "";
            rawText = rawText.strip();
            if (rawText.isEmpty()) {
                log.error("[RAG-LLM] Respuesta vacía del modelo; conversationId={}", conversationId);
                messageHistoryService.saveAssistantMessage(conversationId, sessionId, messageAiError);
                return OutboundMessage.builder()
                    .text(messageAiError)
                    .conversationId(conversationId)
                    .tenantId(tenantId)
                    .build();
            }
            String safeText = responseValidator.validateAndSanitize(rawText);

            if (selfReviewEnabled && chatClientPlain != null && !isBookingFlow(state, classification)
                && ut.length() >= 2) {
                String ragFacts = extractRagFactsFromSystemLines(systemLines);
                List<String> histLines = messageHistoryService.getHistory(conversationId, sessionId);
                String threadBlock = histLines.isEmpty() ? "" : String.join("\n", histLines);
                Optional<String> refined = runSelfReview(ut, safeText, ragFacts, threadBlock);
                if (refined.isPresent() && !wouldDiscardRefinement(safeText, refined.get(), ragFacts)) {
                    safeText = responseValidator.validateAndSanitize(refined.get());
                    log.debug("[RAG-LLM] Self-review aplicada; conversationId={}", conversationId);
                }
            }

            // Assistant persistido por PromptChatMemoryAdvisor + MessageWindowChatMemory (misma tabla message).
            return OutboundMessage.builder()
                .text(safeText)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build();
        } catch (Exception e) {
            log.error("[RAG-LLM] Fallo para conversationId={}: {} — {}",
                conversationId, e.getClass().getSimpleName(), e.getMessage(), e);
            messageHistoryService.saveAssistantMessage(conversationId, sessionId, messageAiError);
            return OutboundMessage.builder()
                .text(messageAiError)
                .conversationId(conversationId)
                .tenantId(tenantId)
                .build();
        } finally {
            ThreadTenantContext.clear();
        }
    }

    /**
     * Flujo de agendamiento para fast path y reglas “sin chunks”: si en BD sigue {@code book_appointment},
     * se mantiene aunque el mini-clasificador marque PREGUNTA_GENERAL (typos, ruido). La línea inyectada
     * {@link #bookingClassificationLine} sigue acortando el bloque CRM cuando el clasificador pide tono FAQ/saludo.
     */
    private static String extractRagFactsFromSystemLines(List<String> lines) {
        if (lines == null || lines.isEmpty()) {
            return "";
        }
        int start = -1;
        int end = -1;
        for (int i = 0; i < lines.size(); i++) {
            if (BotPrompts.RagChat.FRAGMENTS_SECTION_TITLE.equals(lines.get(i))) {
                start = i + 1;
            } else if (BotPrompts.RagChat.FRAGMENTS_SECTION_END.equals(lines.get(i)) && start >= 0) {
                end = i;
                break;
            }
        }
        if (start < 0 || end < 0 || end <= start) {
            return "";
        }
        return String.join("\n", lines.subList(start, end));
    }

    private Optional<String> runSelfReview(String userMessage, String draftReply, String ragFacts, String recentThread) {
        try {
            String sys = BotPrompts.RagChat.buildSelfReviewSystemPrompt(ragFacts, userMessage, draftReply, recentThread);
            Prompt reviewPrompt = new Prompt(List.of(
                new SystemMessage(sys),
                new UserMessage("Produce only the final Spanish message.")
            ));
            String out = chatClientPlain.prompt(reviewPrompt).call().content();
            if (out == null || out.isBlank()) {
                return Optional.empty();
            }
            return Optional.of(out.strip());
        } catch (Exception e) {
            log.warn("[RAG-LLM] Self-review omitida: {} — {}", e.getClass().getSimpleName(), e.getMessage());
            return Optional.empty();
        }
    }

    /**
     * Evita aceptar una “mejora” vacía o sospechosamente recortada frente al borrador o a fragmentos RAG largos.
     */
    private static boolean wouldDiscardRefinement(String original, String refined, String ragFacts) {
        if (refined == null || refined.isBlank()) {
            return true;
        }
        if (original != null && original.length() > 60 && refined.length() < Math.min(20, original.length() / 4)) {
            return true;
        }
        if (ragFacts != null && ragFacts.length() > 80 && refined.length() < 15) {
            return true;
        }
        return false;
    }

    private static boolean isBookingFlow(ConversationState state, IntentClassification classification) {
        if (state != null && state.hasIntent()
            && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(state.getCurrentIntent())) {
            return true;
        }
        if (classification != null && (classification.isGeneralQuestion() || classification.isGreeting())) {
            return false;
        }
        return classification != null && classification.isCrmAction()
            && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(classification.getActionId().orElse(""));
    }

    private String bookingClassificationLine(ConversationState state, String tenantId, IntentClassification classification) {
        boolean activeBookingWithAi = state != null && state.hasIntent()
            && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(state.getCurrentIntent())
            && tenantId != null
            && featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId);
        if (!activeBookingWithAi) {
            return BotPrompts.InjectedClassification.lineFor(classification);
        }
        if (classification != null && classification.isGeneralQuestion()) {
            return BotPrompts.InjectedClassification.GENERAL_QUESTION
                + BotPrompts.InjectedClassification.PENDING_BOOKING_GENERAL_SUFFIX;
        }
        if (classification != null && classification.isGreeting()) {
            return BotPrompts.InjectedClassification.GREETING
                + BotPrompts.InjectedClassification.PENDING_BOOKING_GREETING_SUFFIX;
        }
        if (classification != null && (classification.isBadIntent() || classification.isServiceError())) {
            return BotPrompts.InjectedClassification.lineFor(classification);
        }
        if (classification != null && classification.isCrmAction()) {
            String aid = classification.getActionId().orElse("");
            if (!ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(aid)) {
                return BotPrompts.InjectedClassification.lineFor(classification);
            }
        }
        return BotPrompts.InjectedClassification.CRM_BOOK_APPOINTMENT
            + BotPrompts.InjectedClassification.CRM_BOOK_APPOINTMENT_TIME_FOLLOWUP
            + " Si el último mensaje solo aporta un dato (documento, hora, confirmación), intégralo con el historial sin reiniciar el flujo.";
    }

    /**
     * Resultado de construir el system prompt para el LLM (fragmentos RAG + reglas).
     */
    public record BuildContextResult(List<String> systemPromptLines, boolean hasRelevantChunks) {
        public static BuildContextResult withChunks(List<String> lines) {
            return new BuildContextResult(lines, true);
        }
        public static BuildContextResult noChunks(List<String> lines) {
            return new BuildContextResult(lines, false);
        }
    }

    /** Arma el system prompt (p. ej. RAG) que verá el modelo en este turno. */
    public interface AiContextBuilder {
        BuildContextResult buildContext(ConversationState state, String userMessage);
    }

    /** Valida y sanea el texto devuelto por el modelo antes de enviarlo al usuario. */
    public interface ResponseValidator {
        String validateAndSanitize(String rawResponse);
    }

}
