package com.botai.chatbot.infrastructure.channel.whatsapp;

import com.botai.chatbot.application.support.InboundMetadata;
import com.botai.chatbot.domain.ConversationContextKeys;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.infrastructure.channel.ChannelAdapter;
import com.botai.chatbot.infrastructure.persistence.entity.BotEntity;
import com.botai.chatbot.infrastructure.persistence.jpa.BotJpaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Adaptador para WhatsApp Cloud API (Meta).
 * Parsea el payload del webhook (entry[].changes[].value) y identifica el bot por phone_number_id.
 */
@Component
public class WhatsAppAdapter implements ChannelAdapter {

    private static final Logger log = LoggerFactory.getLogger(WhatsAppAdapter.class);

    public static final String CHANNEL_ID = "whatsapp";
    /** Misma clave que {@link ConversationContextKeys#TENANT_ID} en el contexto persistido. */
    public static final String METADATA_TENANT_ID = ConversationContextKeys.TENANT_ID;

    private final WhatsAppCloudApiClient apiClient;
    private final BotJpaRepository botRepository;

    public WhatsAppAdapter(WhatsAppCloudApiClient apiClient, BotJpaRepository botRepository) {
        this.apiClient = apiClient;
        this.botRepository = botRepository;
    }

    @Override
    public String getChannelId() {
        return CHANNEL_ID;
    }

