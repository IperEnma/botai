package com.botai.domain.agenda.model;

import java.util.Objects;

/** Etiqueta de búsqueda/perfil con significado explícito ([type]). */
public record SearchTag(String value, String type) {

    public static final String TYPE_PROFILE = "profile";
    public static final String TYPE_LOCATION = "location";

    public SearchTag {
        Objects.requireNonNull(value, "value");
        if (value.isBlank()) {
            throw new IllegalArgumentException("value cannot be blank");
        }
        value = value.trim();
        if (type == null || type.isBlank()) {
            type = TYPE_PROFILE;
        } else {
            type = type.trim().toLowerCase();
        }
    }

    public static SearchTag profile(String value) {
        return new SearchTag(value, TYPE_PROFILE);
    }

    public static SearchTag location(String value) {
        return new SearchTag(value, TYPE_LOCATION);
    }

    public boolean isProfile() {
        return TYPE_PROFILE.equals(type);
    }

    public boolean isLocation() {
        return TYPE_LOCATION.equals(type);
    }
}
