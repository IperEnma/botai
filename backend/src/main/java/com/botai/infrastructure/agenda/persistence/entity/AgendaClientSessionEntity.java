package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "agenda_client_sessions", indexes = {
        @Index(name = "idx_agenda_client_sessions_expires_at", columnList = "expires_at")
})
public class AgendaClientSessionEntity extends BaseAuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "token_hash", nullable = false, unique = true, length = 64)
    private String tokenHash;

    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "phone_hash", nullable = false, length = 64)
    private String phoneHash;

    @Column(name = "phone_normalized", nullable = false, length = 32)
    private String phoneNormalized;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getTokenHash() { return tokenHash; }
    public void setTokenHash(String tokenHash) { this.tokenHash = tokenHash; }
    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getPhoneHash() { return phoneHash; }
    public void setPhoneHash(String phoneHash) { this.phoneHash = phoneHash; }
    public String getPhoneNormalized() { return phoneNormalized; }
    public void setPhoneNormalized(String phoneNormalized) { this.phoneNormalized = phoneNormalized; }
    public LocalDateTime getExpiresAt() { return expiresAt; }
    public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
}
