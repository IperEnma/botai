package com.botai.application.chatbot.service.conversation.faq;

import com.botai.application.chatbot.dto.ConversationIntentSource;
import com.botai.application.chatbot.dto.ConversationRouteResult;
import com.botai.application.chatbot.dto.FaqResolutionRequest;
import com.botai.application.chatbot.orchestration.ConversationHandlingContext;
import com.botai.application.chatbot.orchestration.ConversationMode;
import com.botai.application.chatbot.orchestration.ConversationModeHandler;
import com.botai.application.chatbot.service.conversation.common.ConversationActionRouting;
import com.botai.application.chatbot.service.conversation.common.FaqService;
import com.botai.application.chatbot.service.conversation.common.MenuNavigationService;
import com.botai.application.chatbot.service.conversation.common.MenuService;
import com.botai.application.chatbot.support.StandardRouteResponses;
import com.botai.domain.chatbot.ConversationContextKeys;
import com.botai.domain.chatbot.feature.BotFeatures;
import com.botai.domain.chatbot.feature.FeatureFlagService;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.OutboundMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Flujo <strong>solo FAQ/menú</strong> ({@link ConversationMode#FAQ_ONLY}): turno completo en este servicio —
 * fallo de clasificador y mala intención (mensajes fijos), saludo→primer menú, CRM vía {@link ConversationActionRouting},
 * y núcleo FAQ/menú. En modo FAQ+IA se reutiliza {@link #resolve} con {@code aiCompanionEnabled=true}.
 */
@Service
public class FaqConversationService implements ConversationModeHandler {

    private static final Logger log = LoggerFactory.getLogger(FaqConversationService.class);

    private final FeatureFlagService featureFlagService;
    private final FaqService faqService;
    private final MenuNavigationService menuNavigationService;
    private final MenuService menuService;
    private final ConversationActionRouting actionRouting;
    private final StandardRouteResponses standardRouteResponses;

    public FaqConversationService(FeatureFlagService featureFlagService,
                                  FaqService faqService,
                                  MenuNavigationService menuNavigationService,
                                  MenuService menuService,
                                  ConversationActionRouting actionRouting,
                                  StandardRouteResponses standardRouteResponses) {
        this.featureFlagService = featureFlagService;
        this.faqService = faqService;
        this.menuNavigationService = menuNavigationService;
        this.menuService = menuService;
        this.actionRouting = actionRouting;
        this.standardRouteResponses = standardRouteResponses;
    }

    @Override
    public ConversationMode mode() {
        return ConversationMode.FAQ_ONLY;
    }

    @Override
    public Optional<ConversationRouteResult> handle(ConversationHandlingContext ctx) {
        return whenClassifierFailedFaq(ctx)
            .or(() -> actionRouting.continueActiveActionIfAny(ctx))
            .or(() -> whenBadIntentFaq(ctx))
            .or(() -> whenGreetingOpenFirstMenu(ctx))
            .or(() -> actionRouting.startCrmFromClassificationIfEnabled(ctx))
            .or(() -> actionRouting.respondIfCrmIntentButActionsDisabled(ctx))
            .or(() -> resolve(new FaqResolutionRequest(
                ctx.conversationId(), ctx.tenantId(), ctx.text(), ctx.state(), false)));
    }

    private Optional<ConversationRouteResult> whenClassifierFailedFaq(ConversationHandlingContext ctx) {
        if (!ctx.classification().isServiceError()) {
            return Optional.empty();
        }
        log.warn("[FAQ] Clasificador en error -> mensaje fijo");
        return Optional.of(standardRouteResponses.classifierUnavailable(ctx.conversationId(), ctx.tenantId()));
    }

    private Optional<ConversationRouteResult> whenBadIntentFaq(ConversationHandlingContext ctx) {
        if (!ctx.classification().isBadIntent()) {
            return Optional.empty();
        }
        log.info("[FAQ] Mala intencion -> mensaje fijo");
        return Optional.of(standardRouteResponses.badIntent(ctx.conversationId(), ctx.tenantId()));
    }

    private Optional<ConversationRouteResult> whenGreetingOpenFirstMenu(ConversationHandlingContext ctx) {
        if (!ctx.classification().isGreeting()
            || !featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, ctx.tenantId())
            || !menuService.hasAnyActiveMenu(ctx.tenantId())) {
            return Optional.empty();
        }
        return menuService.getFirstMenuKey(ctx.tenantId())
            .flatMap(firstKey -> {
                log.info("[FAQ] Saludo -> primer menu");
                return menuNavigationService.openMenu(ctx.conversationId(), ctx.tenantId(), firstKey);
            });
    }

    /** FAQ con o sin compañía IA ({@code aiCompanionEnabled}) — solo el núcleo menú/keywords (el preludio híbrido va en {@link com.botai.application.chatbot.service.conversation.faqai.FaqAndAiConversationService}). */
    public Optional<ConversationRouteResult> resolve(FaqResolutionRequest req) {
        if (!featureFlagService.isEnabled(BotFeatures.FAQ_ENABLED, req.tenantId())) {
            return Optional.empty();
        }
        String conversationId = req.conversationId();
        String tenantId = req.tenantId();
        String text = req.text();
        ConversationState state = req.state();
        boolean aiCompanion = req.aiCompanionEnabled();
        String currentMenu = state.getContextValue(ConversationContextKeys.CURRENT_MENU, String.class);

        if (currentMenu != null) {
            Optional<ConversationRouteResult> inMenu = menuNavigationService.resolveWhileInMenu(
                conversationId, tenantId, text, state, currentMenu, aiCompanion);
            if (inMenu.isPresent()) {
                return inMenu;
            }
        }

        Optional<ConversationRouteResult> trigger = menuNavigationService.resolveByGlobalTrigger(conversationId, tenantId, text);
        if (trigger.isPresent()) {
            return trigger;
        }

        Optional<ConversationRouteResult> faqHit = matchFaqToResult(conversationId, tenantId, text);
        if (faqHit.isPresent()) {
            return faqHit;
        }

        if (currentMenu == null) {
            return menuNavigationService.showFirstMenuWhenNoCurrent(conversationId, tenantId);
        }

        return Optional.empty();
    }

    private Optional<ConversationRouteResult> matchFaqToResult(String conversationId, String tenantId, String text) {
        return faqService.findFixedMatch(text)
            .map(m -> {
                log.info("[FAQ-SVC] Keyword match (FIXED): {}", m.intent());
                return new ConversationRouteResult(
                    OutboundMessage.builder()
                        .text(m.response())
                        .conversationId(conversationId)
                        .tenantId(tenantId)
                        .build(),
                    ConversationIntentSource.FAQ,
                    null
                );
            });
    }
}
