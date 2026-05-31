package com.botai.infrastructure.chatbot.channel.whatsapp;

import java.util.List;
import java.util.Map;

/**
 * Enmascara datos sensibles en logs de WhatsApp (teléfonos, IDs de Meta, payloads completos).
 */
public final class WhatsAppLogRedaction {

    private WhatsAppLogRedaction() {
    }

    public static String maskPhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return "***";
        }
        String p = phone.strip().replace("+", "");
        if (p.length() <= 4) {
            return "***";
        }
        return "***" + p.substring(p.length() - 4);
    }

    public static String maskId(String id) {
        if (id == null || id.isBlank()) {
            return "***";
        }
        String s = id.strip();
        if (s.length() <= 4) {
            return "***";
        }
        return "***" + s.substring(s.length() - 4);
    }

    public static String truncateText(String text, int max) {
        if (text == null || text.isBlank()) {
            return "";
        }
        if (text.length() <= max) {
            return text;
        }
        return text.substring(0, max) + "...";
    }

    @SuppressWarnings("unchecked")
    public static String summarizeWebhook(Map<String, Object> payload) {
        if (payload == null || payload.isEmpty()) {
            return "webhook vacío";
        }
        try {
            Object entryList = payload.get("entry");
            if (!(entryList instanceof List<?> entries) || entries.isEmpty()) {
                return "webhook sin entry";
            }
            Object firstEntry = entries.get(0);
            if (!(firstEntry instanceof Map<?, ?>)) {
                return "webhook entry inválido";
            }
            Object changes = ((Map<String, Object>) firstEntry).get("changes");
            if (!(changes instanceof List<?> changeList) || changeList.isEmpty()) {
                return "webhook sin changes";
            }
            Object firstChange = changeList.get(0);
            if (!(firstChange instanceof Map<?, ?>)) {
                return "webhook change inválido";
            }
            Object value = ((Map<String, Object>) firstChange).get("value");
            if (!(value instanceof Map<?, ?> valueMap)) {
                return "webhook value inválido";
            }
            Map<String, Object> v = (Map<String, Object>) valueMap;

            if (v.containsKey("statuses")) {
                Object statuses = v.get("statuses");
                if (statuses instanceof List<?> statusList && !statusList.isEmpty()
                        && statusList.get(0) instanceof Map<?, ?> rawStatusMap) {
                    Map<String, Object> statusMap = (Map<String, Object>) rawStatusMap;
                    String status = String.valueOf(statusMap.getOrDefault("status", "?"));
                    return "status update: " + status;
                }
                return "status update";
            }
            if (v.containsKey("messages")) {
                Object messages = v.get("messages");
                if (messages instanceof List<?> msgList && !msgList.isEmpty()
                        && msgList.get(0) instanceof Map<?, ?> rawMsgMap) {
                    Map<String, Object> msgMap = (Map<String, Object>) rawMsgMap;
                    String type = String.valueOf(msgMap.getOrDefault("type", "?"));
                    String from = maskPhone(String.valueOf(msgMap.getOrDefault("from", "")));
                    return "inbound message type=" + type + " from=" + from;
                }
                return "inbound message";
            }
            return "webhook evento desconocido";
        } catch (Exception e) {
            return "webhook (resumen no disponible)";
        }
    }
}
