package com.botai.chatbot.infrastructure.persistence.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "menu_trigger", uniqueConstraints = @UniqueConstraint(columnNames = {"tenant_id", "trigger_word"}))
public class MenuTriggerEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "trigger_word", nullable = false, length = 64)
    private String triggerWord;

    @Column(name = "menu_key", nullable = false, length = 64)
    private String menuKey;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public String getTriggerWord() { return triggerWord; }
    public void setTriggerWord(String triggerWord) { this.triggerWord = triggerWord; }
    public String getMenuKey() { return menuKey; }
    public void setMenuKey(String menuKey) { this.menuKey = menuKey; }
}
