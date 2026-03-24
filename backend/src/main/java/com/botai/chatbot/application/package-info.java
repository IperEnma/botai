/**
 * Capa de aplicación (casos de uso).
 * <ul>
 *   <li>{@code dto} — datos que cruzan servicios (resultados de ruta, clasificación, requests).</li>
 *   <li>{@code orchestration} — modo conversacional FAQ/IA (Strategy + orquestador).</li>
 *   <li>{@code service} — por vertical: {@code conversation} (FAQ/IA), {@code inbound}, {@code action}, {@code knowledge}, {@code admin}.</li>
 *   <li>{@code prompt} — textos del LLM y tools centralizados ({@link com.botai.chatbot.application.prompt.BotPrompts}).</li>
 *   <li>{@code support} — utilidades sin estado ({@link com.botai.chatbot.application.support.InboundMetadata}, respuestas estándar).</li>
 *   <li>{@code usecase} — fachadas de entrada (p. ej. procesar mensaje entrante).</li>
 * </ul>
 */
package com.botai.chatbot.application;
