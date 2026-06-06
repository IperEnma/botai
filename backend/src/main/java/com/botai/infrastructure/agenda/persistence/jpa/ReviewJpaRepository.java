package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.infrastructure.agenda.persistence.entity.ReviewEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ReviewJpaRepository extends JpaRepository<ReviewEntity, UUID> {

    boolean existsByBookingId(UUID bookingId);

    @Query("SELECT AVG(r.rating) FROM ReviewEntity r WHERE r.businessId = :businessId")
    Double avgByBusiness(@Param("businessId") UUID businessId);

    @Query("SELECT COUNT(r) FROM ReviewEntity r WHERE r.businessId = :businessId")
    long countByBusiness(@Param("businessId") UUID businessId);

    @Query("SELECT AVG(r.rating) FROM ReviewEntity r WHERE r.staffMemberId = :staffId")
    Double avgByStaff(@Param("staffId") UUID staffId);

    @Query("SELECT COUNT(r) FROM ReviewEntity r WHERE r.staffMemberId = :staffId")
    long countByStaff(@Param("staffId") UUID staffId);

    @Query("SELECT r.staffMemberId, AVG(r.rating), COUNT(r) FROM ReviewEntity r " +
           "WHERE r.businessId = :businessId AND r.staffMemberId IS NOT NULL " +
           "GROUP BY r.staffMemberId")
    List<Object[]> staffRatingsRaw(@Param("businessId") UUID businessId);

    @Query("SELECT r FROM ReviewEntity r WHERE r.businessId = :businessId ORDER BY r.createdAt DESC")
    List<ReviewEntity> findByBusinessIdPaged(@Param("businessId") UUID businessId,
                                             org.springframework.data.domain.Pageable pageable);
}
