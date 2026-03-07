package com.botai.chatbot.infrastructure.persistence.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "faq", indexes = {
    @Index(name = "idx_faq_intent", columnList = "intent"),
    @Index(name = "idx_faq_active", columnList = "active")
})
public class FaqEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "intent", nullable = false, length = 128)
    private String intent;

    @Column(name = "keywords", nullable = false, columnDefinition = "text")
    private String keywords;

    @Column(name = "response", nullable = false, columnDefinition = "text")
    private String response;

    @Column(name = "use_regex", nullable = false)
    private boolean useRegex = false;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getIntent() {
        return intent;
    }

    public void setIntent(String intent) {
        this.intent = intent;
    }

    public String getKeywords() {
        return keywords;
    }

    public void setKeywords(String keywords) {
        this.keywords = keywords;
    }

    public String getResponse() {
        return response;
    }

    public void setResponse(String response) {
        this.response = response;
    }

    public boolean isUseRegex() {
        return useRegex;
    }

    public void setUseRegex(boolean useRegex) {
        this.useRegex = useRegex;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
