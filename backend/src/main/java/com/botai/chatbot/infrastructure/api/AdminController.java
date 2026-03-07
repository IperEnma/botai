package com.botai.chatbot.infrastructure.api;

import com.botai.chatbot.infrastructure.persistence.entity.*;
import com.botai.chatbot.infrastructure.persistence.jpa.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class AdminController {

    private final MenuJpaRepository menuRepository;
    private final MenuTriggerJpaRepository triggerRepository;
    private final KnowledgeChunkJpaRepository knowledgeRepository;
    private final FeatureConfigJpaRepository featureConfigRepository;
    private final BotJpaRepository botRepository;

    public AdminController(
            MenuJpaRepository menuRepository,
            MenuTriggerJpaRepository triggerRepository,
            KnowledgeChunkJpaRepository knowledgeRepository,
            FeatureConfigJpaRepository featureConfigRepository,
            BotJpaRepository botRepository) {
        this.menuRepository = menuRepository;
        this.triggerRepository = triggerRepository;
        this.knowledgeRepository = knowledgeRepository;
        this.featureConfigRepository = featureConfigRepository;
        this.botRepository = botRepository;
    }

    // ============ AUTH ============
    
    @PostMapping("/auth/google")
    public ResponseEntity<?> authenticateWithGoogle(@RequestBody Map<String, String> payload) {
        String idToken = payload.get("idToken");
        // TODO: Validate Google ID token and create/get user
        // For now, return mock user
        return ResponseEntity.ok(Map.of(
            "id", "user_" + System.currentTimeMillis(),
            "email", "user@example.com",
            "name", "Usuario Demo",
            "accessToken", "demo_token_" + System.currentTimeMillis()
        ));
    }

    // ============ BOTS ============

    @GetMapping("/bots")
    public ResponseEntity<List<BotEntity>> getBots(
            @RequestHeader(value = "Authorization", required = false) String auth) {
        // TODO: Extract userId from token
        // For now, return all bots
        List<BotEntity> bots = botRepository.findAll();
        return ResponseEntity.ok(bots);
    }

    @PostMapping("/bots")
    public ResponseEntity<BotEntity> createBot(@RequestBody BotEntity bot) {
        if (bot.getTenantId() == null || bot.getTenantId().isEmpty()) {
            bot.setTenantId(UUID.randomUUID().toString());
        }
        if (bot.getUserId() == null || bot.getUserId().isEmpty()) {
            bot.setUserId("default_user");
        }
        bot.setCreatedAt(LocalDateTime.now());
        BotEntity saved = botRepository.save(bot);
        String tenantId = saved.getTenantId();

        createDefaultFeatureFlags(tenantId, saved);
        createDefaultMenusAndTriggers(tenantId);

        return ResponseEntity.ok(saved);
    }

    /**
     * Crea menú principal y triggers para el tenant del bot, para que "Hola" / "menu" muestren el menú.
     */
    private void createDefaultMenusAndTriggers(String tenantId) {
        if (tenantId == null || tenantId.isBlank()) return;

        if (menuRepository.findByTenantIdAndMenuKeyAndActiveTrue(tenantId, "main").isPresent()) {
            return;
        }

        MenuEntity main = new MenuEntity();
        main.setTenantId(tenantId);
        main.setMenuKey("main");
        main.setText("¡Hola! 👋 ¿En qué puedo ayudarte?");
        main.setActive(true);
        main = menuRepository.save(main);

        MenuOptionEntity opt1 = new MenuOptionEntity();
        opt1.setMenu(main);
        opt1.setOptionKey("1");
        opt1.setTargetMenuKey("servicios");
        opt1.setLabel("🦷 Ver servicios");
        opt1.setSortOrder(1);
        main.getOptions().add(opt1);

        MenuEntity servicios = new MenuEntity();
        servicios.setTenantId(tenantId);
        servicios.setMenuKey("servicios");
        servicios.setText("🦷 Nuestros servicios. Selecciona una opción o escribe 0 para volver.");
        servicios.setActive(true);
        servicios = menuRepository.save(servicios);

        MenuOptionEntity back = new MenuOptionEntity();
        back.setMenu(servicios);
        back.setOptionKey("0");
        back.setTargetMenuKey("main");
        back.setLabel("⬅️ Volver");
        back.setSortOrder(1);
        servicios.getOptions().add(back);
        menuRepository.save(servicios);

        final MenuEntity mainMenu = main;
        mainMenu.getOptions().forEach(o -> o.setMenu(mainMenu));
        menuRepository.save(main);

        for (String word : new String[]{"hola", "menu", "buenas", "inicio", "hey", "empezar"}) {
            if (triggerRepository.findByTenantId(tenantId).stream()
                    .anyMatch(t -> word.equalsIgnoreCase(t.getTriggerWord()))) continue;
            MenuTriggerEntity trigger = new MenuTriggerEntity();
            trigger.setTenantId(tenantId);
            trigger.setTriggerWord(word);
            trigger.setMenuKey("main");
            triggerRepository.save(trigger);
        }
    }

    @GetMapping("/bots/{botId}")
    public ResponseEntity<BotEntity> getBot(@PathVariable Long botId) {
        return botRepository.findById(botId)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PutMapping("/bots/{botId}")
    public ResponseEntity<BotEntity> updateBot(
            @PathVariable Long botId,
            @RequestBody BotEntity bot) {
        return botRepository.findById(botId)
            .map(existing -> {
                existing.setName(bot.getName());
                existing.setDescription(bot.getDescription());
                existing.setTier(bot.getTier());
                existing.setFaqEnabled(bot.isFaqEnabled());
                existing.setAiEnabled(bot.isAiEnabled());
                existing.setActionsEnabled(bot.isActionsEnabled());
                existing.setWhatsappPhoneNumberId(bot.getWhatsappPhoneNumberId());
                existing.setWhatsappAccessToken(bot.getWhatsappAccessToken());
                existing.setWhatsappVerifyToken(bot.getWhatsappVerifyToken());
                
                updateFeatureFlags(existing.getTenantId(), existing);
                
                return ResponseEntity.ok(botRepository.save(existing));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/bots/{botId}")
    public ResponseEntity<Void> deleteBot(@PathVariable Long botId) {
        botRepository.deleteById(botId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Crea menú principal y triggers para un bot ya existente (si aún no tiene).
     */
    @PostMapping("/bots/{botId}/seed-menus")
    public ResponseEntity<?> seedBotMenus(@PathVariable Long botId) {
        return botRepository.findById(botId)
            .map(bot -> {
                createDefaultMenusAndTriggers(bot.getTenantId());
                return ResponseEntity.ok(Map.of("status", "ok", "message", "Menús y triggers creados para el tenant del bot"));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    private void createDefaultFeatureFlags(String tenantId, BotEntity bot) {
        createOrUpdateFeature(tenantId, "FAQ_ENABLED", bot.isFaqEnabled());
        createOrUpdateFeature(tenantId, "AI_ENABLED", bot.isAiEnabled());
        createOrUpdateFeature(tenantId, "ACTIONS_ENABLED", bot.isActionsEnabled());
    }

    private void updateFeatureFlags(String tenantId, BotEntity bot) {
        org.slf4j.LoggerFactory.getLogger(AdminController.class).info(
            "[BOT] Updating feature flags for tenant={}: FAQ={}, AI={}, ACTIONS={}",
            tenantId, bot.isFaqEnabled(), bot.isAiEnabled(), bot.isActionsEnabled());
        createOrUpdateFeature(tenantId, "FAQ_ENABLED", bot.isFaqEnabled());
        createOrUpdateFeature(tenantId, "AI_ENABLED", bot.isAiEnabled());
        createOrUpdateFeature(tenantId, "ACTIONS_ENABLED", bot.isActionsEnabled());
    }

    private void createOrUpdateFeature(String tenantId, String featureKey, boolean enabled) {
        var existing = featureConfigRepository.findByTenantIdAndFeatureKey(tenantId, featureKey);
        if (existing.isPresent()) {
            var config = existing.get();
            config.setEnabled(enabled);
            featureConfigRepository.save(config);
        } else {
            var config = new FeatureConfigEntity();
            config.setTenantId(tenantId);
            config.setFeatureKey(featureKey);
            config.setEnabled(enabled);
            featureConfigRepository.save(config);
        }
    }

    // ============ MENUS ============

    @GetMapping("/tenants/{tenantId}/menus")
    public ResponseEntity<List<MenuEntity>> getMenus(@PathVariable String tenantId) {
        List<MenuEntity> menus = menuRepository.findByTenantIdAndActiveTrue(tenantId);
        return ResponseEntity.ok(menus);
    }

    @PostMapping("/tenants/{tenantId}/menus")
    public ResponseEntity<MenuEntity> createMenu(
            @PathVariable String tenantId,
            @RequestBody MenuEntity menu) {
        menu.setTenantId(tenantId);
        menu.setActive(true);
        if (menu.getOptions() != null) {
            menu.getOptions().forEach(opt -> opt.setMenu(menu));
        }
        MenuEntity saved = menuRepository.save(menu);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/tenants/{tenantId}/menus/{menuId}")
    public ResponseEntity<MenuEntity> updateMenu(
            @PathVariable String tenantId,
            @PathVariable Long menuId,
            @RequestBody MenuEntity menu) {
        return menuRepository.findById(menuId)
            .map(existing -> {
                existing.setText(menu.getText());
                existing.setMenuKey(menu.getMenuKey());
                existing.setActive(menu.isActive());
                existing.getOptions().clear();
                if (menu.getOptions() != null) {
                    menu.getOptions().forEach(opt -> {
                        opt.setMenu(existing);
                        existing.getOptions().add(opt);
                    });
                }
                return ResponseEntity.ok(menuRepository.save(existing));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/tenants/{tenantId}/menus/{menuId}")
    public ResponseEntity<Void> deleteMenu(
            @PathVariable String tenantId,
            @PathVariable Long menuId) {
        menuRepository.deleteById(menuId);
        return ResponseEntity.noContent().build();
    }

    // ============ TRIGGERS ============

    @GetMapping("/tenants/{tenantId}/triggers")
    public ResponseEntity<List<MenuTriggerEntity>> getTriggers(@PathVariable String tenantId) {
        List<MenuTriggerEntity> triggers = triggerRepository.findByTenantId(tenantId);
        return ResponseEntity.ok(triggers);
    }

    @PostMapping("/tenants/{tenantId}/triggers")
    public ResponseEntity<MenuTriggerEntity> createTrigger(
            @PathVariable String tenantId,
            @RequestBody MenuTriggerEntity trigger) {
        trigger.setTenantId(tenantId);
        MenuTriggerEntity saved = triggerRepository.save(trigger);
        return ResponseEntity.ok(saved);
    }

    @DeleteMapping("/tenants/{tenantId}/triggers/{triggerId}")
    public ResponseEntity<Void> deleteTrigger(
            @PathVariable String tenantId,
            @PathVariable Long triggerId) {
        triggerRepository.deleteById(triggerId);
        return ResponseEntity.noContent().build();
    }

    // ============ KNOWLEDGE (RAG) ============

    @GetMapping("/tenants/{tenantId}/knowledge")
    public ResponseEntity<List<KnowledgeChunkEntity>> getKnowledge(@PathVariable String tenantId) {
        List<KnowledgeChunkEntity> chunks = knowledgeRepository.findByTenantIdAndActiveTrue(tenantId);
        return ResponseEntity.ok(chunks);
    }

    @PostMapping("/tenants/{tenantId}/knowledge")
    public ResponseEntity<KnowledgeChunkEntity> createKnowledge(
            @PathVariable String tenantId,
            @RequestBody KnowledgeChunkEntity chunk) {
        chunk.setTenantId(tenantId);
        chunk.setActive(true);
        KnowledgeChunkEntity saved = knowledgeRepository.save(chunk);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/tenants/{tenantId}/knowledge/{chunkId}")
    public ResponseEntity<KnowledgeChunkEntity> updateKnowledge(
            @PathVariable String tenantId,
            @PathVariable Long chunkId,
            @RequestBody KnowledgeChunkEntity chunk) {
        return knowledgeRepository.findById(chunkId)
            .map(existing -> {
                existing.setTopic(chunk.getTopic());
                existing.setContent(chunk.getContent());
                existing.setKeywords(chunk.getKeywords());
                existing.setActive(chunk.isActive());
                return ResponseEntity.ok(knowledgeRepository.save(existing));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/tenants/{tenantId}/knowledge/{chunkId}")
    public ResponseEntity<Void> deleteKnowledge(
            @PathVariable String tenantId,
            @PathVariable Long chunkId) {
        knowledgeRepository.deleteById(chunkId);
        return ResponseEntity.noContent().build();
    }

    // ============ FEATURE FLAGS ============

    @GetMapping("/tenants/{tenantId}/features")
    public ResponseEntity<List<FeatureConfigEntity>> getFeatures(@PathVariable String tenantId) {
        List<FeatureConfigEntity> features = featureConfigRepository.findAll().stream()
            .filter(f -> f.getTenantId().equals(tenantId))
            .toList();
        return ResponseEntity.ok(features);
    }

    @PutMapping("/tenants/{tenantId}/features/{featureKey}")
    public ResponseEntity<?> updateFeature(
            @PathVariable String tenantId,
            @PathVariable String featureKey,
            @RequestBody Map<String, Boolean> payload) {
        Boolean enabled = payload.get("enabled");
        if (enabled == null) {
            return ResponseEntity.badRequest().body("Missing 'enabled' field");
        }
        
        var existing = featureConfigRepository.findByTenantIdAndFeatureKey(tenantId, featureKey);
        if (existing.isPresent()) {
            var config = existing.get();
            config.setEnabled(enabled);
            return ResponseEntity.ok(featureConfigRepository.save(config));
        } else {
            var config = new FeatureConfigEntity();
            config.setTenantId(tenantId);
            config.setFeatureKey(featureKey);
            config.setEnabled(enabled);
            return ResponseEntity.ok(featureConfigRepository.save(config));
        }
    }
}
