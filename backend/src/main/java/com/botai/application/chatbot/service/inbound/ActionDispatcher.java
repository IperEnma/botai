package com.botai.application.chatbot.service.inbound;

import com.botai.application.chatbot.service.action.GetAgendaPublicUrlAction;
import com.botai.application.chatbot.service.action.ViewAgendaBookingsByContactAction;
import com.botai.domain.chatbot.model.ConversationState;
import com.botai.domain.chatbot.model.InboundMessage;
import com.botai.domain.chatbot.model.OutboundMessage;
import com.botai.domain.chatbot.repository.ConversationRepository;
import com.botai.domain.chatbot.service.BotAction;

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
        String intent = canonicalActionIntent(state.getCurrentIntent());
        Optional<BotAction> action = actions.stream()
            .filter(a -> intent.equals(a.getActionId()))
            .findFirst();
        if (action.isEmpty()) return null;
        OutboundMessage result = action.get().execute(state, userInput);
        // No guardar `state` aquí: es la copia cargada al inicio del request; la acción ya persistió el contexto nuevo.
        return result;
    }

    /**
     * Start an action from a menu option (e.g. user pressed "1" and option has actionIntent "book_appointment").
     */
    public OutboundMessage startFromMenuOption(ConversationState state, String actionIntent, String userInput) {
        if (actionIntent == null || actionIntent.isBlank()) return null;
        String canonical = canonicalActionIntent(actionIntent);
        Optional<BotAction> action = actions.stream()
            .filter(a -> canonical.equals(a.getActionId()))
            .findFirst();
        if (action.isEmpty()) return null;
        ConversationState newState = ConversationState.builder()
            .conversationId(state.getConversationId())
            .userId(state.getUserId())
            .channelId(state.getChannelId())
            .currentIntent(canonical)
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

    /**
     * Menús u opciones persistidas con el id legacy {@code view_appointments} (citas tabla del bot) se redirigen
     * a consulta de reservas en Agenda.
     */
    private static String canonicalActionIntent(String actionIntent) {
        if (actionIntent == null) {
            return null;
        }
        if ("view_appointments".equals(actionIntent)) {
            return ViewAgendaBookingsByContactAction.ACTION_ID;
        }
        // Reserva nueva: el producto Agenda usa autogestión web; menús/legacy siguen pudiendo decir book_appointment.
        if ("book_appointment".equals(actionIntent)) {
            return GetAgendaPublicUrlAction.ACTION_ID;
        }
        return actionIntent;
    }

}
