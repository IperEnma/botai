/**
 * Capa LLM del bot:
 * <ul>
 *   <li>{@link com.botai.application.chatbot.service.conversation.ai.RagLlmChatService} — flujo completo del turno generativo:
 *       {@code AI_ENABLED} → jailbreak → RAG + inyección de clasificación del router → LLM + validación de salida
 *       (implementa {@link com.botai.application.chatbot.orchestration.ConversationModeHandler} para modo solo IA).</li>
 *   <li>{@link com.botai.application.chatbot.service.conversation.ai.JailbreakInputFilter} — bloqueo por patrones de abuso del prompt
 *       antes de llamar al LLM.</li>
 * </ul>
 */
package com.botai.application.chatbot.service.conversation.ai;
