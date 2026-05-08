package com.botai.infrastructure.chatbot.persistence.entity;

import jakarta.persistence.*;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "menu", uniqueConstraints = @UniqueConstraint(columnNames = {"tenant_id", "menu_key"}))
public class MenuEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(name = "menu_key", nullable = false)
    private String menuKey;

    @Column(name = "text", columnDefinition = "text", nullable = false)
    private String text;

    @Column(name = "active", nullable = false)
    private boolean active = true;

    @OneToMany(mappedBy = "menu", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @OrderBy("sortOrder ASC")
    private List<MenuOptionEntity> options = new ArrayList<>();

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }
    public String getMenuKey() { return menuKey; }
    public void setMenuKey(String menuKey) { this.menuKey = menuKey; }
    public String getText() { return text; }
    public void setText(String text) { this.text = text; }
    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
    public List<MenuOptionEntity> getOptions() { return options; }
    public void setOptions(List<MenuOptionEntity> options) { this.options = options; }
}
