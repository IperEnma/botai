package com.botai.application.chatbot.service.feedback;

import com.botai.application.chatbot.dto.ConversationIntentSource;
import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.application.chatbot.support.InboundMetadata;
import com.botai.application.chatbot.support.InboundTextHeuristics;
import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.model.ConversationFeedbackRating;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.application.chatbot.service.inbound.ChatSessionService;
import com.botai.infrastructure.chatbot.config.BotMessages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Al cerrar la conversación (despedida del cliente), pregunta si fue útil y registra Sí/No.
 * El cliente responde por el mismo canal (WhatsApp, web); no se exponen detalles técnicos.
 */
@Service
public class ConversationFeedbackFlowService {

    private static final Logger log = LoggerFactory.getLogger(ConversationFeedbackFlowService.class);

    private final ConversationFeedbackService feedbackService;
    private final ConversationRepository conversationRepository;
    private final String question;
    private final String thanksPositive;
    private final String thanksNegative;
    private final String thanksUnclear;

    public ConversationFeedbackFlowService(ConversationFeedbackService feedbackService,
                                           ConversationRepository conversationRepository,
                                           BotMessages botMessages) {
        this.feedbackService = feedbackService;
        this.conversationRepository = conversationRepository;
        this.question = defaultText(botMessages.getFeedbackQuestion(),
            "¿Te resultó útil esta conversación? Respondé Sí o No.");
        this.thanksPositive = defaultText(botMessages.getFeedbackThanksPositive(),
            "¡Gracias! Nos alegra haberte ayudado.");
        this.thanksNegative = defaultText(botMessages.getFeedbackThanksNegative(),
            "Gracias por contarnos. Trabajaremos para mejorar.");
        this.thanksUnclear = defaultText(botMessages.getFeedbackThanksUnclear(),
            "Respondé Sí o No para saber si te fue útil.");
    }

    public boolean isAwaitingFeedback(ConversationState state) {
        if (state == null || state.getContext() == null) {
            return false;
        }
        return Boolean.TRUE.equals(state.getContext().get(ConversationContextKeys.FEEDBACK_AWAITING));
    }

    /**
     * Si el turno anterior pidió feedback, consume la respuesta Sí/No del cliente.
     */
    public Optional<ConversationRouteResult> tryHandlePendingResponse(InboundMessage inbound, ConversationState state) {
        if (!isAwaitingFeedback(state)) {
            return Optional.empty();
        }
        String tenantId = InboundMetadata.tenantId(inbound);
        if (tenantId == null || tenantId.isBlank()) {
            clearFeedbackFlags(state);
            return Optional.empty();
        }

        Optional<Boolean> answer = InboundTextHeuristics.parseFeedbackYesNo(inbound.getText());
        if (answer.isEmpty()) {
            log.info("[FEEDBACK] Respuesta no reconocida conv={} text='{}'", inbound.getConversationId(), inbound.getText());
            return Optional.of(new ConversationRouteResult(
                OutboundMessage.builder()
                    .text(thanksUnclear)
                    .conversationId(inbound.getConversationId())
                    .tenantId(tenantId)
                    .build(),
                ConversationIntentSource.FEEDBACK,
                null
            ));
        }

        Map<String, Object> ctx = state.getContext();
        String snapshotUser = stringVal(ctx.get(ConversationContextKeys.FEEDBACK_SNAPSHOT_USER));
        String snapshotBot = stringVal(ctx.get(ConversationContextKeys.FEEDBACK_SNAPSHOT_BOT));
        String snapshotSource = stringVal(ctx.get(ConversationContextKeys.FEEDBACK_SNAPSHOT_SOURCE));
        String sessionId = ChatSessionService.sessionIdFrom(state);

        ConversationFeedbackRating rating = answer.get()
            ? ConversationFeedbackRating.POSITIVE
            : ConversationFeedbackRating.NEGATIVE;
        feedbackService.recordFeedback(
            tenantId,
            inbound.getConversationId(),
            sessionId,
            snapshotUser,
            snapshotBot,
            rating,
            snapshotSource
        );
        log.info("[FEEDBACK] Registrado {} conv={} tenant={}", rating, inbound.getConversationId(), tenantId);

        ConversationState cleared = clearFeedbackFlags(state);
        conversationRepository.save(cleared);

        String reply = answer.get() ? thanksPositive : thanksNegative;
        return Optional.of(new ConversationRouteResult(
            OutboundMessage.builder()
                .text(reply)
                .conversationId(inbound.getConversationId())
                .tenantId(tenantId)
                .build(),
            ConversationIntentSource.FEEDBACK,
            null
        ));
    }

    public record FeedbackPromptOutcome(OutboundMessage message, ConversationState state) {}

    /**
     * Tras una respuesta normal, si el usuario se despide, añade la pregunta de utilidad.
     */
    public FeedbackPromptOutcome maybeAppendEndOfConversationPrompt(String userText,
                                                                    OutboundMessage outbound,
                                                                    ConversationState state,
                                                                    String intentSource) {
        if (outbound == null || outbound.getText() == null || outbound.getText().isBlank()) {
            return new FeedbackPromptOutcome(outbound, state);
        }
        if (isAwaitingFeedback(state)) {
            return new FeedbackPromptOutcome(outbound, state);
        }
        if (!InboundTextHeuristics.looksLikeConversationClosing(userText)) {
            return new FeedbackPromptOutcome(outbound, state);
        }
        if (ConversationIntentSource.FEEDBACK.equals(intentSource)) {
            return new FeedbackPromptOutcome(outbound, state);
        }

        String botText = outbound.getText().strip();
        String combined = botText + "\n\n" + question;

        Map<String, Object> ctx = new HashMap<>(state.getContext());
        ctx.put(ConversationContextKeys.FEEDBACK_AWAITING, Boolean.TRUE);
        ctx.put(ConversationContextKeys.FEEDBACK_SNAPSHOT_USER, userText != null ? userText.strip() : "");
        ctx.put(ConversationContextKeys.FEEDBACK_SNAPSHOT_BOT, botText);
        ctx.put(ConversationContextKeys.FEEDBACK_SNAPSHOT_SOURCE,
            intentSource != null ? intentSource : ConversationIntentSource.ERROR);

        ConversationState updated = ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(state.getCurrentIntent())
            .context(ctx)
            .updatedAt(System.currentTimeMillis())
            .build();
        conversationRepository.save(updated);

        OutboundMessage withPrompt = OutboundMessage.builder()
            .text(combined)
            .conversationId(outbound.getConversationId())
            .tenantId(outbound.getTenantId())
            .build();
        log.info("[FEEDBACK] Pregunta de utilidad conv={}", state.getConversationId());
        return new FeedbackPromptOutcome(withPrompt, updated);
    }

    private ConversationState clearFeedbackFlags(ConversationState state) {
        Map<String, Object> ctx = new HashMap<>(state.getContext());
        ctx.remove(ConversationContextKeys.FEEDBACK_AWAITING);
        ctx.remove(ConversationContextKeys.FEEDBACK_SNAPSHOT_USER);
        ctx.remove(ConversationContextKeys.FEEDBACK_SNAPSHOT_BOT);
        ctx.remove(ConversationContextKeys.FEEDBACK_SNAPSHOT_SOURCE);
        return ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(state.getCurrentIntent())
            .context(ctx)
            .updatedAt(System.currentTimeMillis())
            .build();
    }

    private static String stringVal(Object o) {
        return o == null ? "" : o.toString();
    }

    private static String defaultText(String configured, String fallback) {
        return configured != null && !configured.isBlank() ? configured.strip() : fallback;
    }
}
