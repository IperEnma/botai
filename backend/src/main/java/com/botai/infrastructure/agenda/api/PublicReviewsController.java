package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.CreateReviewRequest;
import com.botai.application.agenda.dto.ReviewResponse;
import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.application.agenda.usecase.review.CreateReviewUseCase;
import com.botai.domain.agenda.model.Review;
import com.botai.infrastructure.agenda.support.HttpRequestClientIp;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/public/businesses/{businessId}/reviews")
@Tag(name = "Agenda Public · Reviews", description = "Reseñas de negocios (clientes con sesión OTP)")
public class PublicReviewsController {

    private final CreateReviewUseCase createReviewUseCase;

    public PublicReviewsController(CreateReviewUseCase createReviewUseCase) {
        this.createReviewUseCase = createReviewUseCase;
    }

    @PostMapping
    @Operation(summary = "Crea una reseña para una reserva COMPLETADA")
    public ResponseEntity<ReviewResponse> create(
            @PathVariable("businessId") UUID businessId,
            @RequestHeader(AgendaPublicClientSessionService.SESSION_HEADER) String sessionToken,
            @Valid @RequestBody CreateReviewRequest request,
            HttpServletRequest httpRequest) {

        String clientIp = HttpRequestClientIp.resolve(httpRequest);

        Review review = createReviewUseCase.execute(
                businessId,
                request.bookingId(),
                request.rating(),
                request.comentario(),
                sessionToken,
                clientIp
        );

        return ResponseEntity.status(HttpStatus.CREATED).body(toResponse(review));
    }

    private ReviewResponse toResponse(Review review) {
        return new ReviewResponse(
                review.getId(),
                review.getBusinessId(),
                review.getBookingId(),
                review.getStaffMemberId(),
                review.getRating(),
                review.getComentario(),
                review.getCreatedAt()
        );
    }
}
