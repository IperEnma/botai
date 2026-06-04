package com.botai.infrastructure.agenda.api;

import com.botai.application.agenda.dto.BookingResponse;
import com.botai.application.agenda.dto.PublicClientProfileResponse;
import com.botai.application.agenda.dto.UpdatePublicClientProfileRequest;
import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.application.agenda.usecase.publicclient.ListPublicClientBookingsUseCase;
import com.botai.application.agenda.usecase.publicclient.UpdatePublicClientProfileUseCase;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/agenda/public/me")
@Tag(name = "Agenda Public · Client session", description = "Cliente público verificado por teléfono (OTP)")
public class PublicClientMeController {

    private final ListPublicClientBookingsUseCase listBookings;
    private final UpdatePublicClientProfileUseCase updateProfile;

    public PublicClientMeController(ListPublicClientBookingsUseCase listBookings,
                                    UpdatePublicClientProfileUseCase updateProfile) {
        this.listBookings = listBookings;
        this.updateProfile = updateProfile;
    }

    @GetMapping("/bookings")
    @Operation(summary = "Mis reservas futuras en un negocio (sesión OTP)")
    public ResponseEntity<List<BookingResponse>> listBookings(
            @RequestHeader(AgendaPublicClientSessionService.SESSION_HEADER) String sessionToken,
            @RequestParam("businessId") UUID businessId) {
        return ResponseEntity.ok(listBookings.execute(sessionToken, businessId));
    }

    @PatchMapping("/profile")
    @Operation(summary = "Completar nombre (primera vez)")
    public ResponseEntity<PublicClientProfileResponse> updateProfile(
            @RequestHeader(AgendaPublicClientSessionService.SESSION_HEADER) String sessionToken,
            @Valid @RequestBody UpdatePublicClientProfileRequest request) {
        return ResponseEntity.ok(updateProfile.execute(sessionToken, request.nombre()));
    }
}
