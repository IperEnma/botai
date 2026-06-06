package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.RatingSummary;
import com.botai.domain.agenda.model.Review;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface ReviewRepository {

    Review save(Review review);

    boolean existsByBookingId(UUID bookingId);

    RatingSummary findRatingSummaryByBusinessId(UUID businessId);

    RatingSummary findRatingSummaryByStaffMemberId(UUID staffMemberId);

    /** Batch: una sola query GROUP BY staff_member_id para evitar N+1 en el listado de staff. */
    Map<UUID, RatingSummary> findRatingSummariesForBusiness(UUID businessId);

    // OPCIONAL (pospuesto, Tarea 19)
    List<Review> findByBusinessId(UUID businessId, int page, int size);
    long countByBusinessId(UUID businessId);
}
