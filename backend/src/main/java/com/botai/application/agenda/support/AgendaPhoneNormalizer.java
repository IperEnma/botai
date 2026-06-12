package com.botai.application.agenda.support;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Normalización canónica de teléfonos Agenda: solo dígitos con código de país (E.164 sin {@code +}).
 * Ej. Uruguay {@code 099123456} → {@code 59899123456}; WhatsApp {@code 59899123456} se mantiene.
 */
public final class AgendaPhoneNormalizer {

    private static volatile String defaultCountryCode = "598";

    private AgendaPhoneNormalizer() {}

    public static void configureDefaultCountryCode(String countryCodeDigits) {
        if (countryCodeDigits != null && !countryCodeDigits.isBlank()) {
            defaultCountryCode = digitsOnly(countryCodeDigits);
        }
    }

    public static String defaultCountryCode() {
        return defaultCountryCode;
    }

    public static String normalize(String raw) {
        return normalize(raw, defaultCountryCode);
    }

    public static String normalize(String raw, String countryCodeDigits) {
        String digits = digitsOnly(raw);
        if (digits.isEmpty()) {
            return "";
        }
        String cc = digitsOnly(countryCodeDigits);
        if (cc.isEmpty()) {
            cc = defaultCountryCode;
        }
        return toCanonical(digits, cc);
    }

    public static String normalizeOrNull(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String n = normalize(raw);
        return n.isEmpty() ? null : n;
    }

    public static boolean isValid(String raw) {
        String n = normalize(raw);
        String cc = defaultCountryCode();
        int min = cc.length() + 6;
        return n.length() >= min;
    }

    /**
     * Variantes para comparar con datos legacy (p. ej. {@code 099…} guardado sin código de país).
     */
    public static List<String> matchCandidates(String raw) {
        return matchCandidates(raw, defaultCountryCode);
    }

    /** Comparación robusta: normaliza ambos lados (p. ej. {@code 097205089} ≡ {@code 59897205089}). */
    public static boolean phonesMatch(String stored, String input) {
        if (stored == null || stored.isBlank() || input == null || input.isBlank()) {
            return false;
        }
        String a = normalize(stored);
        String b = normalize(input);
        return !a.isEmpty() && a.equals(b);
    }

    public static List<String> matchCandidates(String raw, String countryCodeDigits) {
        String cc = digitsOnly(countryCodeDigits);
        if (cc.isEmpty()) {
            cc = defaultCountryCode;
        }
        String canonical = normalize(raw, cc);
        if (!isValid(canonical)) {
            return List.of();
        }
        Set<String> keys = new LinkedHashSet<>();
        keys.add(canonical);
        if (canonical.startsWith(cc) && canonical.length() > cc.length()) {
            String local = canonical.substring(cc.length());
            keys.add("0" + local);
            keys.add(local);
        }
        return new ArrayList<>(keys);
    }

    public static String digitsOnly(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.replaceAll("\\D", "");
    }

    private static String toCanonical(String digits, String countryCode) {
        if (digits.startsWith(countryCode) && digits.length() >= countryCode.length() + 6) {
            return digits;
        }
        if (looksLikeInternational(digits, countryCode)) {
            return digits;
        }
        if (digits.startsWith("0") && digits.length() >= 8) {
            return countryCode + digits.substring(1);
        }
        if (digits.length() <= 10) {
            return countryCode + digits;
        }
        return digits;
    }

    private static boolean looksLikeInternational(String digits, String homeCountryCode) {
        if (digits.length() < 11) {
            return false;
        }
        if (digits.startsWith(homeCountryCode)) {
            return true;
        }
        return !digits.startsWith("0");
    }
}
