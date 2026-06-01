package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.domain.agenda.model.Service;

import java.util.List;
import java.util.UUID;

public final class ServiceDtoMapper {

    private ServiceDtoMapper() {
    }

    public static ServiceResponse toResponse(Service service) {
        return toResponse(service, List.of());
    }

    public static ServiceResponse toResponse(Service service, List<UUID> staffMemberIds) {
        if (service == null) {
            return null;
        }
        return new ServiceResponse(
                service.getId(),
                service.getBusinessId(),
                service.getNombre(),
                service.getDescripcion(),
                service.getDuracionMin(),
                service.getPrecio(),
                service.isActivo(),
                service.getSchedulingMode().name(),
                staffMemberIds != null ? staffMemberIds : List.of()
        );
    }
}
