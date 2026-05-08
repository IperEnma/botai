package com.botai.agenda.application.dto;

/**
 * Contexto del administrador de tenant ya registrado en AGENDA,
 * resuelto por {@code email}, {@code google_linked_email} o (vía link) cuenta creada con {@code numero}.
 */
public record TenantAdminContextResponse(String tenantId) {}
