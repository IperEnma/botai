package com.botai.infrastructure.agenda.api;

import com.botai.domain.agenda.exception.AgendaBotNotFoundException;
import com.botai.domain.agenda.exception.AgendaTenantNotResolvedException;
import com.botai.domain.agenda.exception.AgendaUnauthorizedException;
import com.botai.domain.agenda.exception.BookingNotCompletedException;
import com.botai.domain.agenda.exception.ReviewAlreadyExistsException;
import com.botai.domain.agenda.exception.ReviewNotAllowedException;
import com.botai.domain.agenda.exception.BookingNotCancellableException;
import com.botai.domain.agenda.exception.BookingNotFoundException;
import com.botai.domain.agenda.exception.BookingSlotTakenException;
import com.botai.domain.agenda.exception.CancellationNotAllowedException;
import com.botai.domain.agenda.exception.BusinessAlreadyLinkedToOtherBotException;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.exception.CategoryNotFoundException;
import com.botai.domain.agenda.exception.DuplicateCategorySlugException;
import com.botai.domain.agenda.exception.DuplicateTenantEmailException;
import com.botai.domain.agenda.exception.DuplicateTenantNumeroException;
import com.botai.domain.agenda.exception.TenantAccessCodeNotFoundException;
import com.botai.domain.agenda.exception.TenantGoogleLinkConflictException;
import com.botai.domain.agenda.exception.WorkspaceBotMismatchException;
import com.botai.domain.agenda.exception.InvalidPlanConfigurationException;
import com.botai.domain.agenda.exception.NoCreditsException;
import com.botai.domain.agenda.exception.PaymentFailedException;
import com.botai.domain.agenda.exception.PlanDoesNotBelongToBusinessException;
import com.botai.domain.agenda.exception.PlanNotActiveException;
import com.botai.domain.agenda.exception.PlanNotFoundException;
import com.botai.domain.agenda.exception.ServiceNotFoundException;
import com.botai.domain.agenda.exception.SubscriptionExpiredException;
import com.botai.domain.agenda.exception.UserSubscriptionNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.PessimisticLockingFailureException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Handler de excepciones acotado a los controllers del módulo AGENDA.
 *
 * <p>{@code basePackages} apunta a {@code com.botai.infrastructure.agenda.api}
 * para no interceptar excepciones del bot.</p>
 */
