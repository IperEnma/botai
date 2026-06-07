package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.UploadedFileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UploadedFileJpaRepository extends JpaRepository<UploadedFileEntity, String> {
}
