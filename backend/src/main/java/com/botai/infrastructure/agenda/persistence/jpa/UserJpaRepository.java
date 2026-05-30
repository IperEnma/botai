package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserJpaRepository extends JpaRepository<UserEntity, UUID> {

    Optional<UserEntity> findByTenantIdAndEmail(String tenantId, String email);

    @Query("SELECT u FROM UserEntity u WHERE u.tenantId = :tenantId AND u.tipoUsuario = 'CLIENT' " +
           "AND (:q = '' OR LOWER(u.nombre) LIKE LOWER(CONCAT('%', :q, '%')) OR u.telefono LIKE CONCAT('%', :q, '%')) " +
           "ORDER BY u.nombre ASC")
    List<UserEntity> searchClients(@Param("tenantId") String tenantId, @Param("q") String q);
}
