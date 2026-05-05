package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.Service;
import com.botai.agenda.infrastructure.persistence.entity.ServiceEntity;

public final class ServiceMapper {

    private ServiceMapper() {
    }

    public static Service toDomain(ServiceEntity entity) {
        if (entity == null) {
            return null;
        }
        return new Service(
                entity.getId(),
                entity.getBusinessId(),
                entity.getNombre(),
                entity.getDescripcion(),
                entity.getDuracionMin(),
                entity.getPrecio(),
                entity.isActivo(),
                entity.getDeletedAt(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public static ServiceEntity toEntity(Service service) {
        if (service == null) {
            return null;
        }
        ServiceEntity entity = new ServiceEntity();
        entity.setId(service.getId());
        entity.setBusinessId(service.getBusinessId());
        entity.setNombre(service.getNombre());
        entity.setDescripcion(service.getDescripcion());
        entity.setDuracionMin(service.getDuracionMin());
        entity.setPrecio(service.getPrecio());
        entity.setActivo(service.isActivo());
        entity.setDeletedAt(service.getDeletedAt());
        entity.setCreatedAt(service.getCreatedAt());
        entity.setUpdatedAt(service.getUpdatedAt());
        return entity;
    }
}
