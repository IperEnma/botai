package com.botai.application.agenda.usecase.publicclient;

import com.botai.application.agenda.dto.BookingResponse;
import com.botai.application.agenda.dto.PublicClientProfileResponse;
import com.botai.application.agenda.dto.VerifyPhoneVerificationResponse;
import com.botai.application.agenda.mapper.BookingDtoMapper;
import com.botai.application.agenda.support.AgendaClientResolver;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.model.Booking;
import com.botai.domain.agenda.model.BookingEstado;
import com.botai.domain.agenda.model.Service;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.BookingRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.ServiceRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class VerifyPublicClientPhoneUseCase {

    private final BusinessRepository businessRepository;
    private final UserRepository userRepository;
    private final BookingRepository bookingRepository;
    private final ServiceRepository serviceRepository;
    private final AgendaPublicClientSessionService sessionService;

    public VerifyPublicClientPhoneUseCase(BusinessRepository businessRepository,
                                          UserRepository userRepository,
                                          BookingRepository bookingRepository,
                                          ServiceRepository serviceRepository,
                                          AgendaPublicClientSessionService sessionService) {
        this.businessRepository = businessRepository;
        this.userRepository = userRepository;
        this.bookingRepository = bookingRepository;
        this.serviceRepository = serviceRepository;
        this.sessionService = sessionService;
    }

    public VerifyPhoneVerificationResponse execute(UUID businessId, String telefonoRaw, String code) {
        var business = businessRepository.findById(businessId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
        String tenantId = business.getTenantId();
        String phone = AgendaPhoneNormalizer.normalize(telefonoRaw);
        if (!AgendaPhoneNormalizer.isValid(phone)) {
            throw new IllegalArgumentException("Teléfono inválido");
        }

        sessionService.verifyOtpCode(tenantId, phone, code);
        AgendaClientResolver.ClientEnsureResult ensured =
                AgendaClientResolver.ensureClientByPhone(userRepository, tenantId, phone);
        User user = ensured.user();

        String sessionToken = sessionService.issueSessionToken(tenantId, user.getId(), phone);
        List<BookingResponse> bookings = listUpcomingForUser(businessId, user.getId());
        PublicClientProfileResponse profile = toProfile(user, ensured.needsName());
        return new VerifyPhoneVerificationResponse(sessionToken, profile, bookings);
    }

    public VerifyPhoneVerificationResponse executeWithoutOtp(UUID businessId, String telefonoRaw) {
        var business = businessRepository.findById(businessId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
        String tenantId = business.getTenantId();
        String phone = AgendaPhoneNormalizer.normalize(telefonoRaw);
        AgendaClientResolver.ClientEnsureResult ensured =
                AgendaClientResolver.ensureClientByPhone(userRepository, tenantId, phone);
        User user = ensured.user();
        String sessionToken = sessionService.issueSessionToken(tenantId, user.getId(), phone);
        return new VerifyPhoneVerificationResponse(
                sessionToken,
                toProfile(user, ensured.needsName()),
                listUpcomingForUser(businessId, user.getId()));
    }

    List<BookingResponse> listUpcomingForUser(UUID businessId, UUID userId) {
        List<Booking> all = bookingRepository.findAllByUserId(userId).stream()
                .filter(b -> businessId.equals(b.getBusinessId()))
                .filter(b -> b.getEstado() == BookingEstado.PENDING || b.getEstado() == BookingEstado.CONFIRMED)
                .filter(b -> !b.getFechaHoraInicio().isBefore(LocalDateTime.now()))
                .sorted(Comparator.comparing(Booking::getFechaHoraInicio))
                .toList();

        Map<UUID, Service> services = serviceRepository.findAllByBusinessId(businessId).stream()
                .collect(Collectors.toMap(Service::getId, s -> s, (a, b) -> a));
        User user = userRepository.findById(userId).orElse(null);

        return all.stream()
                .map(b -> {
                    Service svc = services.get(b.getServiceId());
                    String svcName = svc != null ? svc.getNombre() : null;
                    return BookingDtoMapper.toResponse(b, svcName, user);
                })
                .toList();
    }

    private static PublicClientProfileResponse toProfile(User user, boolean needsName) {
        return new PublicClientProfileResponse(
                user.getId(),
                user.getNombre(),
                user.getTelefono(),
                user.getEmail(),
                needsName);
    }
}
