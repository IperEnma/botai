package com.botai.chatbot.application.dto;

import com.botai.chatbot.domain.model.OutboundMessage;

/**
 * Resultado de enrutar un mensaje hacia FAQ, menú o IA. Tipo de dominio de aplicación: no pertenece al router.
 */
public record ConversationRouteResult(OutboundMessage message, String intentSource, String newMenuId) {}
