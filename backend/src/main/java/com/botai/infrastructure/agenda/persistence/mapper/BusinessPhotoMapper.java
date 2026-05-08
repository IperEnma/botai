package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.BusinessPhoto;
import com.botai.infrastructure.agenda.persistence.entity.BusinessPhotoEntity;

public final class BusinessPhotoMapper {

    private BusinessPhotoMapper() {}

    public static BusinessPhoto toDomain(BusinessPhotoEntity e) {
        return new BusinessPhoto(e.getId(), e.getBusinessId(), e.getUrl(), e.getOrden(), e.getCreatedAt());
    }

    public static BusinessPhotoEntity toEntity(BusinessPhoto p) {
        BusinessPhotoEntity e = new BusinessPhotoEntity();
        e.setId(p.getId());
        e.setBusinessId(p.getBusinessId());
        e.setUrl(p.getUrl());
        e.setOrden(p.getOrden());
        e.setCreatedAt(p.getCreatedAt());
        return e;
    }
}
