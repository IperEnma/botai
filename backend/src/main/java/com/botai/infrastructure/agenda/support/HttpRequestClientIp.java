package com.botai.infrastructure.agenda.support;

import jakarta.servlet.http.HttpServletRequest;

public final class HttpRequestClientIp {

    private HttpRequestClientIp() {}

    public static String resolve(HttpServletRequest request) {
        if (request == null) {
            return "unknown";
        }
        String xff = request.getHeader("X-Forwarded-For");
        if (xff != null && !xff.isBlank()) {
            return xff.split(",")[0].trim();
        }
        String remote = request.getRemoteAddr();
        return remote != null && !remote.isBlank() ? remote : "unknown";
    }
}
