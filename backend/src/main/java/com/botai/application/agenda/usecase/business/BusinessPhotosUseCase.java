package com.botai.application.agenda.usecase.business;

import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.BusinessPhoto;
import com.botai.domain.agenda.repository.BusinessPhotoRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.UUID;

@Service
public class BusinessPhotosUseCase {

    private static final int MAX_PHOTOS = 10;

    private final BusinessPhotoRepository photoRepository;
    private final BusinessRepository businessRepository;

    public BusinessPhotosUseCase(BusinessPhotoRepository photoRepository,
                                 BusinessRepository businessRepository) {
        this.photoRepository = photoRepository;
        this.businessRepository = businessRepository;
    }

    @Transactional(readOnly = true)
    public List<BusinessPhoto> list(String tenantId, UUID businessId) {
        validateOwnership(tenantId, businessId);
        return photoRepository.findByBusinessId(businessId);
    }

    @Transactional
    public BusinessPhoto add(String tenantId, UUID businessId, String url) {
        validateOwnership(tenantId, businessId);
        int current = photoRepository.countByBusinessId(businessId);
        if (current >= MAX_PHOTOS) {
            throw new IllegalStateException("El negocio ya tiene el máximo de " + MAX_PHOTOS + " fotos.");
        }
        BusinessPhoto photo = new BusinessPhoto(UUID.randomUUID(), businessId, url, current, LocalDateTime.now());
        return photoRepository.save(photo);
    }

    @Transactional
    public void delete(String tenantId, UUID businessId, UUID photoId) {
        validateOwnership(tenantId, businessId);
        BusinessPhoto photo = photoRepository.findById(photoId)
                .orElseThrow(() -> new NoSuchElementException("Foto no encontrada: " + photoId));
        if (!photo.getBusinessId().equals(businessId)) {
            throw new NoSuchElementException("Foto no encontrada: " + photoId);
        }
        photoRepository.deleteById(photoId);
    }

    private void validateOwnership(String tenantId, UUID businessId) {
        businessRepository.findByIdAndTenantId(businessId, tenantId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }
}
