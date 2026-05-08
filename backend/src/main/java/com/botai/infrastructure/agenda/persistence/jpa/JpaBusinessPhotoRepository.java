package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.BusinessPhoto;
import com.botai.domain.agenda.repository.BusinessPhotoRepository;
import com.botai.infrastructure.agenda.persistence.mapper.BusinessPhotoMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaBusinessPhotoRepository implements BusinessPhotoRepository {

    private final BusinessPhotoJpaRepository jpa;

    public JpaBusinessPhotoRepository(BusinessPhotoJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public List<BusinessPhoto> findByBusinessId(UUID businessId) {
        return jpa.findByBusinessIdOrderByOrdenAsc(businessId).stream()
                .map(BusinessPhotoMapper::toDomain)
                .toList();
    }

    @Override
    public int countByBusinessId(UUID businessId) {
        return jpa.countByBusinessId(businessId);
    }

    @Override
    public BusinessPhoto save(BusinessPhoto photo) {
        return BusinessPhotoMapper.toDomain(jpa.save(BusinessPhotoMapper.toEntity(photo)));
    }

    @Override
    public Optional<BusinessPhoto> findById(UUID id) {
        return jpa.findById(id).map(BusinessPhotoMapper::toDomain);
    }

    @Override
    public void deleteById(UUID id) {
        jpa.deleteById(id);
    }
}
