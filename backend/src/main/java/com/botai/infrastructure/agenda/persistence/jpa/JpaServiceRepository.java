package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.infrastructure.agenda.persistence.entity.ServiceEntity;
import com.botai.infrastructure.agenda.persistence.mapper.ServiceMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaServiceRepository implements ServiceRepository {

    private final ServiceJpaRepository jpa;

    public JpaServiceRepository(ServiceJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Service save(Service service) {
        ServiceEntity entity = ServiceMapper.toEntity(service);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        ServiceEntity saved = jpa.save(entity);
        return ServiceMapper.toDomain(saved);
    }

    @Override
    public Optional<Service> findById(UUID id) {
        return jpa.findByIdAndDeletedAtIsNull(id).map(ServiceMapper::toDomain);
    }

    @Override
    public List<Service> findAllByBusinessId(UUID businessId) {
        return jpa.findAllByBusinessIdAndDeletedAtIsNull(businessId).stream()
                .map(ServiceMapper::toDomain)
                .toList();
    }

    @Override
    public List<Service> findAllActiveByBusinessId(UUID businessId) {
        return jpa.findAllByBusinessIdAndActivoTrueAndDeletedAtIsNull(businessId).stream()
                .map(ServiceMapper::toDomain)
                .toList();
    }

    @Override
    @org.springframework.transaction.annotation.Transactional
    public void softDelete(UUID id) {
        jpa.softDelete(id);
    }
}