@RestControllerAdvice(basePackages = "com.botai.infrastructure.agenda.api")
public class AgendaGlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(AgendaGlobalExceptionHandler.class);

    @ExceptionHandler(AgendaUnauthorizedException.class)
    public ResponseEntity<Map<String, Object>> handleUnauthorized(AgendaUnauthorizedException ex) {
        return response(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", ex.getMessage(), null);
    }

    @ExceptionHandler(ReviewNotAllowedException.class)
    public ResponseEntity<Map<String, Object>> handleReviewNotAllowed(ReviewNotAllowedException ex) {
        return response(HttpStatus.FORBIDDEN, "REVIEW_NOT_ALLOWED", ex.getMessage(), null);
    }

    @ExceptionHandler(BookingNotCompletedException.class)
    public ResponseEntity<Map<String, Object>> handleBookingNotCompleted(BookingNotCompletedException ex) {
        return response(HttpStatus.UNPROCESSABLE_ENTITY, "BOOKING_NOT_COMPLETED", ex.getMessage(), null);
    }

    @ExceptionHandler(ReviewAlreadyExistsException.class)
    public ResponseEntity<Map<String, Object>> handleReviewAlreadyExists(ReviewAlreadyExistsException ex) {
        return response(HttpStatus.CONFLICT, "REVIEW_ALREADY_EXISTS", ex.getMessage(), null);
    }

    @ExceptionHandler(BusinessNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessNotFound(BusinessNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "BUSINESS_NOT_FOUND", ex.getMessage(), null);
    }

    @ExceptionHandler(AgendaTenantNotResolvedException.class)
    public ResponseEntity<Map<String, Object>> handleTenantNotResolved(AgendaTenantNotResolvedException ex) {
        return response(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage(), null);
    }

    @ExceptionHandler(AgendaBotNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleAgendaBotNotFound(AgendaBotNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "BOT_NOT_FOUND", ex.getMessage(), null);
    }

    @ExceptionHandler(WorkspaceBotMismatchException.class)
    public ResponseEntity<Map<String, Object>> handleWorkspaceBotMismatch(WorkspaceBotMismatchException ex) {
        return response(HttpStatus.FORBIDDEN, "BOT_TENANT_MISMATCH", ex.getMessage(), null);
    }

    @ExceptionHandler(BusinessAlreadyLinkedToOtherBotException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessLinkedOtherBot(BusinessAlreadyLinkedToOtherBotException ex) {
        return response(HttpStatus.CONFLICT, "BUSINESS_LINKED_TO_OTHER_BOT", ex.getMessage(), null);
    }

    @ExceptionHandler(CategoryNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleCategoryNotFound(CategoryNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "CATEGORY_NOT_FOUND", ex.getMessage(), null);
    }

    @ExceptionHandler(DuplicateCategorySlugException.class)
    public ResponseEntity<Map<String, Object>> handleDuplicateSlug(DuplicateCategorySlugException ex) {
        return response(HttpStatus.CONFLICT, "DUPLICATE_CATEGORY_SLUG", ex.getMessage(), null);
    }

    @ExceptionHandler(DuplicateTenantEmailException.class)
    public ResponseEntity<Map<String, Object>> handleDuplicateTenantEmail(DuplicateTenantEmailException ex) {
        return response(HttpStatus.CONFLICT, "EMAIL_ALREADY_REGISTERED", ex.getMessage(), null);
    }

    @ExceptionHandler(DuplicateTenantNumeroException.class)
    public ResponseEntity<Map<String, Object>> handleDuplicateTenantNumero(DuplicateTenantNumeroException ex) {
        return response(HttpStatus.CONFLICT, "NUMERO_ALREADY_REGISTERED", ex.getMessage(), null);
    }

    @ExceptionHandler(TenantAccessCodeNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleAccessCodeNotFound(TenantAccessCodeNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "ACCESS_CODE_NOT_FOUND", ex.getMessage(), null);
    }

    @ExceptionHandler(TenantGoogleLinkConflictException.class)
    public ResponseEntity<Map<String, Object>> handleGoogleLinkConflict(TenantGoogleLinkConflictException ex) {
        return response(HttpStatus.CONFLICT, "GOOGLE_LINK_CONFLICT", ex.getMessage(), null);
    }

    @ExceptionHandler(PlanNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handlePlanNotFound(PlanNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "PLAN_NOT_FOUND", ex.getMessage(), null);
    }

    /**
     * Se mapea a 404 (no 403) para no revelar si un plan existe bajo otro
     * business — la semántica desde la perspectiva del cliente es "plan no
     * visible bajo este recurso".
     */
    @ExceptionHandler(PlanDoesNotBelongToBusinessException.class)
    public ResponseEntity<Map<String, Object>> handlePlanMismatch(PlanDoesNotBelongToBusinessException ex) {
        return response(HttpStatus.NOT_FOUND, "PLAN_NOT_FOUND", ex.getMessage(), null);
    }

    @ExceptionHandler(InvalidPlanConfigurationException.class)
    public ResponseEntity<Map<String, Object>> handleInvalidPlanConfig(InvalidPlanConfigurationException ex) {
        return response(HttpStatus.BAD_REQUEST, "INVALID_PLAN_CONFIGURATION", ex.getMessage(), null);
    }

    @ExceptionHandler(UserSubscriptionNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleSubscriptionNotFound(UserSubscriptionNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "SUBSCRIPTION_NOT_FOUND", ex.getMessage(), null);
    }

    /**
     * Plan existe pero está inactivo — no se puede vender. 409 deja claro que
     * el estado del recurso (no el request) es lo que impide la operación.
     */
    @ExceptionHandler(PlanNotActiveException.class)
    public ResponseEntity<Map<String, Object>> handlePlanNotActive(PlanNotActiveException ex) {
        return response(HttpStatus.CONFLICT, "PLAN_NOT_ACTIVE", ex.getMessage(), null);
    }

    /**
     * El gateway de pagos rechazó el cobro. 402 es el código estándar para
     * "pago requerido / pago falló"; incluimos la razón del gateway en el
     * body para que el cliente la muestre al usuario.
     */
    @ExceptionHandler(PaymentFailedException.class)
    public ResponseEntity<Map<String, Object>> handlePaymentFailed(PaymentFailedException ex) {
        Map<String, String> details = new LinkedHashMap<>();
        details.put("reason", ex.getReason() == null ? "UNKNOWN" : ex.getReason());
        return response(HttpStatus.PAYMENT_REQUIRED, "PAYMENT_FAILED", ex.getMessage(), details);
    }

    @ExceptionHandler(BookingNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleBookingNotFound(BookingNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "BOOKING_NOT_FOUND", ex.getMessage(), null);
    }

    @ExceptionHandler(ServiceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleServiceNotFound(ServiceNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "SERVICE_NOT_FOUND", ex.getMessage(), null);
    }

    /**
     * Slot ocupado por otra reserva. 409 para que el cliente reintente con
     * otro horario sin confusión con un 400.
     */
    @ExceptionHandler(BookingSlotTakenException.class)
    public ResponseEntity<Map<String, Object>> handleSlotTaken(BookingSlotTakenException ex) {
        return response(HttpStatus.CONFLICT, "BOOKING_SLOT_TAKEN", ex.getMessage(), null);
    }

    @ExceptionHandler(BookingNotCancellableException.class)
    public ResponseEntity<Map<String, Object>> handleNotCancellable(BookingNotCancellableException ex) {
        return response(HttpStatus.CONFLICT, "BOOKING_NOT_CANCELLABLE", ex.getMessage(), null);
    }

    @ExceptionHandler(CancellationNotAllowedException.class)
    public ResponseEntity<Map<String, Object>> handleCancellationWindow(CancellationNotAllowedException ex) {
        return response(HttpStatus.CONFLICT, "CANCELLATION_NOT_ALLOWED", ex.getMessage(), null);
    }

    @ExceptionHandler(NoCreditsException.class)
    public ResponseEntity<Map<String, Object>> handleNoCredits(NoCreditsException ex) {
        return response(HttpStatus.CONFLICT, "NO_CREDITS", ex.getMessage(), null);
    }

    @ExceptionHandler(SubscriptionExpiredException.class)
    public ResponseEntity<Map<String, Object>> handleSubscriptionExpired(SubscriptionExpiredException ex) {
        return response(HttpStatus.CONFLICT, "SUBSCRIPTION_EXPIRED", ex.getMessage(), null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        List<Map<String, String>> errors = ex.getBindingResult().getFieldErrors().stream()
                .map(this::fieldErrorToMap)
                .toList();
        return response(HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "Request inválido", errors);
    }

    /**
     * Lock de suscripción expiró por timeout de PostgreSQL ({@code lock_timeout}).
     * 409 con mensaje claro en lugar de 500 genérico.
     */
    @ExceptionHandler(PessimisticLockingFailureException.class)
    public ResponseEntity<Map<String, Object>> handleLockTimeout(PessimisticLockingFailureException ex) {
        log.warn("AGENDA: lock pesimista expiró: {}", ex.getMessage());
        return response(HttpStatus.CONFLICT, "LOCK_TIMEOUT",
                "El recurso está siendo modificado por otra operación. Intenta nuevamente.", null);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalArgument(IllegalArgumentException ex) {
        return response(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage(), null);
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, Object>> handleIllegalState(IllegalStateException ex) {
        log.warn("AGENDA: estado inválido: {}", ex.getMessage());
        return response(HttpStatus.CONFLICT, "CONFLICT", ex.getMessage(), null);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleUnexpected(Exception ex) {
        log.error("AGENDA: error inesperado en controller", ex);
        return response(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Ocurrió un error interno. Por favor intenta nuevamente.", null);
    }

    private ResponseEntity<Map<String, Object>> response(HttpStatus status,
                                                         String code,
                                                         String message,
                                                         Object details) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", LocalDateTime.now().toString());
        body.put("status", status.value());
        body.put("code", code);
        body.put("message", message);
        if (details != null) {
            body.put("details", details);
        }
        return ResponseEntity.status(status).body(body);
    }

    private Map<String, String> fieldErrorToMap(FieldError error) {
        Map<String, String> map = new LinkedHashMap<>();
        map.put("field", error.getField());
        map.put("message", error.getDefaultMessage() == null ? "inválido" : error.getDefaultMessage());
        return map;
    }
}
