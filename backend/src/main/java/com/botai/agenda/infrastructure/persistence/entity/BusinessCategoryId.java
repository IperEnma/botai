package com.botai.agenda.infrastructure.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class BusinessCategoryId implements Serializable {

    private static final long serialVersionUID = 1L;

    @Column(name = "business_id", nullable = false)
    private UUID businessId;

    @Column(name = "category_id", nullable = false)
    private UUID categoryId;

    public BusinessCategoryId() {
    }

    public BusinessCategoryId(UUID businessId, UUID categoryId) {
        this.businessId = businessId;
        this.categoryId = categoryId;
    }

    public UUID getBusinessId() { return businessId; }
    public void setBusinessId(UUID businessId) { this.businessId = businessId; }
    public UUID getCategoryId() { return categoryId; }
    public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof BusinessCategoryId that)) return false;
        return Objects.equals(businessId, that.businessId)
                && Objects.equals(categoryId, that.categoryId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(businessId, categoryId);
    }
}