    /**
     * Parsea el payload de WhatsApp Cloud API (objeto entry → changes → value → messages).
     * Ignora status updates (statuses) que Meta envía cuando el bot envía mensajes.
     */
    @Override
    @SuppressWarnings("unchecked")
    public InboundMessage toInboundMessage(Object rawPayload) {
        log.info("[WA-ADAPTER] toInboundMessage llamado");
        
        if (!(rawPayload instanceof Map)) {
            log.warn("[WA-ADAPTER] Payload no es Map, ignorando");
            return emptyInbound();
        }
        Map<String, Object> payload = (Map<String, Object>) rawPayload;

        String from = "unknown";
        String text = "";
        String messageId = "";
        String tenantId = null;
        String whatsappProfileName = null;

        Object entryList = payload.get("entry");
        if (entryList instanceof List<?> entries && !entries.isEmpty()) {
            Object firstEntry = entries.get(0);
            if (firstEntry instanceof Map<?, ?> entryMap) {
                Object changes = ((Map<String, Object>) firstEntry).get("changes");
                if (changes instanceof List<?> changeList && !changeList.isEmpty()) {
                    Object firstChange = changeList.get(0);
                    if (firstChange instanceof Map<?, ?> changeMap) {
                        Object value = ((Map<String, Object>) firstChange).get("value");
                        if (value instanceof Map<?, ?> valueMap) {
                            Map<String, Object> v = (Map<String, Object>) value;

                            Object contactsObj = v.get("contacts");
                            if (contactsObj instanceof List<?> contactList && !contactList.isEmpty()) {
                                Object c0 = contactList.get(0);
                                if (c0 instanceof Map<?, ?> contactMap) {
                                    Object profile = contactMap.get("profile");
                                    if (profile instanceof Map<?, ?> profMap) {
                                        Object nameObj = profMap.get("name");
                                        if (nameObj != null) {
                                            String pn = String.valueOf(nameObj).strip();
                                            if (!pn.isEmpty()) {
                                                whatsappProfileName = WhatsAppInboundTextUtf8.tryFix(pn);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // IGNORAR STATUS UPDATES (esto causa el loop!)
                            if (v.containsKey("statuses")) {
                                log.info("[WA-ADAPTER] Status update detectado, IGNORANDO (evita loop)");
                                return emptyInbound();
                            }
                            
                            // Identificar bot por phone_number_id para obtener tenantId (value.metadata.phone_number_id en Cloud API)
                            Object metadata = v.get("metadata");
                            if (metadata instanceof Map<?, ?> metaMap) {
                                Object phoneNumberId = ((Map<String, Object>) metadata).get("phone_number_id");
                                if (phoneNumberId != null) {
                                    String phoneIdStr = phoneNumberId.toString().strip();
                                    if (!phoneIdStr.isEmpty()) {
                                        Optional<BotEntity> botOpt = botRepository.findFirstByWhatsappPhoneNumberId(phoneIdStr);
                                        if (botOpt.isEmpty()) {
                                            // Fallback: buscar por valor normalizado (trim) por si en BD hay espacios
                                            List<BotEntity> allBots = botRepository.findAll();
                                            botOpt = allBots.stream()
                                                .filter(b -> b.getWhatsappPhoneNumberId() != null
                                                    && b.getWhatsappPhoneNumberId().strip().equals(phoneIdStr))
                                                .findFirst();
                                            if (botOpt.isPresent()) {
                                                log.info("[WA-ADAPTER] Bot identificado por phone_number_id (match con trim) -> tenant={}", botOpt.get().getTenantId());
                                            }
                                        }
                                        if (botOpt.isPresent()) {
                                            tenantId = botOpt.get().getTenantId();
                                            if (tenantId != null) {
                                                log.info("[WA-ADAPTER] Bot identificado por phone_number_id={} -> tenant={}", phoneIdStr, tenantId);
                                            }
                                        } else {
                                            List<BotEntity> allBots = botRepository.findAll();
                                            log.warn("[WA-ADAPTER] No hay bot con whatsapp_phone_number_id={}. Meta envio: {}. Bots en BD (id -> ultimos 4 digitos): {}",
                                                phoneIdStr, phoneIdStr,
                                                allBots.stream()
                                                    .map(b -> b.getId() + "=" + (b.getWhatsappPhoneNumberId() != null && b.getWhatsappPhoneNumberId().length() >= 4
                                                        ? "***" + b.getWhatsappPhoneNumberId().substring(b.getWhatsappPhoneNumberId().length() - 4) : (b.getWhatsappPhoneNumberId() != null ? b.getWhatsappPhoneNumberId() : "null")))
                                                    .toList());
                                        }
                                    } else {
                                        log.warn("[WA-ADAPTER] metadata.phone_number_id viene vacío.");
                                    }
                                } else {
                                    log.warn("[WA-ADAPTER] metadata.phone_number_id ausente en el payload. Claves en value: {}", v.keySet());
                                }
                            } else if (tenantId == null) {
                                log.warn("[WA-ADAPTER] value.metadata no es Map. Claves en value: {}", v.keySet());
                            }
                            
                            Object messages = v.get("messages");
                            if (messages instanceof List<?> msgList && !msgList.isEmpty()) {
                                Object firstMsg = msgList.get(0);
                                if (firstMsg instanceof Map<?, ?> msg) {
                                    Map<String, Object> m = (Map<String, Object>) firstMsg;
                                    from = String.valueOf(m.getOrDefault("from", from));
                                    messageId = String.valueOf(m.getOrDefault("id", messageId));
                                    String msgType = String.valueOf(m.get("type"));
                                    log.info("[WA-ADAPTER] Mensaje tipo={}, from={}, id={}", msgType, from, messageId);
                                    
                                    if ("text".equals(msgType)) {
                                        Object textObj = m.get("text");
                                        if (textObj instanceof Map<?, ?> textMap) {
                                            Object body = ((Map<?, ?>) textObj).get("body");
                                            text = body != null ? String.valueOf(body) : "";
                                            text = WhatsAppInboundTextUtf8.tryFix(text);
                                        }
                                    } else {
                                        log.info("[WA-ADAPTER] Mensaje no es texto ({}), ignorando contenido", msgType);
                                    }
                                }
                            } else {
                                log.info("[WA-ADAPTER] No hay 'messages' en el payload");
                            }
                        }
                    }
                }
            }
        }

        log.info("[WA-ADAPTER] Parseado: from={}, tenant={}, text={}", from, tenantId, text.length() > 50 ? text.substring(0,50)+"..." : text);
        
        String conversationId = from + "@" + CHANNEL_ID;
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("messageId", messageId);
        if (tenantId != null) {
            metadata.put(METADATA_TENANT_ID, tenantId);
        }
        if (whatsappProfileName != null && !whatsappProfileName.isBlank()) {
            metadata.put(InboundMetadata.WHATSAPP_PROFILE_NAME, whatsappProfileName);
        }
        return InboundMessage.builder()
            .channelId(CHANNEL_ID)
            .userId(from)
            .conversationId(conversationId)
            .text(text)
            .metadata(metadata)
            .build();
    }

    @Override
    public void send(OutboundMessage message) {
        log.info("[WA-ADAPTER] send() llamado");
        if (message == null) {
            log.warn("[WA-ADAPTER] send() mensaje es null");
            return;
        }
        String to = message.getConversationId() != null && message.getConversationId().contains("@")
            ? message.getConversationId().split("@")[0]
            : null;
        if (to == null || to.isBlank()) {
            log.warn("[WA-ADAPTER] send() conversationId vacío o sin @");
            return;
        }
        
        String tenantId = message.getTenantId();
        if (tenantId == null || tenantId.isBlank()) {
            log.warn("[WA-ADAPTER] send() tenantId ausente, no se puede enviar");
            return;
        }
        String body = renderMessage(message);
        body = WhatsAppInboundTextUtf8.tryFix(body != null ? body : "");
        log.info("[WA-ADAPTER] Enviando a {} (tenant={}): {}", to, tenantId, body != null && body.length() > 50 ? body.substring(0,50)+"..." : body);
        boolean sent = apiClient.sendText(tenantId, to, body != null ? body : "");
        if (sent) {
            log.info("[WA-ADAPTER] Mensaje enviado exitosamente a {}", to);
        } else {
            log.warn("[WA-ADAPTER] No se pudo enviar el mensaje a {} (revisa logs [WA-API] y permisos Meta/WhatsApp)", to);
        }
    }

    /**
     * Render OutboundMessage to WhatsApp text format.
     * Options are appended as numbered list.
     * Future: can be changed to use WhatsApp Interactive Messages/Buttons.
     */
    private String renderMessage(OutboundMessage message) {
        StringBuilder sb = new StringBuilder();
        
        if (message.getText() != null && !message.getText().isBlank()) {
            sb.append(message.getText());
        }
        
        if (message.getOptions() != null && !message.getOptions().isEmpty()) {
            sb.append("\n\n");
            for (String option : message.getOptions()) {
                sb.append(option).append("\n");
            }
        }
        if (message.getFooterText() != null && !message.getFooterText().isBlank()) {
            sb.append("\n\n").append(message.getFooterText());
        }
        
        return sb.toString().trim();
    }

    private static InboundMessage emptyInbound() {
        return InboundMessage.builder()
            .channelId(CHANNEL_ID)
            .userId("unknown")
            .conversationId("unknown")
            .text("")
            .build();
    }
}
