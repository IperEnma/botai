package com.botai.agenda.domain.repository;

import com.botai.agenda.domain.model.BusinessPhoto;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BusinessPhotoRepository {

    List<BusinessPhoto> findByBusinessId(UUID businessId);

    int countByBusinessId(UUID businessId);

    BusinessPhoto save(BusinessPhoto photo);

    Optional<BusinessPhoto> findById(UUID id);

    void deleteById(UUID id);
}
