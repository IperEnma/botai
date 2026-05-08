/**
 * Orquestación del modo conversacional (FAQ / IA) con patrón <em>Strategy</em>:
 * <ul>
 *   <li>{@link ConversationModeResolver} — elige {@link ConversationMode} según flags del tenant.</li>
 *   <li>{@link ConversationModeOrchestrator} — precondiciones, clasificación y despacho al {@link ConversationModeHandler}
 *       (FAQ / IA / FAQ+IA). Cada handler implementa su propio pipeline de turno.</li>
 *   <li>Cada modo (FAQ-only, IA-only, FAQ+IA) lo implementa un {@code @Service} en {@code application.service}
 *       que implementa {@link ConversationModeHandler} (sin clases delegadoras extra).</li>
 * </ul>
 */
package com.botai.application.chatbot.orchestration;
