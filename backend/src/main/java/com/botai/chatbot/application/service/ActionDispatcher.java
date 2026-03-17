package com.botai.chatbot.application.service;

import com.botai.chatbot.domain.model.ConversationState;
import com.botai.chatbot.domain.model.InboundMessage;
import com.botai.chatbot.domain.model.OutboundMessage;
import com.botai.chatbot.domain.repository.ConversationRepository;
import com.botai.chatbot.domain.service.BotAction;

import java.util.List;
import java.util.Optional;

/**
 * Dispatches to the appropriate action based on conversation state or intent.
 * Actions do not know channel or AI.
 */
public class ActionDispatcher {

    private final List<BotAction> actions;
    private final ConversationRepository conversationRepository;

    public ActionDispatcher(List<BotAction> actions, ConversationRepository conversationRepository) {
        this.actions = actions != null ? actions : List.of();
        this.conversationRepository = conversationRepository;
    }

    /**
     * If state has an active intent, find the matching action and execute.
     */
    public OutboundMessage dispatch(ConversationState state, String userInput) {
        if (!state.hasIntent()) return null;
        Optional<BotAction> action = actions.stream()
            .filter(a -> state.getCurrentIntent().equals(a.getActionId()))
            .findFirst();
        if (action.isEmpty()) return null;
        OutboundMessage result = action.get().execute(state, userInput);
        if (result != null) {
            updateStateAfterAction(state, action.get(), userInput, result);
        }
        return result;
    }

    /**
     * Start an action from a menu option (e.g. user pressed "1" and option has actionIntent "book_appointment").
     */
    public OutboundMessage startFromMenuOption(ConversationState state, String actionIntent, String userInput) {
        if (actionIntent == null || actionIntent.isBlank()) return null;
        Optional<BotAction> action = actions.stream()
            .filter(a -> actionIntent.equals(a.getActionId()))
            .findFirst();
        if (action.isEmpty()) return null;
        ConversationState newState = ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(actionIntent)
            .context(state.getContext())
            .build();
        conversationRepository.save(newState);
        OutboundMessage result = action.get().execute(newState, userInput);
        // No volver a guardar newState: la acción ya persiste el estado actualizado (step, etc.)
        return result;
    }

    /**
     * Try to start an action by trigger intent (e.g. "crear lead" -> create_lead).
     */
    public OutboundMessage tryDispatchByIntent(InboundMessage inbound, ConversationState state) {
        String text = inbound.getText();
        if (text == null || text.isBlank()) return null;
        String normalized = text.strip().toLowerCase();

        for (BotAction action : actions) {
            String trigger = action.getTriggerIntent();
            if (trigger == null || trigger.isBlank()) continue;
            if (normalized.contains(trigger.toLowerCase())) {
                ConversationState newState = ConversationState.builder()
                    .conversationId(inbound.getConversationId())
                    .userId(inbound.getUserId())
                    .channelId(inbound.getChannelId())
                    .currentIntent(action.getActionId())
                    .context(state.getContext())
                    .build();
                conversationRepository.save(newState);
                return action.execute(newState, text);
            }
        }
        return null;
    }

    private void updateStateAfterAction(ConversationState state, BotAction action, String userInput, OutboundMessage result) {
        // Action may have already updated state. If action completes, clear intent.
        // Here we only persist; clearing is done inside the action when flow ends.
        conversationRepository.save(state);
    }
}
