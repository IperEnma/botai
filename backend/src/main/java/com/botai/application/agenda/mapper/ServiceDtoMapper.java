package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.ServiceResponse;
import com.botai.domain.agenda.model.Service;

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
