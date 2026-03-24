package com.botai.chatbot.application.service.conversation.common;

import com.botai.chatbot.application.dto.ConversationIntentSource;
import com.botai.chatbot.application.service.inbound.ActionDispatcher;
import com.botai.chatbot.application.dto.ConversationRouteResult;
import com.botai.chatbot.domain.feature.BotFeatures;
import com.botai.chatbot.domain.feature.FeatureFlagService;
import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.infrastructure.config.BotMessages;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Optional;

/**
 * Navegación por menús (triggers, opción numérica, submenús, re-mostrar, pie con hint si IA está activa).
 * No responde FAQs por keywords — eso es {@link FaqService} /
 * {@link com.botai.chatbot.application.service.conversation.faq.FaqConversationService}.
 */
@Service
public class MenuNavigationService {

    private static final Logger log = LoggerFactory.getLogger(MenuNavigationService.class);

    private final FeatureFlagService featureFlagService;
    private final MenuService menuService;
    private final ActionDispatcher actionDispatcher;
    private final ConversationActionRouting conversationActionRouting;
    private final BotMessages messages;

    public MenuNavigationService(FeatureFlagService featureFlagService,
                                 MenuService menuService,
                                 ActionDispatcher actionDispatcher,
                                 ConversationActionRouting conversationActionRouting,
                                 BotMessages messages) {
        this.featureFlagService = featureFlagService;
        this.menuService = menuService;
        this.actionDispatcher = actionDispatcher;
        this.conversationActionRouting = conversationActionRouting;
        this.messages = messages;
    }

    public Optional<ConversationRouteResult> openMenu(String conversationId, String tenantId, String menuKey) {
        return menuService.getMenu(menuKey, conversationId, tenantId)
            .map(m -> withMenuHintIfAiEnabled(m, ConversationIntentSource.MENU, menuKey));
    }

    /**
     * Usuario ya está en un menú: opción, trigger, o re-mostrar primer menú si no hay IA de apoyo.
     */
    public Optional<ConversationRouteResult> resolveWhileInMenu(String conversationId, String tenantId, String text,
                                                                ConversationState state, String currentMenu,
                                                                boolean aiCompanionEnabled) {
        Optional<ConversationRouteResult> fromSelection = tryMenuSelection(conversationId, tenantId, text, state, currentMenu);
        if (fromSelection.isPresent()) return fromSelection;

        Optional<ConversationRouteResult> fromTrigger = tryMenuTrigger(conversationId, tenantId, text);
        if (fromTrigger.isPresent()) return fromTrigger;

        if (!aiCompanionEnabled && menuService.hasAnyActiveMenu(tenantId)) {
            return menuService.getFirstMenuKey(tenantId)
                .flatMap(k -> menuService.getMenu(k, conversationId, tenantId)
                    .map(m -> withMenuHintIfAiEnabled(m, ConversationIntentSource.MENU, k)));
        }
        return Optional.empty();
    }

    /** Trigger de palabra clave fuera del flujo “ya en menú” (p. ej. “menú”, “hola”). */
    public Optional<ConversationRouteResult> resolveByGlobalTrigger(String conversationId, String tenantId, String text) {
        return tryMenuTrigger(conversationId, tenantId, text);
    }

    /** Sin menú actual en contexto: mostrar el primer menú del tenant. */
    public Optional<ConversationRouteResult> showFirstMenuWhenNoCurrent(String conversationId, String tenantId) {
        if (!menuService.hasAnyActiveMenu(tenantId)) {
            return Optional.empty();
        }
        return menuService.getFirstMenuKey(tenantId)
            .flatMap(k -> menuService.getMenu(k, conversationId, tenantId)
                .map(m -> {
                    log.info("[MENU-NAV] Sin menu actual -> primer menu");
                    return withMenuHintIfAiEnabled(m, ConversationIntentSource.MENU, k);
                }));
    }

    private Optional<ConversationRouteResult> tryMenuSelection(String conversationId, String tenantId, String text,
                                                                ConversationState state, String currentMenu) {
        var selected = menuService.findSelectedOptionWithAction(currentMenu, text, tenantId);
        if (selected.isEmpty()) return Optional.empty();

        var sel = selected.get();
        if (sel.actionIntent() != null && !sel.actionIntent().isBlank()
            && featureFlagService.isEnabled(BotFeatures.ACTIONS_ENABLED, tenantId)) {
            if (ConversationActionRouting.BOOK_APPOINTMENT_ACTION_ID.equals(sel.actionIntent())
                && conversationActionRouting.armBookAppointmentForFluidAiIfApplicable(state, tenantId)) {
                log.info("[MENU-NAV] Opcion agendar + IA -> sin wizard; sigue el LLM con tools");
                return Optional.empty();
            }
            var actionResult = actionDispatcher.startFromMenuOption(state, sel.actionIntent(), text);
            if (actionResult != null) {
                log.info("[MENU-NAV] Opcion -> accion: {} -> {}", text, sel.actionIntent());
                return Optional.of(new ConversationRouteResult(actionResult, ConversationIntentSource.ACTION, null));
            }
        }
        String targetMenu = sel.targetMenuKey();
        log.info("[MENU-NAV] Opcion -> submenu: {} -> {}", text, targetMenu);
        return menuService.getMenu(targetMenu, conversationId, tenantId)
            .map(m -> withMenuHintIfAiEnabled(m, ConversationIntentSource.MENU, targetMenu));
    }

    private Optional<ConversationRouteResult> tryMenuTrigger(String conversationId, String tenantId, String text) {
        return menuService.findMenuTrigger(text, tenantId)
            .flatMap(menuId -> {
                log.info("[MENU-NAV] Trigger: {} -> {}", text, menuId);
                return menuService.getMenu(menuId, conversationId, tenantId)
                    .map(m -> withMenuHintIfAiEnabled(m, ConversationIntentSource.MENU, menuId));
            });
    }

    private ConversationRouteResult withMenuHintIfAiEnabled(OutboundMessage menuMessage, String intentSource, String newMenuId) {
        String tid = menuMessage.getTenantId() != null ? menuMessage.getTenantId() : "";
        if (!featureFlagService.isEnabled(BotFeatures.AI_ENABLED, tid)) {
            return new ConversationRouteResult(menuMessage, intentSource, newMenuId);
        }
        OutboundMessage withHint = OutboundMessage.builder()
            .text(menuMessage.getText())
            .options(menuMessage.getOptions())
            .footerText(messages.getAiHint())
            .conversationId(menuMessage.getConversationId())
            .tenantId(menuMessage.getTenantId())
            .build();
        return new ConversationRouteResult(withHint, intentSource, newMenuId);
    }
}
