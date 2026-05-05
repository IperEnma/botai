package com.botai.agenda.infrastructure.api;

import com.botai.agenda.domain.exception.BookingNotCancellableException;
import com.botai.agenda.domain.exception.BookingNotFoundException;
import com.botai.agenda.domain.exception.BookingSlotTakenException;
import com.botai.agenda.domain.exception.CancellationNotAllowedException;
import com.botai.agenda.domain.exception.BusinessNotFoundException;
import com.botai.agenda.domain.exception.CategoryNotFoundException;
import com.botai.agenda.domain.exception.DuplicateCategorySlugException;
import com.botai.agenda.domain.exception.DuplicateTenantEmailException;
import com.botai.agenda.domain.exception.InvalidPlanConfigurationException;
import com.botai.agenda.domain.exception.NoCreditsException;
import com.botai.agenda.domain.exception.PaymentFailedException;
import com.botai.agenda.domain.exception.PlanDoesNotBelongToBusinessException;
import com.botai.agenda.domain.exception.PlanNotActiveException;
import com.botai.agenda.domain.exception.PlanNotFoundException;
import com.botai.agenda.domain.exception.ServiceNotFoundException;
import com.botai.agenda.domain.exception.SubscriptionExpiredException;
import com.botai.agenda.domain.exception.UserSubscriptionNotFoundException;
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
 * <p>{@code basePackages} apunta a {@code com.botai.agenda.infrastructure.api}
 * para no interceptar excepciones del bot.</p>
 */
@RestControllerAdvice(basePackages = "com.botai.agenda.infrastructure.api")
public class AgendaGlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(AgendaGlobalExceptionHandler.class);

    @ExceptionHandler(BusinessNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessNotFound(BusinessNotFoundException ex) {
        return response(HttpStatus.NOT_FOUND, "BUSINESS_NOT_FOUND", ex.getMessage(), null);
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
