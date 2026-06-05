package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.util.UUID;

@Entity
@Table(name = "agenda_security_audit_log", indexes = {
        @Index(name = "idx_agenda_security_audit_created_at", columnList = "created_at"),
        @Index(name = "idx_agenda_security_audit_phone_event_created",
                columnList = "phone_hash, event_type, created_at"),
        @Index(name = "idx_agenda_security_audit_ip_event_created",
                columnList = "client_ip, event_type, created_at")
})
public class AgendaSecurityAuditEntity extends BaseAuditableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "event_type", nullable = false, length = 40)
    private String eventType;

    @Column(name = "outcome", nullable = false, length = 16)
    private String outcome;

    @Column(name = "tenant_id", length = 64)
    private String tenantId;

    @Column(name = "client_ip", length = 64)
    private String clientIp;

    @Column(name = "phone_hash", length = 64)
    private String phoneHash;

    @Column(name = "token_hash", length = 64)
    private String tokenHash;

    @Column(name = "detail", length = 500)
    private String detail;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }
    public String getEventType() { return eventType; }
    public void setEventType(String eventType) { this.eventType = eventType; }
    public String getOutcome() { return outcome; }
    public void setOutcome(String outcome) { this.outcome = outcome; }
    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public String getClientIp() { return clientIp; }
    public void setClientIp(String clientIp) { this.clientIp = clientIp; }
    public String getPhoneHash() { return phoneHash; }
    public void setPhoneHash(String phoneHash) { this.phoneHash = phoneHash; }
    public String getTokenHash() { return tokenHash; }
    public void setTokenHash(String tokenHash) { this.tokenHash = tokenHash; }
    public String getDetail() { return detail; }
    public void setDetail(String detail) { this.detail = detail; }
}
