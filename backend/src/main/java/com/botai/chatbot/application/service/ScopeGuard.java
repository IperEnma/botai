package com.botai.chatbot.application.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.regex.Pattern;

/**
 * Guardrail de entrada: si está activo, bloquea por regex (jailbreak/cambio de rol). Si desactivado, no bloquea.
 */
@Service
public class ScopeGuard {

    private static final Logger log = LoggerFactory.getLogger(ScopeGuard.class);

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

    private final boolean enabled;
    private final String outOfScopeMessage;

    public ScopeGuard(@Value("${bot.guardrails.enabled:true}") boolean enabled,
                      @Value("${bot.guardrails.out-of-scope-message:}") String outOfScopeMessage) {
        this.enabled = enabled;
        this.outOfScopeMessage = outOfScopeMessage != null && !outOfScopeMessage.isBlank()
            ? outOfScopeMessage
            : "";
    }

    public boolean isJailbreak(String userMessage) {
        if (userMessage == null || userMessage.isBlank()) return false;
        String normalized = userMessage.strip();
        for (Pattern p : JAILBREAK_PATTERNS) {
            if (p.matcher(normalized).find()) return true;
        }
        return false;
    }

    /**
     * Si guardrail desactivado → permite todo. Si activo → bloquea solo por patrones de jailbreak (regex).
     */
    public ScopeResult check(String userMessage, String tenantId) {
        if (!enabled) {
            return ScopeResult.allow();
        }
        if (userMessage == null || userMessage.isBlank()) {
            return ScopeResult.allow();
        }
        String normalized = userMessage.strip();
        for (Pattern p : JAILBREAK_PATTERNS) {
            if (p.matcher(normalized).find()) {
                log.info("[GUARDRAIL] Entrada bloqueada (tenant={}): {}", tenantId, p.pattern());
                return ScopeResult.block(outOfScopeMessage);
            }
        }
        return ScopeResult.allow();
    }

    public String getOutOfScopeMessage() {
        return outOfScopeMessage;
    }

    public record ScopeResult(boolean allowed, String blockMessage) {
        public static ScopeResult allow() {
            return new ScopeResult(true, null);
        }
        public static ScopeResult block(String message) {
            return new ScopeResult(false, message);
        }
    }
}
