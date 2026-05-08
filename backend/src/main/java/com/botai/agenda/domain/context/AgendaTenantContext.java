package com.botai.agenda.domain.context;

/**
 * Holder de tenant para el módulo AGENDA.
 *
 * <p>ThreadLocal propio, aislado del {@code TenantContext} del bot para respetar
 * la regla de no importar nada desde {@code com.botai.chatbot.*}. Si en el futuro
 * se introduce un contexto compartido, se haría con una abstracción explícita
 * (no importando entre paquetes).</p>
 *
 * <p>Uso típico: un interceptor HTTP resuelve el tenantId desde el contexto de
 * seguridad y lo setea acá al comienzo de la request; el {@code clear()} se
 * llama en el {@code afterCompletion}.</p>
 */
public final class AgendaTenantContext {

    private static final ThreadLocal<String> TENANT_ID = new ThreadLocal<>();
    private static final ThreadLocal<String> USER_ID = new ThreadLocal<>();

    private AgendaTenantContext() {
        // Utility class — no instanciable.
    }

    public static void setTenantId(String tenantId) {
        TENANT_ID.set(tenantId);
    }

    public static String getTenantId() {
        return TENANT_ID.get();
    }

    public static String requireTenantId() {
        String tenantId = TENANT_ID.get();
        if (tenantId == null || tenantId.isBlank()) {
            throw new IllegalStateException("AgendaTenantContext: tenantId no seteado para la request actual");
        }
        return tenantId;
    }

    public static void setUserId(String userId) {
        USER_ID.set(userId);
    }

    public static String getUserId() {
        return USER_ID.get();
    }

    public static void clear() {
        TENANT_ID.remove();
        USER_ID.remove();
    }
}
