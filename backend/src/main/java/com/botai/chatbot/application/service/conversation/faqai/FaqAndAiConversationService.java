package com.botai.chatbot.application.service.conversation.faqai;

import com.botai.chatbot.application.dto.AiConversationRequest;
import com.botai.chatbot.application.dto.ConversationRouteResult;
import com.botai.chatbot.application.dto.FaqResolutionRequest;
import com.botai.chatbot.application.orchestration.ConversationHandlingContext;
import com.botai.chatbot.application.orchestration.ConversationMode;
import com.botai.chatbot.application.orchestration.ConversationModeHandler;
import com.botai.chatbot.application.prompt.BotPrompts;
import com.botai.chatbot.application.service.conversation.ai.RagLlmChatService;
import com.botai.chatbot.application.service.conversation.common.ConversationActionRouting;
import com.botai.chatbot.application.service.conversation.common.MenuNavigationService;
import com.botai.chatbot.application.service.conversation.common.MenuService;
import com.botai.chatbot.application.service.conversation.faq.FaqConversationService;
import com.botai.chatbot.application.support.InboundTextHeuristics;
import com.botai.chatbot.application.support.StandardRouteResponses;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Flujo <strong>FAQ + IA</strong> ({@link ConversationMode#FAQ_AND_AI}): turno completo aquí — como solo IA ante fallo
 * de clasificador/mala intención (LLM si IA activa), saludo→menú, CRM vía {@link ConversationActionRouting},
 * luego FAQ y si no hay match IA.
 */
@Service
public class FaqAndAiConversationService implements ConversationModeHandler {

    private static final Logger log = LoggerFactory.getLogger(FaqAndAiConversationService.class);

    private final FaqConversationService faqConversationService;
    private final RagLlmChatService ragLlmChatService;
    private final FeatureFlagService featureFlagService;
    private final ConversationActionRouting actionRouting;
    private final MenuService menuService;
    private final MenuNavigationService menuNavigationService;
    private final StandardRouteResponses standardRouteResponses;

    public FaqAndAiConversationService(FaqConversationService faqConversationService,
                                       RagLlmChatService ragLlmChatService,
                                       FeatureFlagService featureFlagService,
                                       ConversationActionRouting actionRouting,
                                       MenuService menuService,
                                       MenuNavigationService menuNavigationService,
                                       StandardRouteResponses standardRouteResponses) {
        this.faqConversationService = faqConversationService;
        this.ragLlmChatService = ragLlmChatService;
        this.featureFlagService = featureFlagService;
        this.actionRouting = actionRouting;
        this.menuService = menuService;
        this.menuNavigationService = menuNavigationService;
        this.standardRouteResponses = standardRouteResponses;
    }

    @Override
    public ConversationMode mode() {
        return ConversationMode.FAQ_AND_AI;
    }

    @Override
    public Optional<ConversationRouteResult> handle(ConversationHandlingContext ctx) {
        return whenClassifierFailedThenLlm(ctx)
            .or(() -> actionRouting.continueActiveActionIfAny(ctx))
            .or(() -> whenBadIntentThenLlm(ctx))
            .or(() -> whenGreetingOpenFirstMenu(ctx))
            .or(() -> actionRouting.startCrmFromClassificationIfEnabled(ctx))
            .or(() -> actionRouting.respondIfCrmIntentButActionsDisabled(ctx))
            .or(() -> {
                var faqReq = new FaqResolutionRequest(
                    ctx.conversationId(), ctx.tenantId(), ctx.text(), ctx.state(), true);
                return faqConversationService.resolve(faqReq)
                    .or(() -> ragLlmChatService.replyWithLlm(
                        AiConversationRequest.of(ctx.inbound(), ctx.state(), ctx.classification())));
            });
    }

    private Optional<ConversationRouteResult> whenClassifierFailedThenLlm(ConversationHandlingContext ctx) {
        if (!ctx.classification().isServiceError()) {
            return Optional.empty();
        }
        String tenantId = ctx.tenantId();
        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            log.warn("[FAQ+AI] Clasificador en error -> LLM");
            return ragLlmChatService.replyWithLlm(new AiConversationRequest(ctx.inbound(), ctx.state(), ctx.classification(),
                BotPrompts.RouterSupplement.classifierFailureLines()));
        }
        log.warn("[FAQ+AI] Clasificador en error -> mensaje fijo (IA off)");
        return Optional.of(standardRouteResponses.classifierUnavailable(ctx.conversationId(), tenantId));
    }

    private Optional<ConversationRouteResult> whenBadIntentThenLlm(ConversationHandlingContext ctx) {
        if (!ctx.classification().isBadIntent()) {
            return Optional.empty();
        }
        String tenantId = ctx.tenantId();
        if (featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tenantId)) {
            if (ctx.state() != null && ctx.state().hasIntent()
                && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(ctx.state().getCurrentIntent())
                && InboundTextHeuristics.looksLikeNoiseOrCorruptedContent(ctx.text())) {
                log.info("[FAQ+AI] Mala intencion con ruido/encoding en flujo cita -> LLM sin suplemento hostil");
                return ragLlmChatService.replyWithLlm(AiConversationRequest.of(ctx.inbound(), ctx.state(), ctx.classification()));
            }
            log.info("[FAQ+AI] Mala intencion -> LLM");
            return ragLlmChatService.replyWithLlm(new AiConversationRequest(ctx.inbound(), ctx.state(), ctx.classification(),
                BotPrompts.RouterSupplement.badIntentLines()));
        }
        log.info("[FAQ+AI] Mala intencion -> mensaje fijo (IA off)");
        return Optional.of(standardRouteResponses.badIntent(ctx.conversationId(), tenantId));
    }

    private Optional<ConversationRouteResult> whenGreetingOpenFirstMenu(ConversationHandlingContext ctx) {
        // No sustituir el flujo de cita (LLM/tools) por el menú de saludo.
        if (ctx.state() != null && ctx.state().hasIntent()
            && ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(ctx.state().getCurrentIntent())
            && featureFlagService.isEnabled(BotFeatures.AI_ENABLED, ctx.tenantId())) {
            return Optional.empty();
        }
        if (!ctx.classification().isGreeting()
            || !featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, ctx.tenantId())
            || !menuService.hasAnyActiveMenu(ctx.tenantId())) {
            return Optional.empty();
        }
        return menuService.getFirstMenuKey(ctx.tenantId())
            .flatMap(firstKey -> {
                log.info("[FAQ+AI] Saludo -> primer menu");
                return menuNavigationService.openMenu(ctx.conversationId(), ctx.tenantId(), firstKey);
            });
    }

}
