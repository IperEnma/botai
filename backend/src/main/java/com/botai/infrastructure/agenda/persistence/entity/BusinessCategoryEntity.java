package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Index;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(
        name = "agenda_business_categories",
        indexes = @Index(name = "idx_abc_category", columnList = "category_id"))
public class BusinessCategoryEntity {

    @EmbeddedId
    private BusinessCategoryId id;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public BusinessCategoryEntity() {
    }

    public BusinessCategoryEntity(BusinessCategoryId id) {
        this.id = id;
    }

    public BusinessCategoryId getId() { return id; }
    public void setId(BusinessCategoryId id) { this.id = id; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
