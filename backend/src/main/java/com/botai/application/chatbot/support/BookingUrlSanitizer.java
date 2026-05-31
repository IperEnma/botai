package com.botai.application.chatbot.support;

import java.net.URI;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Detecta URLs de agendado de terceros (Calendly, etc.) que el LLM no debe enviar al cliente.
 */
public final class BookingUrlSanitizer {

    private static final Pattern HTTP_URL = Pattern.compile("(?i)https?://[^\\s)>\\]]+");

    private static final List<String> BLOCKED_BOOKING_HOST_SUFFIXES = List.of(
        "calendly.com",
        "booksy.com",
        "fresha.com",
        "acuityscheduling.com",
        "appointlet.com",
        "simplybook.me",
        "setmore.com",
        "square.site",
        "hubspot.com"
    );

    private BookingUrlSanitizer() {}

    public static boolean containsHttpUrl(String text) {
        return text != null && HTTP_URL.matcher(text).find();
    }

    /** true si hay alguna URL de un dominio de reservas externo conocido. */
    public static boolean containsBlockedThirdPartyBookingUrl(String text) {
        if (text == null || text.isBlank()) {
            return false;
        }
        Matcher m = HTTP_URL.matcher(text);
        while (m.find()) {
            String host = hostOf(m.group());
            if (host != null && isBlockedHost(host)) {
                return true;
            }
        }
        return false;
    }

    /** true si hay URL http(s) y alguna no pertenece al host del frontend configurado. */
    public static boolean containsUrlOutsideAllowedHost(String text, String allowedHost) {
        if (text == null || text.isBlank() || !containsHttpUrl(text)) {
            return false;
        }
        if (containsBlockedThirdPartyBookingUrl(text)) {
            return true;
        }
        if (allowedHost == null || allowedHost.isBlank()) {
            return true;
        }
        Matcher m = HTTP_URL.matcher(text);
        while (m.find()) {
            String host = hostOf(m.group());
            if (host != null && !host.equalsIgnoreCase(allowedHost)) {
                return true;
            }
        }
        return false;
    }

    private static boolean isBlockedHost(String host) {
        String h = host.toLowerCase();
        for (String suffix : BLOCKED_BOOKING_HOST_SUFFIXES) {
            if (h.equals(suffix) || h.endsWith("." + suffix)) {
                return true;
            }
        }
        return false;
    }

    private static String hostOf(String url) {
        try {
            URI uri = URI.create(url.strip());
            return uri.getHost();
        } catch (Exception e) {
            return null;
        }
    }
}
