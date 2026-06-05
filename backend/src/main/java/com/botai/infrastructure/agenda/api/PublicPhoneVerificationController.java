package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.SendPhoneVerificationRequest;
import com.botai.application.agenda.dto.SendPhoneVerificationResponse;
import com.botai.application.agenda.dto.VerifyPhoneVerificationRequest;
import com.botai.application.agenda.dto.VerifyPhoneVerificationResponse;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.application.agenda.usecase.publicclient.VerifyPublicClientPhoneUseCase;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.infrastructure.agenda.support.HttpRequestClientIp;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/public/businesses/{businessId}/phone-verification")
@Tag(name = "Agenda Public · Phone verification", description = "OTP por WhatsApp → sesión de cliente público")
public class PublicPhoneVerificationController {

    private final BusinessRepository businessRepository;
    private final AgendaPublicClientSessionService sessionService;
    private final VerifyPublicClientPhoneUseCase verifyPublicClientPhoneUseCase;
    private final boolean verificationEnabled;

    public PublicPhoneVerificationController(BusinessRepository businessRepository,
                                           AgendaPublicClientSessionService sessionService,
                                           VerifyPublicClientPhoneUseCase verifyPublicClientPhoneUseCase,
                                           @Value("${agenda.phone.verification.enabled:true}") boolean verificationEnabled) {
        this.businessRepository = businessRepository;
        this.sessionService = sessionService;
        this.verifyPublicClientPhoneUseCase = verifyPublicClientPhoneUseCase;
        this.verificationEnabled = verificationEnabled;
    }

    @PostMapping("/send")
    @Operation(summary = "Enviar código OTP al teléfono (WhatsApp)")
    public ResponseEntity<SendPhoneVerificationResponse> send(
            @PathVariable UUID businessId,
            @Valid @RequestBody SendPhoneVerificationRequest request,
            HttpServletRequest httpRequest) {
        String tenantId = resolveTenantId(businessId);
        String phone = normalizePhone(request.telefono());
        String clientIp = HttpRequestClientIp.resolve(httpRequest);
        AgendaPublicClientSessionService.SendResult result =
                sessionService.sendCode(tenantId, phone, clientIp);
        if (!verificationEnabled) {
            return ResponseEntity.ok(new SendPhoneVerificationResponse(
                true, "Verificación deshabilitada; ingresá cualquier código."));
        }
        if (result.delivered()) {
            return ResponseEntity.ok(new SendPhoneVerificationResponse(
                true, "Te enviamos un código por WhatsApp."));
        }
        return ResponseEntity.ok(new SendPhoneVerificationResponse(
            false, "No pudimos enviar el código. Revisá el número o probá más tarde."));
    }

    @PostMapping("/verify")
    @Operation(summary = "Validar OTP y abrir sesión de cliente (perfil + reservas)")
    public ResponseEntity<VerifyPhoneVerificationResponse> verify(
            @PathVariable UUID businessId,
            @Valid @RequestBody VerifyPhoneVerificationRequest request,
            HttpServletRequest httpRequest) {
        String phone = normalizePhone(request.telefono());
        String clientIp = HttpRequestClientIp.resolve(httpRequest);
        VerifyPhoneVerificationResponse body = verificationEnabled
                ? verifyPublicClientPhoneUseCase.execute(businessId, phone, request.code(), clientIp)
                : verifyPublicClientPhoneUseCase.executeWithoutOtp(businessId, phone, clientIp);
        return ResponseEntity.ok(body);
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
