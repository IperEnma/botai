package com.botai.infrastructure.chatbot.persistence.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "bot")
public class BotEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false, unique = true)
    private String tenantId;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(nullable = false)
    private String name;

    @Column(length = 500)
    private String description;

    @Column(nullable = false)
    private String tier;

    @Column(name = "faq_enabled", nullable = false)
    private boolean faqEnabled = true;

    @Column(name = "ai_enabled", nullable = false)
    private boolean aiEnabled = false;

    @Column(name = "actions_enabled", nullable = false)
    private boolean actionsEnabled = false;

    @Column(name = "whatsapp_phone_number_id")
    private String whatsappPhoneNumberId;

    /** Ciphertext AES-GCM ({@code enc:v1:…}); suele superar 255 chars. */
    @Column(name = "whatsapp_access_token", columnDefinition = "TEXT")
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String whatsappAccessToken;

    @Column(name = "whatsapp_verify_token")
    private String whatsappVerifyToken;

    @Column(name = "created_at", nullable = false)
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime updatedAt;

    /**
     * Solo entrada JSON al crear el bot: sucursales / negocios Agenda ({@code agenda_businesses.id}) que atiende.
     * Obligatorio al menos un UUID; el {@code tenantId} del bot debe coincidir con el de esas filas en Agenda.
     * No se persiste en la tabla {@code bot}; se aplica vía {@link com.botai.application.agenda.usecase.bot.LinkBotToAgendaBusinessesUseCase}.
     */
    @JsonInclude(JsonInclude.Include.NON_EMPTY)
    @Transient
    private List<UUID> linkedAgendaBusinessIds;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getTier() { return tier; }
    public void setTier(String tier) { this.tier = tier; }

    public boolean isFaqEnabled() { return faqEnabled; }
    public void setFaqEnabled(boolean faqEnabled) { this.faqEnabled = faqEnabled; }

    public boolean isAiEnabled() { return aiEnabled; }
    public void setAiEnabled(boolean aiEnabled) { this.aiEnabled = aiEnabled; }

    public boolean isActionsEnabled() { return actionsEnabled; }
    public void setActionsEnabled(boolean actionsEnabled) { this.actionsEnabled = actionsEnabled; }

    public String getWhatsappPhoneNumberId() { return whatsappPhoneNumberId; }
    public void setWhatsappPhoneNumberId(String whatsappPhoneNumberId) { this.whatsappPhoneNumberId = whatsappPhoneNumberId; }

    public String getWhatsappAccessToken() { return whatsappAccessToken; }
    public void setWhatsappAccessToken(String whatsappAccessToken) { this.whatsappAccessToken = whatsappAccessToken; }

    /** Indica si hay token guardado (sin exponer el valor). */
    public boolean isWhatsappAccessTokenConfigured() {
        return whatsappAccessToken != null && !whatsappAccessToken.isBlank();
    }

    @JsonIgnore
    public String getWhatsappVerifyToken() { return whatsappVerifyToken; }
    public void setWhatsappVerifyToken(String whatsappVerifyToken) { this.whatsappVerifyToken = whatsappVerifyToken; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    public List<UUID> getLinkedAgendaBusinessIds() {
        return linkedAgendaBusinessIds;
    }

    public void setLinkedAgendaBusinessIds(List<UUID> linkedAgendaBusinessIds) {
        this.linkedAgendaBusinessIds = linkedAgendaBusinessIds;
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
