package com.botai.application.chatbot.service.inbound;

import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.session.ChatSessionKeys;
import com.botai.infrastructure.chatbot.config.BotProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * Sesiones de chat por {@code conversationId}: el historial que ve el LLM solo incluye mensajes
 * de la sesión actual. Nueva sesión tras inactividad configurable o si el usuario pide reiniciar.
 */
@Service
public class ChatSessionService {

    private static final Logger log = LoggerFactory.getLogger(ChatSessionService.class);

    private final ConversationRepository conversationRepository;
    private final int idleMinutes;

    public ChatSessionService(ConversationRepository conversationRepository, BotProperties botProperties) {
        this.conversationRepository = conversationRepository;
        this.idleMinutes = botProperties.getSession().getIdleMinutes();
    }

    /**
     * Asegura sesión activa, rota si hace falta, actualiza timestamp y persiste contexto.
     */
    public ConversationState touchSession(ConversationState state, String userMessage) {
        Map<String, Object> ctx = new HashMap<>(state.getContext());
        long now = System.currentTimeMillis();

        String currentSid = stringVal(ctx.get(ChatSessionKeys.SESSION_ID));
        String lastStr = stringVal(ctx.get(ChatSessionKeys.SESSION_LAST_ACTIVITY));
        long lastActivity = parseLongSafe(lastStr, 0L);

        boolean explicitReset = wantsNewSession(userMessage);
        boolean idleExceeded = idleMinutes > 0 && lastActivity > 0
            && (now - lastActivity) > (long) idleMinutes * 60_000L;
        boolean missingSession = currentSid == null || currentSid.isBlank();

        if (explicitReset || idleExceeded || missingSession) {
            String newId = UUID.randomUUID().toString();
            ctx.put(ChatSessionKeys.SESSION_ID, newId);
            log.info("[SESSION] Nueva sesión: conv={} id={} (resetExplícito={}, idle={}, primera={})",
                state.getConversationId(), newId, explicitReset, idleExceeded, missingSession);
        }

        ctx.put(ChatSessionKeys.SESSION_LAST_ACTIVITY, String.valueOf(now));

        ConversationState updated = ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(state.getCurrentIntent())
            .context(ctx)
            .updatedAt(now)
            .build();
        conversationRepository.save(updated);
        return updated;
    }

    public static String sessionIdFrom(ConversationState state) {
        if (state == null || state.getContext() == null) {
            return null;
        }
        return stringVal(state.getContext().get(ChatSessionKeys.SESSION_ID));
    }

    private static boolean wantsNewSession(String userMessage) {
        if (userMessage == null || userMessage.isBlank()) {
            return false;
        }
        String t = userMessage.toLowerCase(Locale.ROOT).replace('á', 'a')
            .replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u')
            .strip();
        return t.contains("nueva conversacion") || t.contains("nueva sesion") || t.contains("reiniciar")
            || t.contains("empezar de nuevo") || t.contains("empezar de cero") || t.contains("borrar contexto")
            || t.contains("olvidate de lo anterior") || t.contains("olvida lo anterior")
            || t.equals("reset") || t.contains("cerrar sesion de chat");
    }

    private static String stringVal(Object o) {
        return o == null ? null : o.toString().strip();
    }

    private static long parseLongSafe(String s, long defaultVal) {
        if (s == null || s.isBlank()) {
            return defaultVal;
        }
        try {
            return Long.parseLong(s.trim());
        } catch (NumberFormatException e) {
            return defaultVal;
        }
    }
}
