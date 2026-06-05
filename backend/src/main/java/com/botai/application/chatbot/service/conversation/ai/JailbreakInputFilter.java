package com.botai.application.chatbot.service.conversation.ai;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.regex.Pattern;

/**
 * Filtra el texto del usuario antes del LLM: detecta patrones típicos de jailbreak, cambio de rol o abuso del prompt (regex).
 */
@Service
public class JailbreakInputFilter {

    private static final Logger log = LoggerFactory.getLogger(JailbreakInputFilter.class);

    private static final List<Pattern> JAILBREAK_PATTERNS = List.of(
        Pattern.compile("(?i)(ignor(a|e)\\s+(las?\\s+)?instrucciones|forget\\s+(all\\s+)?(instructions|prompts))"),
        Pattern.compile("(?i)(olvida\\s+(tus?|las?)\\s+instrucciones|olvidar\\s+instrucciones)"),
        Pattern.compile("(?i)(actúa\\s+como|actua\\s+como|you\\s+are\\s+now|eres\\s+ahora|you\\s+are\\s+a)"),
        Pattern.compile("(?i)(ponte\\s+en\\s+el\\s+rol|ponte\\s+en\\s+rol|change\\s+(your\\s+)?role)"),
        Pattern.compile("(?i)(DAN|do\\s+anything\\s+now|jailbreak)"),
        Pattern.compile("(?i)(escribe\\s+código|escribe\\s+codigo|write\\s+code|genera\\s+código|hola\\s+mundo\\s+en)"),
        Pattern.compile("(?i)(programador|programmer|developer|desarrollador)"),
        Pattern.compile("(?i)(#include\\s*<|int\\s+main\\s*\\(|printf\\s*\\()"),
        Pattern.compile("(?i)(reveal\\s+(your\\s+)?(instructions|prompt)|cuáles\\s+son\\s+tus\\s+instrucciones)"),
        Pattern.compile("(?i)(pretend\\s+you|finge\\s+que|simula\\s+que)"),
        Pattern.compile("(?i)(bypass|omitir\\s+restricciones|sin\\s+restricciones)")
    );

    public boolean isJailbreakPattern(String userMessage) {
        if (userMessage == null || userMessage.isBlank()) return false;
        String normalized = userMessage.strip();
        for (Pattern p : JAILBREAK_PATTERNS) {
            if (p.matcher(normalized).find()) return true;
        }
        return false;
    }

    /**
     * Bloquea solo si coincide un patrón de jailbreak; el turno sigue al LLM con suplementos de límite.
     */
    public Decision evaluate(String userMessage, String tenantId) {
        if (userMessage == null || userMessage.isBlank()) {
            return Decision.allow();
        }
        String normalized = userMessage.strip();
        for (Pattern p : JAILBREAK_PATTERNS) {
            if (p.matcher(normalized).find()) {
                log.info("[JAILBREAK-FILTER] Entrada bloqueada (tenant={}): {}", tenantId, p.pattern());
                return Decision.block(null);
            }
        }
        return Decision.allow();
    }

    public record Decision(boolean allowed, String blockMessage) {
        public static Decision allow() {
            return new Decision(true, null);
        }
        public static Decision block(String message) {
            return new Decision(false, message);
        }
    }
}
