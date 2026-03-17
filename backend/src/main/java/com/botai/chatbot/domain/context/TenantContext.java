package com.botai.chatbot.domain.context;

/**
 * Contexto del tenant actual para la petición (p. ej. en tools que no reciben tenant por argumento).
 * Se establece antes de invocar al modelo con tools y se limpia después.
 */
public final class TenantContext {

    private static final ThreadLocal<String> TENANT_HOLDER = new ThreadLocal<>();
    private static final ThreadLocal<String> USER_ID_HOLDER = new ThreadLocal<>();

    public static void set(String tenantId) {
        TENANT_HOLDER.set(tenantId);
    }

    public static String get() {
        return TENANT_HOLDER.get();
    }

    public static void setUserId(String userId) {
        USER_ID_HOLDER.set(userId);
    }

    public static String getUserId() {
        return USER_ID_HOLDER.get();
    }

    public static void clear() {
        TENANT_HOLDER.remove();
        USER_ID_HOLDER.remove();
    }
}
