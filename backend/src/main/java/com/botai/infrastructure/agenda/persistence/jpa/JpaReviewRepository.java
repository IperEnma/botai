package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.domain.agenda.model.RatingSummary;
import com.botai.domain.agenda.model.Review;
import com.botai.domain.agenda.repository.ReviewRepository;
import com.botai.infrastructure.agenda.persistence.entity.ReviewEntity;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Repository
public class JpaReviewRepository implements ReviewRepository {

    private final ReviewJpaRepository jpa;

    public JpaReviewRepository(ReviewJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public Review save(Review review) {
        ReviewEntity entity = toEntity(review);
        ReviewEntity saved = jpa.save(entity);
        return toDomain(saved);
    }

    @Override
    public boolean existsByBookingId(UUID bookingId) {
        return jpa.existsByBookingId(bookingId);
    }

    @Override
    public RatingSummary findRatingSummaryByBusinessId(UUID businessId) {
        Double avg = jpa.avgByBusiness(businessId);
        if (avg == null) {
            return RatingSummary.empty();
        }
        long count = jpa.countByBusiness(businessId);
        return new RatingSummary(avg, (int) count);
    }

    @Override
    public RatingSummary findRatingSummaryByStaffMemberId(UUID staffMemberId) {
        Double avg = jpa.avgByStaff(staffMemberId);
        if (avg == null) {
            return RatingSummary.empty();
        }
        long count = jpa.countByStaff(staffMemberId);
        return new RatingSummary(avg, (int) count);
    }

    @Override
    public Map<UUID, RatingSummary> findRatingSummariesForBusiness(UUID businessId) {
        List<Object[]> rows = jpa.staffRatingsRaw(businessId);
        Map<UUID, RatingSummary> result = new HashMap<>();
        for (Object[] row : rows) {
            UUID staffId = (UUID) row[0];
            Double avg = (Double) row[1];
            long count = ((Number) row[2]).longValue();
            result.put(staffId, new RatingSummary(avg, (int) count));
        }
        return result;
    }

    @Override
    public List<Review> findByBusinessId(UUID businessId, int page, int size) {
        return jpa.findByBusinessIdPaged(businessId, PageRequest.of(page, size))
                .stream()
                .map(this::toDomain)
                .toList();
    }

    @Override
    public long countByBusinessId(UUID businessId) {
        return jpa.countByBusiness(businessId);
    }

    private ReviewEntity toEntity(Review review) {
        ReviewEntity entity = new ReviewEntity();
        entity.setId(review.getId() != null ? review.getId() : UUID.randomUUID());
        entity.setBusinessId(review.getBusinessId());
        entity.setBookingId(review.getBookingId());
        entity.setAgendaUserId(review.getAgendaUserId());
        entity.setStaffMemberId(review.getStaffMemberId());
        entity.setRating(review.getRating());
        entity.setComentario(review.getComentario());
        entity.setCreatedAt(review.getCreatedAt() != null ? review.getCreatedAt() : LocalDateTime.now());
        return entity;
    }

    private Review toDomain(ReviewEntity entity) {
        return new Review(
                entity.getId(),
                entity.getBusinessId(),
                entity.getBookingId(),
                entity.getAgendaUserId(),
                entity.getStaffMemberId(),
                entity.getRating(),
                entity.getComentario(),
                entity.getCreatedAt()
        );
    }
}
