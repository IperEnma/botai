package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.SendPhoneVerificationRequest;
import com.botai.application.agenda.dto.SendPhoneVerificationResponse;
import com.botai.application.agenda.dto.VerifyPhoneVerificationRequest;
import com.botai.application.agenda.dto.VerifyPhoneVerificationResponse;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.application.agenda.support.AgendaPhoneVerificationService;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.repository.BusinessRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/public/businesses/{businessId}/phone-verification")
@Tag(name = "Agenda Public · Phone verification", description = "OTP por WhatsApp al reservar (confirmar titularidad del teléfono)")
public class PublicPhoneVerificationController {

    private final BusinessRepository businessRepository;
    private final AgendaPhoneVerificationService verificationService;

    public PublicPhoneVerificationController(BusinessRepository businessRepository,
                                           AgendaPhoneVerificationService verificationService) {
        this.businessRepository = businessRepository;
        this.verificationService = verificationService;
    }

    @PostMapping("/send")
    @Operation(summary = "Enviar código OTP al teléfono (WhatsApp)")
    public ResponseEntity<SendPhoneVerificationResponse> send(
            @PathVariable UUID businessId,
            @Valid @RequestBody SendPhoneVerificationRequest request) {
        String tenantId = resolveTenantId(businessId);
        String phone = normalizePhone(request.telefono());
        AgendaPhoneVerificationService.SendResult result = verificationService.sendCode(tenantId, phone);
        if (result.immediateTokenWhenDisabled() != null) {
            return ResponseEntity.ok(new SendPhoneVerificationResponse(
                true, "Verificación deshabilitada en este entorno.", null));
        }
        if (result.delivered()) {
            return ResponseEntity.ok(new SendPhoneVerificationResponse(
                true, "Te enviamos un código por WhatsApp.", null));
        }
        if (result.devCodeEcho() != null) {
            return ResponseEntity.ok(new SendPhoneVerificationResponse(
                false, "No se pudo enviar WhatsApp; usá el código de prueba.", result.devCodeEcho()));
        }
        return ResponseEntity.ok(new SendPhoneVerificationResponse(
            false, "No pudimos enviar el código. Revisá el número o probá más tarde.", null));
    }

    @PostMapping("/verify")
    @Operation(summary = "Validar código y obtener token para crear la reserva")
    public ResponseEntity<VerifyPhoneVerificationResponse> verify(
            @PathVariable UUID businessId,
            @Valid @RequestBody VerifyPhoneVerificationRequest request) {
        String tenantId = resolveTenantId(businessId);
        String phone = normalizePhone(request.telefono());
        String token = verificationService.verifyAndIssueToken(tenantId, phone, request.code());
        return ResponseEntity.ok(new VerifyPhoneVerificationResponse(token));
    }

    private String resolveTenantId(UUID businessId) {
        return businessRepository.findById(businessId)
            .map(b -> b.getTenantId())
            .orElseThrow(() -> new BusinessNotFoundException(businessId));
    }

    private static String normalizePhone(String raw) {
        String phone = AgendaPhoneNormalizer.normalize(raw);
        if (!AgendaPhoneNormalizer.isValid(phone)) {
            throw new IllegalArgumentException("Teléfono inválido");
        }
        return phone;
    }
}
