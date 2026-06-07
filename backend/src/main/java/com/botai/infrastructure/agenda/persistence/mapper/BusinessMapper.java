package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.SearchTag;
import com.botai.infrastructure.agenda.persistence.entity.BusinessEntity;

import java.util.List;

/**
 * Mapper estático Business ↔ BusinessEntity.
 * <p>Las etiquetas tipadas viven en {@code agenda_business_tags}, no en la fila del negocio.</p>
 */
public final class BusinessMapper {

    private BusinessMapper() {
    }

    public static Business toDomain(BusinessEntity entity, List<SearchTag> tags) {
        if (entity == null) {
            return null;
        }
        List<SearchTag> searchTags = tags == null ? List.of() : List.copyOf(tags);
        return new Business(
                entity.getId(),
                entity.getTenantId(),
                entity.getNombre(),
                entity.getDescripcion(),
                entity.getOwnerUserId(),
                searchTags,
                entity.isActivo(),
                entity.getLogoUrl(),
                entity.getColorPrimario(),
                entity.getInstagramUrl(),
                entity.getTiktokUrl(),
                entity.getFacebookUrl(),
                entity.getColorFondo(),
                entity.getFontFamily(),
                entity.getPublicSlug(),
                entity.getCompanySlug(),
                entity.getBotId(),
                entity.getDireccion(),
                entity.getBannerUrl(),
                entity.getDeletedAt(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public static BusinessEntity toEntity(Business business) {
        if (business == null) {
            return null;
        }
        BusinessEntity entity = new BusinessEntity();
        entity.setId(business.getId());
        entity.setTenantId(business.getTenantId());
        entity.setNombre(business.getNombre());
        entity.setDescripcion(business.getDescripcion());
        entity.setOwnerUserId(business.getOwnerUserId());
        entity.setActivo(business.isActivo());
        entity.setLogoUrl(business.getLogoUrl());
        entity.setColorPrimario(business.getColorPrimario());
        entity.setInstagramUrl(business.getInstagramUrl());
        entity.setTiktokUrl(business.getTiktokUrl());
        entity.setFacebookUrl(business.getFacebookUrl());
        entity.setColorFondo(business.getColorFondo());
        entity.setFontFamily(business.getFontFamily());
        entity.setPublicSlug(business.getPublicSlug());
        entity.setCompanySlug(business.getCompanySlug());
        entity.setBotId(business.getBotId());
        entity.setDireccion(business.getDireccion());
        entity.setBannerUrl(business.getBannerUrl());
        entity.setDeletedAt(business.getDeletedAt());
        entity.setCreatedAt(business.getCreatedAt());
        entity.setUpdatedAt(business.getUpdatedAt());
        return entity;
    }
}
