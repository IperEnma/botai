/**
 * Servicios de aplicación agrupados por vertical:
 * <ul>
 *   <li>{@code conversation} — los tres modos FAQ / IA / FAQ+IA y piezas compartidas (menú, FAQ keywords).</li>
 *   <li>{@code inbound} — pipeline de mensaje entrante (core, router, historial, sesión, acciones en curso).</li>
 *   <li>{@code action} — {@link com.botai.chatbot.domain.service.BotAction} concretas (citas, leads, etc.).</li>
 *   <li>{@code knowledge} — RAG / fragmentos de conocimiento.</li>
 *   <li>{@code admin} — casos de uso de panel/backoffice.</li>
 * </ul>
 */
package com.botai.chatbot.application.service;
