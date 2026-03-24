/**
 * Capa LLM del bot:
 * <ul>
 *   <li>{@link com.botai.chatbot.application.service.conversation.ai.RagLlmChatService} — flujo completo del turno generativo:
 *       {@code AI_ENABLED} → jailbreak → RAG + inyección de clasificación del router → LLM + validación de salida
 *       (implementa {@link com.botai.chatbot.application.orchestration.ConversationModeHandler} para modo solo IA).</li>
 *   <li>{@link com.botai.chatbot.application.service.conversation.ai.JailbreakInputFilter} — bloqueo por patrones de abuso del prompt
 *       antes de llamar al LLM.</li>
 * </ul>
 */
package com.botai.chatbot.application.service.conversation.ai;
