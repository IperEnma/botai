package com.botai.application.agenda.usecase.publicclient;

import com.botai.application.agenda.dto.BookingResponse;
import com.botai.application.agenda.support.AgendaPublicClientSessionService;
import com.botai.domain.agenda.exception.BusinessNotFoundException;
import com.botai.domain.agenda.repository.BusinessRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.UUID;

@Component
public class ListPublicClientBookingsUseCase {

    private final BusinessRepository businessRepository;
    private final VerifyPublicClientPhoneUseCase verifyPublicClientPhoneUseCase;
    private final AgendaPublicClientSessionService sessionService;

    public ListPublicClientBookingsUseCase(BusinessRepository businessRepository,
                                           VerifyPublicClientPhoneUseCase verifyPublicClientPhoneUseCase,
                                           AgendaPublicClientSessionService sessionService) {
        this.businessRepository = businessRepository;
        this.verifyPublicClientPhoneUseCase = verifyPublicClientPhoneUseCase;
        this.sessionService = sessionService;
    }

    public List<BookingResponse> execute(String sessionToken, UUID businessId) {
        var business = businessRepository.findById(businessId)
                .orElseThrow(() -> new BusinessNotFoundException(businessId));
        AgendaPublicClientSessionService.ClientSession session =
                sessionService.requireSessionForTenant(sessionToken, business.getTenantId());
        return verifyPublicClientPhoneUseCase.listUpcomingForUser(businessId, session.userId());
    }
}
