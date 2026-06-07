package com.botai.application.agenda.usecase.business;

import com.botai.application.agenda.support.AgendaPublicSlug;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.SearchTag;
import com.botai.domain.agenda.repository.BotWorkspaceRegistry;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RegisterBusinessUseCaseTest {

    private BusinessRepository businessRepo;
    private BusinessSettingsRepository settingsRepo;
    private SaveBusinessHoursUseCase saveHours;
    private BotWorkspaceRegistry botWorkspaceRegistry;
    private RegisterBusinessUseCase useCase;

    @BeforeEach
    void setUp() {
        businessRepo = mock(BusinessRepository.class);
        settingsRepo = mock(BusinessSettingsRepository.class);
        saveHours = mock(SaveBusinessHoursUseCase.class);
        botWorkspaceRegistry = mock(BotWorkspaceRegistry.class);
        when(botWorkspaceRegistry.findBotIdByWorkspaceTenantId(anyString())).thenReturn(Optional.empty());
        useCase = new RegisterBusinessUseCase(businessRepo, settingsRepo, saveHours, botWorkspaceRegistry);
    }

    @Test
    void registraNegocioYCreaSettingsPorDefault() {
        String tenantId = "tenant-1";
        UUID ownerId = UUID.randomUUID();

        when(businessRepo.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));
        when(settingsRepo.save(any(BusinessSettings.class))).thenAnswer(inv -> inv.getArgument(0));
        when(saveHours.execute(any(), any(), any())).thenAnswer(inv -> inv.getArgument(2));

        Business result = useCase.execute(
                tenantId,
                "Peluquería Centro",
                "Corte y color",
                ownerId,
                List.of(SearchTag.profile("centro"), SearchTag.profile("corte"))
        );

        // Captura del Business que se pasó a save.
        ArgumentCaptor<Business> businessCaptor = ArgumentCaptor.forClass(Business.class);
        verify(businessRepo).save(businessCaptor.capture());
        Business savedBusiness = businessCaptor.getValue();

        assertEquals(tenantId, savedBusiness.getTenantId(),
                "El Business persistido debe tener el tenantId recibido");
        assertEquals("Peluquería Centro", savedBusiness.getNombre());
        assertEquals(ownerId, savedBusiness.getOwnerUserId());
        assertNotNull(savedBusiness.getPublicSlug());
        assertEquals(
                AgendaPublicSlug.forNewBusiness(savedBusiness.getId(), "Peluquería Centro"),
                savedBusiness.getPublicSlug(),
                "Al registrar el negocio debe asignarse public_slug para URL pública");

        // Captura de los settings: deben ser los defaults del business recién creado.
        ArgumentCaptor<BusinessSettings> settingsCaptor = ArgumentCaptor.forClass(BusinessSettings.class);
        verify(settingsRepo).save(settingsCaptor.capture());
        BusinessSettings savedSettings = settingsCaptor.getValue();

        assertEquals(savedBusiness.getId(), savedSettings.getBusinessId(),
                "Los settings se crean para el mismo businessId devuelto por el repo");
        // Valores default esperados — ver BusinessSettings.defaults().
        assertEquals(4, savedSettings.getHoursCancellationLimit());
        assertEquals(3, savedSettings.getLoyaltyMinAttendances());
        assertEquals(30, savedSettings.getLoyaltyWindowDays());
        assertEquals(7, savedSettings.getExpirationAlertDays());
        assertEquals(2, savedSettings.getExpirationAlertCredits());

        // El ID devuelto debe coincidir con el del save.
        assertEquals(savedBusiness.getId(), result.getId(),
                "El ID del Business devuelto debe matchear el del repo");
    }

    @Test
    void searchTagsNullSeTraducenEnListaVacia() {
        when(businessRepo.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));
        when(settingsRepo.save(any(BusinessSettings.class))).thenAnswer(inv -> inv.getArgument(0));
        when(saveHours.execute(any(), any(), any())).thenAnswer(inv -> inv.getArgument(2));

        useCase.execute("tenant-1", "Sin tags", null, null, null);

        ArgumentCaptor<Business> captor = ArgumentCaptor.forClass(Business.class);
        verify(businessRepo).save(captor.capture());
        assertEquals(0, captor.getValue().getSearchTags().size(),
                "searchTags null se convierte en lista vacía al persistir");
    }

    @Test
    void persisteBotIdCuandoExisteBotParaElTenant() {
        when(businessRepo.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));
        when(settingsRepo.save(any(BusinessSettings.class))).thenAnswer(inv -> inv.getArgument(0));
        when(saveHours.execute(any(), any(), any())).thenAnswer(inv -> inv.getArgument(2));
        when(botWorkspaceRegistry.findBotIdByWorkspaceTenantId("tenant-1")).thenReturn(Optional.of(42L));

        useCase.execute("tenant-1", "Sucursal", null, UUID.randomUUID(), List.of());

        ArgumentCaptor<Business> captor = ArgumentCaptor.forClass(Business.class);
        verify(businessRepo).save(captor.capture());
        assertEquals(42L, captor.getValue().getBotId());
    }
}
