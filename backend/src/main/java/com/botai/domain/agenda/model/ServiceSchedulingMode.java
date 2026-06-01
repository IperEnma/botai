package com.botai.domain.agenda.model;

public enum ServiceSchedulingMode {
    GENERAL,
    BY_STAFF;

    public static ServiceSchedulingMode fromString(String value) {
        if (value == null || value.isBlank()) {
            return GENERAL;
        }
        return ServiceSchedulingMode.valueOf(value.trim().toUpperCase());
    }
}
