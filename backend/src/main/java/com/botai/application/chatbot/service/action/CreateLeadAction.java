package com.botai.application.chatbot.service.action;

import com.botai.application.chatbot.support.InboundMetadata;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.Lead;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.repository.LeadRepository;
import com.botai.domain.chatbot.service.BotAction;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * Example action: collect name and email, then create a lead. Does not know channel or AI.
 */
@Component
public class CreateLeadAction implements BotAction {

    private static final String ACTION_ID = "create_lead";
    private static final String TRIGGER = "crear lead";
    private static final Pattern EMAIL = Pattern.compile(
        "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");

    private final LeadRepository leadRepository;
    private final ConversationRepository conversationRepository;

    public CreateLeadAction(LeadRepository leadRepository, ConversationRepository conversationRepository) {
        this.leadRepository = leadRepository;
        this.conversationRepository = conversationRepository;
    }

    @Override
    public String getActionId() {
        return ACTION_ID;
    }

    @Override
    public String getTriggerIntent() {
        return TRIGGER;
    }

    @Override
    public OutboundMessage execute(ConversationState state, String userInput) {
        String convId = state.getConversationId();
        Map<String, Object> ctx = new HashMap<>(state.getContext());
        Object t = ctx.get(InboundMetadata.TENANT_ID);
        if (t == null || t.toString().isBlank()) {
            throw new IllegalStateException("tenantId is required in context");
        }
        String tenantId = t.toString().strip();

        if (!ctx.containsKey("step")) {
            ctx.put("step", "name");
            conversationRepository.save(ConversationState.builder()
                .conversationId(convId)
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(ACTION_ID)
                .context(ctx)
                .build());
            return OutboundMessage.builder()
                .text("Para crear el lead, dime tu nombre completo.")
                .conversationId(convId)
                .tenantId(tenantId)
                .build();
        }

        String step = (String) ctx.get("step");
        if ("name".equals(step)) {
            ctx.put("step", "email");
            ctx.put("name", userInput.strip());
            conversationRepository.save(ConversationState.builder()
                .conversationId(convId)
                .userId(state.getUserId())
                .channelId(state.getChannelId())
                .currentIntent(ACTION_ID)
                .context(ctx)
                .build());
            return OutboundMessage.builder()
                .text("Gracias. Ahora indícame tu correo electrónico.")
                .conversationId(convId)
                .tenantId(tenantId)
                .build();
        }

        if ("email".equals(step)) {
            String email = userInput.strip();
            if (!EMAIL.matcher(email).matches()) {
                return OutboundMessage.builder()
                    .text("Por favor, escribe un email válido (ejemplo: nombre@dominio.com).")
                    .conversationId(convId)
                    .tenantId(tenantId)
                    .build();
            }
            String name = (String) ctx.get("name");
            Lead lead = new Lead(name, email, "chatbot", state.getUserId());
            leadRepository.save(lead);
            conversationRepository.clearIntent(convId);
            return OutboundMessage.builder()
                .text("Lead creado correctamente. Te contactaremos pronto.")
                .conversationId(convId)
                .tenantId(tenantId)
                .build();
        }

        return null;
    }
}
