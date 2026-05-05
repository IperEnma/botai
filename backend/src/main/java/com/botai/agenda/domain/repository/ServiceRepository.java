package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.Service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ServiceRepository {

    Service save(Service service);

    Optional<Service> findById(UUID id);

    List<Service> findAllByBusinessId(UUID businessId);

    List<Service> findAllActiveByBusinessId(UUID businessId);

    void softDelete(UUID id);
}
