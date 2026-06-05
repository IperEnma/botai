package com.botai.infrastructure.security.context;

/**
 * Contexto por hilo vinculado a la identidad de la petición: tenant, usuario de canal y conversación.
 * Vive bajo {@code infrastructure.security} porque se alinea con la resolución de identidad
 * (JWT, guards, tools que operan en nombre del usuario autenticado o del canal).
 *
 * <p>Llamar siempre a {@link #clear()} al terminar el request o el bloque try/finally equivalente.</p>
 */
public final class ThreadTenantContext {

    private static final ThreadLocal<String> TENANT_ID = new ThreadLocal<>();
    private static final ThreadLocal<String> USER_ID = new ThreadLocal<>();
    private static final ThreadLocal<String> CONVERSATION_ID = new ThreadLocal<>();

    private ThreadTenantContext() {
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
            throw new IllegalStateException("ThreadTenantContext: tenantId no seteado para el hilo actual");
        }
        return tenantId;
    }

    public static void setUserId(String userId) {
        USER_ID.set(userId);
    }

    public static String getUserId() {
        return USER_ID.get();
    }

    /** Para tools que necesitan el id de conversación (p. ej. limpiar intent tras agendar). */
    public static void setConversationId(String conversationId) {
        CONVERSATION_ID.set(conversationId);
    }

    public static String getConversationId() {
        return CONVERSATION_ID.get();
    }

    public static void clear() {
        TENANT_ID.remove();
        USER_ID.remove();
        CONVERSATION_ID.remove();
        clearToolCallBudget();
    }

    private static final ThreadLocal<Integer> TOOL_CALLS_USED = new ThreadLocal<>();
    private static final ThreadLocal<Integer> TOOL_CALLS_MAX = new ThreadLocal<>();

    public static void beginToolCallBudget(int maxCalls) {
        TOOL_CALLS_USED.set(0);
        TOOL_CALLS_MAX.set(Math.max(1, maxCalls));
    }

    public static boolean tryConsumeToolCall() {
        Integer max = TOOL_CALLS_MAX.get();
        if (max == null) {
            return true;
        }
        int used = TOOL_CALLS_USED.get() != null ? TOOL_CALLS_USED.get() : 0;
        if (used >= max) {
            return false;
        }
        TOOL_CALLS_USED.set(used + 1);
        return true;
    }

    public static void clearToolCallBudget() {
        TOOL_CALLS_USED.remove();
        TOOL_CALLS_MAX.remove();
    }
}
