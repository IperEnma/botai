package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.StaffMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface StaffMemberJpaRepository extends JpaRepository<StaffMemberEntity, UUID> {

    @Query("SELECT s FROM AgendaStaffMemberEntity s WHERE :businessId MEMBER OF s.businessIds")
    List<StaffMemberEntity> findByBusinessId(@Param("businessId") UUID businessId);

    @Query("SELECT s FROM AgendaStaffMemberEntity s "
            + "WHERE s.userId = :userId AND :businessId MEMBER OF s.businessIds "
            + "AND s.deletedAt IS NULL")
    java.util.Optional<StaffMemberEntity> findByUserIdAndBusinessId(
            @Param("userId") UUID userId, @Param("businessId") UUID businessId);

    @Query("SELECT s FROM AgendaStaffMemberEntity s "
            + "WHERE :businessId MEMBER OF s.businessIds "
            + "AND s.activo = TRUE AND s.deletedAt IS NULL")
    List<StaffMemberEntity> findActiveByBusinessId(@Param("businessId") UUID businessId);

    @Query("SELECT (COUNT(s) > 0) FROM AgendaStaffMemberEntity s "
            + "WHERE s.id = :id AND :businessId MEMBER OF s.businessIds")
    boolean existsByIdAndBusinessId(@Param("id") UUID id, @Param("businessId") UUID businessId);
}
