package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.BusinessPhoto;

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
