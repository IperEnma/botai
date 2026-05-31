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
import com.botai.application.chatbot.service.action.GetAgendaPublicUrlAction;
import com.botai.application.chatbot.service.agenda.PublicAgendaLinkResolver;
import com.botai.application.chatbot.service.inbound.ChatSessionService;
import com.botai.application.chatbot.support.StandardRouteResponses;
import com.botai.application.chatbot.service.inbound.MessageHistoryService;
import com.botai.application.chatbot.support.InboundMetadata;
import com.botai.application.chatbot.support.InboundTextHeuristics;
import com.botai.infrastructure.config.AppUrlProperties;
import com.botai.infrastructure.security.context.ThreadTenantContext;
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

import java.net.URI;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

/**
 * <strong>Flujo completo del turno generativo (modo solo IA y segunda capa FAQ+IA).</strong>
 * <ol>
 *   <li><strong>Clasificación</strong> la hace el orquestador; en {@link #handle}: error clasificador/mala intención (LLM si IA activa),
 *       CRM vía {@link ConversationActionRouting} (nueva reserva Agenda → enlace público, sin wizard en chat).</li>
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
    private final ChatClient chatClientPlain;
    private final boolean selfReviewEnabled;
    private final PublicAgendaLinkResolver publicAgendaLinkResolver;
    private final AppUrlProperties appUrls;
    private final String messageTenantUnknown;
    private final String messageAiError;

    private static final Pattern HTTP_URL = Pattern.compile("(?i)https?://[^\\s)>\\]]+");

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
                             @Qualifier("chatClientPlain") ChatClient chatClientPlain,
                             @Value("${bot.rag.self-review-enabled:false}") boolean selfReviewEnabled,
                             PublicAgendaLinkResolver publicAgendaLinkResolver,
                             AppUrlProperties appUrls,
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
        this.chatClientPlain = chatClientPlain;
        this.selfReviewEnabled = selfReviewEnabled;
        this.publicAgendaLinkResolver = publicAgendaLinkResolver;
        this.appUrls = appUrls;
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
            .or(() -> whenBookingHeuristicOverridesGeneralQuestion(ctx))
            .or(() -> actionRouting.respondIfCrmIntentButActionsDisabled(ctx))
            .or(() -> replyWithLlm(AiConversationRequest.of(ctx.inbound(), ctx.state(), ctx.classification())));
    }

    /** Si el mini-LLM dijo PREGUNTA_GENERAL pero el texto es claramente reservar, forzar enlace real. */
    private Optional<ConversationRouteResult> whenBookingHeuristicOverridesGeneralQuestion(
        ConversationHandlingContext ctx) {
        if (!ctx.classification().isGeneralQuestion()
            || !InboundTextHeuristics.looksLikeNewBookingRequest(ctx.text())
            || !featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, ctx.tenantId())) {
            return Optional.empty();
        }
        log.info("[RAG-LLM] PREGUNTA_GENERAL + heuristica reserva -> get_agenda_public_url");
        var bookingIntent = new IntentClassification.CrmAction(GetAgendaPublicUrlAction.ACTION_ID);
        var bookingCtx = new ConversationHandlingContext(
            ctx.conversationId(), ctx.tenantId(), ctx.text(), ctx.inbound(), ctx.state(), bookingIntent);
        return actionRouting.startCrmFromClassificationIfEnabled(bookingCtx);
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
            log.info("[AI] Mala intencion -> LLM");
            return replyWithLlm(new AiConversationRequest(ctx.inbound(), ctx.state(), ctx.classification(),
                BotPrompts.RouterSupplement.badIntentLines()));
        }
        log.info("[AI] Mala intencion -> mensaje fijo (IA off)");
        return Optional.of(standardRouteResponses.badIntent(ctx.conversationId(), tenantId));
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
                inbound, request.state(), request.classification(), mergeLists(guardSupp, supplemental));
            return Optional.of(new ConversationRouteResult(msg, ConversationIntentSource.AI, null));
        }

        log.info("[RAG-LLM] Generacion RAG + clasificacion inyectada");
        OutboundMessage out = generateResponse(
            inbound, request.state(), request.classification(), supplemental);
        return Optional.of(new ConversationRouteResult(out, ConversationIntentSource.AI, null));
    }

    private static List<String> mergeLists(List<String> a, List<String> b) {
        if (b == null || b.isEmpty()) return a;
        return Stream.concat(a.stream(), b.stream()).toList();
    }

    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state) {
        return generateResponse(inbound, state, null, Collections.emptyList());
    }

    /**
     * Generación con la clasificación del router ya resuelta (inyectada en system prompt vía {@link BotPrompts.InjectedClassification}).
     */
    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification) {
        return generateResponse(inbound, state, classification, Collections.emptyList());
    }

    /**
     * Líneas extra de system (router: clasificador caído, mala intención, etc.).
     */
    public OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification,
                                           List<String> supplementalSystemLines) {
        return generateResponse(inbound, state, classification, supplementalSystemLines, aiContextBuilder);
    }

    /**
     * Misma generación que {@link #generateResponse} pero sin fragmentos RAG (solo reglas mínimas + tools); útil para comparar en diagnóstico.
     */
    public OutboundMessage generateResponseNoRag(InboundMessage inbound, ConversationState state, IntentClassification classification) {
        return generateResponse(inbound, state, classification, Collections.emptyList(), defaultAiContextBuilder);
    }

    private OutboundMessage generateResponse(InboundMessage inbound, ConversationState state, IntentClassification classification,
                                           List<String> supplementalSystemLines, AiContextBuilder contextBuilder) {
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

        return generateResponseWithRag(inbound, conversationId, userText, tenantId, state, classification, supplementalSystemLines, contextBuilder);
    }

    private OutboundMessage generateResponseWithRag(InboundMessage inbound, String conversationId, String userText, String tenantId,
                                                     ConversationState state, IntentClassification classification,
                                                     List<String> supplementalSystemLines,
                                                     AiContextBuilder contextBuilder) {
        String sessionId = ChatSessionService.sessionIdFrom(state);
        String memoryKey = ChatMemoryConversationIdCodec.encode(conversationId, sessionId);
        ThreadTenantContext.setTenantId(tenantId);
        ThreadTenantContext.setUserId(resolveUserIdForTools(inbound, state));
        ThreadTenantContext.setConversationId(conversationId);
        try {
            BuildContextResult ctxResult = contextBuilder.buildContext(state, userText);
            List<String> systemLines = new ArrayList<>(ctxResult.systemPromptLines());
            boolean ragEmpty = !ctxResult.hasRelevantChunks();
            if (ragEmpty) {
                log.info("[RAG-LLM] Sin chunks RAG -> LLM con contexto mínimo (fecha + reglas conservadoras)");
                systemLines.add("");
                systemLines.add(BotPrompts.RagChat.NO_CHUNKS_SECTION_TITLE);
                systemLines.add(BotPrompts.RagChat.NO_CHUNKS_LINE_USE_TOOLS);
                systemLines.add(BotPrompts.RagChat.NO_CHUNKS_LINE_SIN_DATOS);
                systemLines.add(BotPrompts.RagChat.NO_CHUNKS_LINE_AGENDAR_TOOLS);
            }

            String classificationLine = BotPrompts.InjectedClassification.lineFor(classification);
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
            safeText = replaceHallucinatedBookingUrls(safeText, tenantId, ut);

            if (selfReviewEnabled && chatClientPlain != null && ut.length() >= 2) {
                String ragFacts = extractRagFactsFromSystemLines(systemLines);
                List<String> histLines = messageHistoryService.getHistory(conversationId, sessionId);
                String threadBlock = histLines.isEmpty() ? "" : String.join("\n", histLines);
                Optional<String> refined = runSelfReview(ut, safeText, ragFacts, threadBlock);
                if (refined.isPresent() && !wouldDiscardRefinement(safeText, refined.get(), ragFacts)) {
                    safeText = responseValidator.validateAndSanitize(refined.get());
                    safeText = replaceHallucinatedBookingUrls(safeText, tenantId, ut);
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
    /**
     * Si el modelo inventó Calendly u otra URL ajena al frontend configurado, sustituir por el enlace Agenda real.
     */
    private String replaceHallucinatedBookingUrls(String text, String tenantId, String userText) {
        if (text == null || text.isBlank() || tenantId == null || tenantId.isBlank()) {
            return text;
        }
        if (!InboundTextHeuristics.containsHttpUrl(text)) {
            return text;
        }
        String allowedHost = frontendHost();
        if (allowedHost.isEmpty() || allUrlsMatchHost(text, allowedHost)) {
            return text;
        }
        if (!InboundTextHeuristics.looksLikeNewBookingRequest(userText)
            && !InboundTextHeuristics.containsHttpUrl(userText)) {
            return text;
        }
        log.warn("[RAG-LLM] URL externa/inventada en respuesta de reserva; tenant={} -> enlace Agenda", tenantId);
        return publicAgendaLinkResolver.buildBookingReplyForTenant(tenantId)
            .orElse(publicAgendaLinkResolver.noLinkMessage());
    }

    private String frontendHost() {
        try {
            String base = appUrls.normalizedFrontend();
            if (base.isBlank()) {
                return "";
            }
            URI uri = URI.create(base);
            return uri.getHost() != null ? uri.getHost().toLowerCase() : "";
        } catch (Exception e) {
            return "";
        }
    }

    private static boolean allUrlsMatchHost(String text, String allowedHost) {
        Matcher m = HTTP_URL.matcher(text);
        while (m.find()) {
            String url = m.group();
            try {
                URI uri = URI.create(url);
                String host = uri.getHost();
                if (host == null || !host.equalsIgnoreCase(allowedHost)) {
                    return false;
                }
            } catch (Exception e) {
                return false;
            }
        }
        return true;
    }

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
