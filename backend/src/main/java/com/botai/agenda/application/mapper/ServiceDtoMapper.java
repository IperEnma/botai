package com.botai.agenda.application.mapper;

import com.botai.agenda.application.dto.ServiceResponse;
import com.botai.agenda.domain.model.Service;

public final class ServiceDtoMapper {

    private ServiceDtoMapper() {
    }

    public static ServiceResponse toResponse(Service service) {
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
                service.isActivo()
        );
    }
}
