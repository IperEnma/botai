package com.botai.infrastructure.agenda.persistence.mapper;

import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.ServiceSchedulingMode;
import com.botai.infrastructure.agenda.persistence.entity.ServiceEntity;

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
                ServiceSchedulingMode.fromString(entity.getSchedulingMode()),
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
        entity.setSchedulingMode(service.getSchedulingMode().name());
        entity.setDeletedAt(service.getDeletedAt());
        entity.setCreatedAt(service.getCreatedAt());
        entity.setUpdatedAt(service.getUpdatedAt());
        return entity;
    }
}
