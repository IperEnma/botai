package com.botai.chatbot.domain.model;

/**
 * Domain entity for a lead. Persistence layer maps to JPA entity.
 */
public final class Lead {

    private final String name;
    private final String email;
    private final String source;
    private final String userId;

    public Lead(String name, String email, String source, String userId) {
        this.name = name;
        this.email = email;
        this.source = source;
        this.userId = userId;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getSource() {
        return source;
    }

    public String getUserId() {
        return userId;
    }
}
