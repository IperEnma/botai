package com.botai.chatbot.infrastructure.persistence.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
@Table(name = "menu_option")
public class MenuOptionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "menu_id", nullable = false)
    private MenuEntity menu;

    @Column(name = "option_key", nullable = false, length = 16)
    private String optionKey;

    @Column(name = "target_menu_key", nullable = false, length = 64)
    private String targetMenuKey;

    @Column(name = "label", nullable = false)
    private String label;

    @Column(name = "sort_order", nullable = false)
    private int sortOrder = 0;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    @JsonIgnore
    public MenuEntity getMenu() { return menu; }
    public void setMenu(MenuEntity menu) { this.menu = menu; }
    public String getOptionKey() { return optionKey; }
    public void setOptionKey(String optionKey) { this.optionKey = optionKey; }
    public String getTargetMenuKey() { return targetMenuKey; }
    public void setTargetMenuKey(String targetMenuKey) { this.targetMenuKey = targetMenuKey; }
    public String getLabel() { return label; }
    public void setLabel(String label) { this.label = label; }
    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }
}
