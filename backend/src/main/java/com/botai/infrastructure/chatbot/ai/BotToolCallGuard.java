package com.botai.infrastructure.chatbot.ai;

import com.botai.application.chatbot.prompt.BotPrompts;
import com.botai.infrastructure.chatbot.config.BotProperties;
import com.botai.infrastructure.security.context.ThreadTenantContext;
import org.springframework.stereotype.Component;

/**
 * Limita llamadas a tools por turno para evitar loops del agente.
 */
@Component
public class BotToolCallGuard {

    private final int maxCallsPerTurn;

    public BotToolCallGuard(BotProperties botProperties) {
        this.maxCallsPerTurn = botProperties.getTools().getMaxCallsPerTurn();
    }

    public void beginTurn() {
        ThreadTenantContext.beginToolCallBudget(maxCallsPerTurn);
    }

    public void endTurn() {
        ThreadTenantContext.clearToolCallBudget();
    }

    public String gate() {
        if (ThreadTenantContext.tryConsumeToolCall()) {
            return null;
        }
        return BotPrompts.ToolsConsulta.ERR_TOOL_BUDGET_EXCEEDED;
    }
}
