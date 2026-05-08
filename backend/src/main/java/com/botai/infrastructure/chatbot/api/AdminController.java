package com.botai.infrastructure.chatbot.api;

import com.botai.application.chatbot.service.admin.BusinessHoursAdminService;
import com.botai.application.chatbot.service.admin.BusinessServiceAdminService;
import com.botai.application.chatbot.service.knowledge.KnowledgeChunkAdminService;
import com.botai.infrastructure.chatbot.booking.CustomerDocumentNormalizer;
import com.botai.infrastructure.chatbot.persistence.entity.*;
import com.botai.infrastructure.chatbot.persistence.jpa.*;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.ArrayList;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class AdminController {

    private final MenuJpaRepository menuRepository;
    private final MenuTriggerJpaRepository triggerRepository;
    private final FeatureConfigJpaRepository featureConfigRepository;
    private final BotJpaRepository botRepository;
    private final BusinessHoursAdminService businessHoursAdminService;
    private final BusinessServiceAdminService businessServiceAdminService;
    private final KnowledgeChunkAdminService knowledgeChunkAdminService;
    private final AppointmentJpaRepository appointmentRepository;

    public AdminController(
            MenuJpaRepository menuRepository,
            MenuTriggerJpaRepository triggerRepository,
            FeatureConfigJpaRepository featureConfigRepository,
            BotJpaRepository botRepository,
            BusinessHoursAdminService businessHoursAdminService,
            BusinessServiceAdminService businessServiceAdminService,
            KnowledgeChunkAdminService knowledgeChunkAdminService,
            AppointmentJpaRepository appointmentRepository) {
        this.menuRepository = menuRepository;
        this.triggerRepository = triggerRepository;
        this.featureConfigRepository = featureConfigRepository;
        this.botRepository = botRepository;
        this.businessHoursAdminService = businessHoursAdminService;
        this.businessServiceAdminService = businessServiceAdminService;
        this.knowledgeChunkAdminService = knowledgeChunkAdminService;
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
        return ResponseEntity.ok(businessHoursAdminService.getByTenant(tenantId));
    }

    @PutMapping("/tenants/{tenantId}/business-hours")
    public ResponseEntity<List<BusinessHoursEntity>> saveBusinessHours(
            @PathVariable String tenantId,
            @RequestBody List<Map<String, Object>> body) {
        return ResponseEntity.ok(businessHoursAdminService.save(tenantId, body));
    }

    // ============ SERVICIOS DEL NEGOCIO ============

    @GetMapping("/tenants/{tenantId}/services")
    public ResponseEntity<List<ServiceEntity>> getServices(@PathVariable String tenantId) {
        return ResponseEntity.ok(businessServiceAdminService.getByTenant(tenantId));
    }

    @PostMapping("/tenants/{tenantId}/services")
    public ResponseEntity<ServiceEntity> createService(
            @PathVariable String tenantId,
            @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(businessServiceAdminService.create(tenantId, body));
    }

    @PutMapping("/tenants/{tenantId}/services/{serviceId}")
    public ResponseEntity<ServiceEntity> updateService(
            @PathVariable String tenantId,
            @PathVariable Long serviceId,
            @RequestBody Map<String, Object> body) {
        return businessServiceAdminService.update(tenantId, serviceId, body)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/tenants/{tenantId}/services/{serviceId}")
    public ResponseEntity<Void> deleteService(
            @PathVariable String tenantId,
            @PathVariable Long serviceId) {
        return businessServiceAdminService.delete(tenantId, serviceId)
            ? ResponseEntity.noContent().build()
            : ResponseEntity.notFound().build();
    }

    // ============ CITAS / AGENDA ============

    /**
     * Lista citas en rango. Por defecto {@code includeCancelled=false}: solo activas ({@code scheduled}),
     * para que las canceladas desde el chat (status {@code cancelled}) no sigan apareciendo como agenda viva.
     */
    @GetMapping("/tenants/{tenantId}/appointments")
    public ResponseEntity<List<AppointmentEntity>> getAppointments(
            @PathVariable String tenantId,
            @RequestParam(required = false) String from,
            @RequestParam(required = false) String to,
            @RequestParam(required = false, defaultValue = "false") boolean includeCancelled,
            @RequestParam(required = false) String customerDocument) {
        LocalDate start = from != null && !from.isBlank() ? LocalDate.parse(from) : LocalDate.now();
        LocalDate end = to != null && !to.isBlank() ? LocalDate.parse(to) : start.plusMonths(1);
        List<AppointmentEntity> list = appointmentRepository.findByTenantIdAndAppointmentDateBetweenOrderByAppointmentTimeAsc(tenantId, start, end);
        if (!includeCancelled) {
            list = list.stream()
                .filter(a -> {
                    String s = a.getStatus();
                    return s == null || s.isBlank() || !"cancelled".equalsIgnoreCase(s.strip());
                })
                .collect(Collectors.toList());
        }
        if (customerDocument != null && !customerDocument.isBlank()) {
            String nd = CustomerDocumentNormalizer.normalize(customerDocument);
            if (!nd.isEmpty()) {
                list = list.stream()
                    .filter(a -> nd.equals(a.getCustomerDocument() != null
                        ? a.getCustomerDocument().strip() : ""))
                    .collect(Collectors.toList());
            }
        }
        return ResponseEntity.ok(list);
    }

    /** Cancelar / reactivar cita desde el panel (misma semántica que la tool del chatbot). */
    @PatchMapping("/tenants/{tenantId}/appointments/{appointmentId}")
    public ResponseEntity<AppointmentEntity> patchAppointmentStatus(
            @PathVariable String tenantId,
            @PathVariable Long appointmentId,
            @RequestBody Map<String, String> body) {
        String status = body != null && body.get("status") != null ? body.get("status").strip() : "";
        if (status.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }
        return appointmentRepository.findById(appointmentId)
            .filter(a -> tenantId.equals(a.getTenantId()))
            .map(a -> {
                a.setStatus(status);
                return ResponseEntity.ok(appointmentRepository.save(a));
            })
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/tenants/{tenantId}/appointments")
    public ResponseEntity<?> createAppointment(
            @PathVariable String tenantId,
            @RequestBody Map<String, Object> body) {
        String customerDocumentRaw = body.get("customerDocument") != null ? body.get("customerDocument").toString().strip() : "";
        String customerDocument = CustomerDocumentNormalizer.normalize(customerDocumentRaw);
        if (customerDocument.isEmpty()) {
            return ResponseEntity.badRequest().body(
                Map.of("error", "customerDocument es obligatorio para mantener el expediente del usuario."));
        }
        String customerName = body.get("customerName") != null ? body.get("customerName").toString().trim() : "";
        if (customerName.isEmpty()) {
            return ResponseEntity.badRequest().body(
                Map.of("error", "customerName es obligatorio."));
        }
        AppointmentEntity e = new AppointmentEntity();
        e.setTenantId(tenantId);
        e.setCustomerName(customerName);
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
        return ResponseEntity.ok(knowledgeChunkAdminService.getByTenant(tenantId));
    }

    @PostMapping("/tenants/{tenantId}/knowledge")
    public ResponseEntity<KnowledgeChunkEntity> createKnowledge(
            @PathVariable String tenantId,
            @RequestBody KnowledgeChunkEntity chunk) {
        return ResponseEntity.ok(knowledgeChunkAdminService.create(tenantId, chunk));
    }

    @PutMapping("/tenants/{tenantId}/knowledge/{chunkId}")
    public ResponseEntity<KnowledgeChunkEntity> updateKnowledge(
            @PathVariable String tenantId,
            @PathVariable Long chunkId,
            @RequestBody KnowledgeChunkEntity chunk) {
        return knowledgeChunkAdminService.update(tenantId, chunkId, chunk)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/tenants/{tenantId}/knowledge/{chunkId}")
    public ResponseEntity<Void> deleteKnowledge(
            @PathVariable String tenantId,
            @PathVariable Long chunkId) {
        return knowledgeChunkAdminService.delete(tenantId, chunkId)
            ? ResponseEntity.noContent().build()
            : ResponseEntity.notFound().build();
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
