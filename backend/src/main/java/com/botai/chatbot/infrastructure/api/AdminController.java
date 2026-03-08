package com.botai.chatbot.infrastructure.api;

import com.botai.chatbot.infrastructure.persistence.entity.*;
import com.botai.chatbot.infrastructure.persistence.jpa.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.ArrayList;
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
    private final BusinessHoursJpaRepository businessHoursRepository;
    private final ServiceJpaRepository serviceRepository;
    private final AppointmentJpaRepository appointmentRepository;

    public AdminController(
            MenuJpaRepository menuRepository,
            MenuTriggerJpaRepository triggerRepository,
            KnowledgeChunkJpaRepository knowledgeRepository,
            FeatureConfigJpaRepository featureConfigRepository,
            BotJpaRepository botRepository,
            BusinessHoursJpaRepository businessHoursRepository,
            ServiceJpaRepository serviceRepository,
            AppointmentJpaRepository appointmentRepository) {
        this.menuRepository = menuRepository;
        this.triggerRepository = triggerRepository;
        this.knowledgeRepository = knowledgeRepository;
        this.featureConfigRepository = featureConfigRepository;
        this.botRepository = botRepository;
        this.businessHoursRepository = businessHoursRepository;
        this.serviceRepository = serviceRepository;
        this.appointmentRepository = appointmentRepository;
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
        // No se crean menús ni servicios por defecto: el dueño debe configurar todo en el panel.

        return ResponseEntity.ok(saved);
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
        org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(AdminController.class);
        log.info("[BOT] PUT /bots/{} recibido: whatsappPhoneNumberId en body={} (vacío={})", botId, bot.getWhatsappPhoneNumberId() != null ? "***" + (bot.getWhatsappPhoneNumberId().length() >= 4 ? bot.getWhatsappPhoneNumberId().substring(bot.getWhatsappPhoneNumberId().length() - 4) : "set") : "null", bot.getWhatsappPhoneNumberId() == null || bot.getWhatsappPhoneNumberId().isEmpty());
        return botRepository.findById(botId)
            .map(existing -> {
                existing.setName(bot.getName());
                existing.setDescription(bot.getDescription());
                existing.setTier(bot.getTier());
                existing.setFaqEnabled(bot.isFaqEnabled());
                existing.setAiEnabled(bot.isAiEnabled());
                existing.setActionsEnabled(bot.isActionsEnabled());
                existing.setWhatsappPhoneNumberId(trimToNull(bot.getWhatsappPhoneNumberId()));
                existing.setWhatsappAccessToken(trimToNull(bot.getWhatsappAccessToken()));
                existing.setWhatsappVerifyToken(trimToNull(bot.getWhatsappVerifyToken()));
                String ph = existing.getWhatsappPhoneNumberId();
                log.info("[BOT] Update bot id={} tenant={} whatsappPhoneNumberId guardado={}", botId, existing.getTenantId(), ph != null && !ph.isEmpty() ? "***" + (ph.length() >= 4 ? ph.substring(ph.length() - 4) : ph) : "null");
                updateFeatureFlags(existing.getTenantId(), existing);
                BotEntity saved = botRepository.save(existing);
                BotEntity refetched = botRepository.findById(botId).orElse(null);
                if (refetched != null) {
                    String refetchedPh = refetched.getWhatsappPhoneNumberId();
                    log.info("[BOT] Tras guardar, refetch bot id={}: whatsappPhoneNumberId en BD={}", botId, refetchedPh != null && !refetchedPh.isEmpty() ? "***" + (refetchedPh.length() >= 4 ? refetchedPh.substring(refetchedPh.length() - 4) : refetchedPh) : "null");
                }
                return ResponseEntity.ok(saved);
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/bots/{botId}")
    public ResponseEntity<Void> deleteBot(@PathVariable Long botId) {
        botRepository.deleteById(botId);
        return ResponseEntity.noContent().build();
    }

    private static String trimToNull(String value) {
        if (value == null) return null;
        String s = value.strip();
        return s.isEmpty() ? null : s;
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
        if (menu.getOptions() == null) {
            menu.setOptions(new ArrayList<>());
        }
        menu.getOptions().forEach(opt -> opt.setMenu(menu));
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
                List<MenuOptionEntity> newOptions = new ArrayList<>();
                if (menu.getOptions() != null) {
                    for (MenuOptionEntity opt : menu.getOptions()) {
                        MenuOptionEntity newOpt = new MenuOptionEntity();
                        newOpt.setMenu(existing);
                        newOpt.setOptionKey(opt.getOptionKey());
                        newOpt.setTargetMenuKey(opt.getTargetMenuKey());
                        newOpt.setLabel(opt.getLabel());
                        newOpt.setSortOrder(opt.getSortOrder());
                        newOpt.setActionIntent(opt.getActionIntent());
                        newOptions.add(newOpt);
                    }
                }
                existing.setOptions(newOptions);
                MenuEntity saved = menuRepository.save(existing);
                return ResponseEntity.ok(saved);
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

    // ============ HORARIO DEL NEGOCIO ============
    // dayOfWeek: 1=Lunes .. 7=Domingo. openTime/closeTime "09:00", "18:00"; null = cerrado

    @GetMapping("/tenants/{tenantId}/business-hours")
    public ResponseEntity<List<BusinessHoursEntity>> getBusinessHours(@PathVariable String tenantId) {
        return ResponseEntity.ok(businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId));
    }

    @PutMapping("/tenants/{tenantId}/business-hours")
    public ResponseEntity<List<BusinessHoursEntity>> saveBusinessHours(
            @PathVariable String tenantId,
            @RequestBody List<Map<String, Object>> body) {
        businessHoursRepository.deleteByTenantId(tenantId);
        for (Map<String, Object> row : body) {
            Number dayNum = (Number) row.get("dayOfWeek");
            if (dayNum == null) continue;
            int day = dayNum.intValue();
            if (day < 1 || day > 7) continue;
            String open = row.get("openTime") != null ? row.get("openTime").toString().trim() : null;
            String close = row.get("closeTime") != null ? row.get("closeTime").toString().trim() : null;
            if (open != null && open.isEmpty()) open = null;
            if (close != null && close.isEmpty()) close = null;
            BusinessHoursEntity e = new BusinessHoursEntity();
            e.setTenantId(tenantId);
            e.setDayOfWeek(day);
            e.setOpenTime(open);
            e.setCloseTime(close);
            businessHoursRepository.save(e);
        }
        return ResponseEntity.ok(businessHoursRepository.findByTenantIdOrderByDayOfWeek(tenantId));
    }

    // ============ SERVICIOS DEL NEGOCIO ============

    @GetMapping("/tenants/{tenantId}/services")
    public ResponseEntity<List<ServiceEntity>> getServices(@PathVariable String tenantId) {
        return ResponseEntity.ok(serviceRepository.findByTenantIdOrderBySortOrderAsc(tenantId));
    }

    @PostMapping("/tenants/{tenantId}/services")
    public ResponseEntity<ServiceEntity> createService(
            @PathVariable String tenantId,
            @RequestBody Map<String, Object> body) {
        ServiceEntity e = new ServiceEntity();
        e.setTenantId(tenantId);
        e.setName(body.get("name") != null ? body.get("name").toString() : "");
        e.setSortOrder(body.get("sortOrder") != null ? ((Number) body.get("sortOrder")).intValue() : 0);
        e.setActive(true);
        return ResponseEntity.ok(serviceRepository.save(e));
    }

    @PutMapping("/tenants/{tenantId}/services/{serviceId}")
    public ResponseEntity<ServiceEntity> updateService(
            @PathVariable String tenantId,
            @PathVariable Long serviceId,
            @RequestBody Map<String, Object> body) {
        return serviceRepository.findById(serviceId)
            .filter(s -> tenantId.equals(s.getTenantId()))
            .map(s -> {
                if (body.get("name") != null) s.setName(body.get("name").toString());
                if (body.get("sortOrder") != null) s.setSortOrder(((Number) body.get("sortOrder")).intValue());
                if (body.get("active") != null) s.setActive(Boolean.TRUE.equals(body.get("active")));
                return ResponseEntity.ok(serviceRepository.save(s));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/tenants/{tenantId}/services/{serviceId}")
    public ResponseEntity<Void> deleteService(
            @PathVariable String tenantId,
            @PathVariable Long serviceId) {
        if (serviceRepository.findById(serviceId).filter(s -> tenantId.equals(s.getTenantId())).isPresent()) {
            serviceRepository.deleteById(serviceId);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }

    // ============ CITAS / AGENDA ============

    @GetMapping("/tenants/{tenantId}/appointments")
    public ResponseEntity<List<AppointmentEntity>> getAppointments(
            @PathVariable String tenantId,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to) {
        LocalDate start = from != null && !from.isBlank() ? LocalDate.parse(from) : LocalDate.now();
        LocalDate end = to != null && !to.isBlank() ? LocalDate.parse(to) : start.plusMonths(1);
        List<AppointmentEntity> list = appointmentRepository.findByTenantIdAndAppointmentDateBetweenOrderByAppointmentTimeAsc(tenantId, start, end);
        return ResponseEntity.ok(list);
    }

    @PostMapping("/tenants/{tenantId}/appointments")
    public ResponseEntity<?> createAppointment(
            @PathVariable String tenantId,
            @RequestBody Map<String, Object> body) {
        String customerDocument = body.get("customerDocument") != null ? body.get("customerDocument").toString().strip() : "";
        if (customerDocument.isEmpty()) {
            return ResponseEntity.badRequest().body(
                Map.of("error", "customerDocument es obligatorio para mantener el expediente del usuario."));
        }
        AppointmentEntity e = new AppointmentEntity();
        e.setTenantId(tenantId);
        e.setCustomerName(body.get("customerName") != null ? body.get("customerName").toString().trim() : "");
        e.setCustomerDocument(customerDocument);
        e.setServiceName(body.get("serviceName") != null ? body.get("serviceName").toString().trim() : "");
        e.setAppointmentDate(body.get("appointmentDate") != null ? LocalDate.parse(body.get("appointmentDate").toString()) : LocalDate.now());
        e.setAppointmentTime(body.get("appointmentTime") != null ? body.get("appointmentTime").toString().trim() : "09:00");
        e.setStatus("scheduled");
        return ResponseEntity.ok(appointmentRepository.save(e));
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
