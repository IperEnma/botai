package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.infrastructure.persistence.entity.MenuEntity;
import com.botai.chatbot.infrastructure.persistence.entity.MenuOptionEntity;
import com.botai.chatbot.infrastructure.persistence.entity.MenuTriggerEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.MenuJpaRepository;
import com.botai.chatbot.infrastructure.persistence.jpa.MenuTriggerJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Canal-agnostic menu system. Reads menus from DB (multi-tenant).
 * Channel adapters render options in their own format (buttons, text, etc.)
 */
@Service
public class MenuService {

    private static final Logger log = LoggerFactory.getLogger(MenuService.class);

    private final MenuJpaRepository menuRepository;
    private final MenuTriggerJpaRepository triggerRepository;

    public MenuService(MenuJpaRepository menuRepository, MenuTriggerJpaRepository triggerRepository) {
        this.menuRepository = menuRepository;
        this.triggerRepository = triggerRepository;
    }

    /**
     * Exige tenantId no nulo ni vacío. Si no viene, falla rápido.
     */
    private static String requireTenant(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) {
            throw new IllegalArgumentException("tenantId is required");
        }
        return tenantId;
    }

    /**
     * Comprueba si el texto dispara un menú (ej. "hola" → main).
     * Solo hace match cuando el mensaje es básicamente solo esa palabra (no frases que la contengan),
     * para que preguntas como "hola, ¿cuánto cuesta?" vayan a la IA (Capa 2) y no al menú.
     */
    public Optional<String> findMenuTrigger(String text, String tenantId) {
        if (text == null) return Optional.empty();
        String normalized = text.toLowerCase().trim();
        if (normalized.isEmpty()) return Optional.empty();
        String tenant = requireTenant(tenantId);
        for (MenuTriggerEntity trigger : triggerRepository.findByTenantId(tenant)) {
            String word = trigger.getTriggerWord().toLowerCase();
            if (isOnlyTriggerWord(normalized, word)) {
                log.debug("[MENU] Trigger match: '{}' -> menu '{}'", trigger.getTriggerWord(), trigger.getMenuKey());
                return Optional.of(trigger.getMenuKey());
            }
        }
        return Optional.empty();
    }

    /** True si el mensaje es solo la palabra del trigger (con espacios/puntuación opcionales al final). */
    private static boolean isOnlyTriggerWord(String normalized, String triggerWord) {
        if (triggerWord.isEmpty()) return false;
        if (normalized.equals(triggerWord)) return true;
        if (!normalized.startsWith(triggerWord)) return false;
        String rest = normalized.substring(triggerWord.length()).trim();
        return rest.isEmpty() || rest.matches("^[!?\\.,\\-]+$");
    }

    /**
     * Comprueba si el texto es una opción del menú actual (ej. "1", "2"). Solo usa datos del tenant del bot.
     */
    public Optional<String> findSelectedOption(String currentMenuKey, String text, String tenantId) {
        if (currentMenuKey == null || text == null) return Optional.empty();
        String tenant = requireTenant(tenantId);
        Optional<MenuEntity> menuOpt = menuRepository.findByTenantIdAndMenuKeyAndActiveTrue(tenant, currentMenuKey);
        if (menuOpt.isEmpty()) return Optional.empty();
        String normalized = text.trim();
        for (MenuOptionEntity opt : menuOpt.get().getOptions()) {
            if (opt.getOptionKey().equals(normalized)) {
                log.debug("[MENU] Option selected: '{}' -> menu '{}'", opt.getOptionKey(), opt.getTargetMenuKey());
                return Optional.of(opt.getTargetMenuKey());
            }
        }
        return Optional.empty();
    }

    /**
     * Obtiene un menú por clave para el tenant. Solo datos de ese tenant.
     */
    public Optional<OutboundMessage> getMenu(String menuKey, String conversationId, String tenantId) {
        String tenant = requireTenant(tenantId);
        Optional<MenuEntity> menuOpt = menuRepository.findByTenantIdAndMenuKeyAndActiveTrue(tenant, menuKey);
        if (menuOpt.isEmpty()) {
            log.warn("[MENU] Menu not found: tenant={}, key={}", tenant, menuKey);
            return Optional.empty();
        }
        MenuEntity menu = menuOpt.get();
        List<String> optionLabels = menu.getOptions().stream()
            .map(o -> o.getOptionKey() + ". " + o.getLabel())
            .toList();
        return Optional.of(OutboundMessage.builder()
            .text(menu.getText())
            .options(optionLabels)
            .conversationId(conversationId)
            .tenantId(tenant)
            .build());
    }

    public boolean hasMenu(String menuKey, String tenantId) {
        return menuRepository.findByTenantIdAndMenuKeyAndActiveTrue(requireTenant(tenantId), menuKey).isPresent();
    }
}
