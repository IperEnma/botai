package com.botai.domain.agenda.model;

/**
 * Categoría comercial opcional del plan. No impacta la lógica de descuento, solo
 * clasifica para filtros/precios. Usable como {@code null} si el negocio no usa tiers.
 */
public enum PlanTier {
    VIP,
    GOLDEN,
    PLATA
}
