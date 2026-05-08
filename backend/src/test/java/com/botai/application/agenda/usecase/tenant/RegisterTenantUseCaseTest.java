package com.botai.application.agenda.usecase.tenant;

import com.botai.application.agenda.dto.RegisterTenantRequest;
import com.botai.application.agenda.dto.RegisterTenantResponse;
import com.botai.domain.agenda.exception.DuplicateTenantEmailException;
import com.botai.domain.agenda.exception.DuplicateTenantNumeroException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.Category;
import com.botai.domain.agenda.model.TenantAccount;
import com.botai.domain.agenda.model.TenantConfig;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.BotWorkspaceRegistry;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.domain.agenda.repository.CategoryRepository;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import com.botai.domain.agenda.repository.TenantConfigRepository;
import com.botai.domain.agenda.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RegisterTenantUseCaseTest {

    private TenantAccountRepository tenantAccountRepo;
    private UserRepository userRepo;
    private TenantConfigRepository tenantConfigRepo;
    private BusinessRepository businessRepo;
    private BusinessSettingsRepository businessSettingsRepo;
    private CategoryRepository categoryRepo;
    private BusinessCategoryRepository businessCategoryRepo;
    private BotWorkspaceRegistry botWorkspaceRegistry;

    private RegisterTenantUseCase useCase;

    @BeforeEach
    void setUp() {
        tenantAccountRepo = mock(TenantAccountRepository.class);
        userRepo = mock(UserRepository.class);
        tenantConfigRepo = mock(TenantConfigRepository.class);
        businessRepo = mock(BusinessRepository.class);
        businessSettingsRepo = mock(BusinessSettingsRepository.class);
        categoryRepo = mock(CategoryRepository.class);
        businessCategoryRepo = mock(BusinessCategoryRepository.class);
        botWorkspaceRegistry = mock(BotWorkspaceRegistry.class);

        useCase = new RegisterTenantUseCase(
                tenantAccountRepo,
                userRepo,
                tenantConfigRepo,
                businessRepo,
                businessSettingsRepo,
                categoryRepo,
                businessCategoryRepo,
                botWorkspaceRegistry
        );

        when(tenantAccountRepo.existsByEmail(anyString())).thenReturn(false);
        when(tenantAccountRepo.existsByNumero(anyString())).thenReturn(false);
        when(tenantAccountRepo.existsByGoogleLinkedEmail(anyString())).thenReturn(false);
        when(tenantAccountRepo.findByTenantId(anyString())).thenReturn(Optional.empty());
        when(tenantAccountRepo.save(any(TenantAccount.class))).thenAnswer(inv -> inv.getArgument(0));
        when(userRepo.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));
        when(tenantConfigRepo.save(any(TenantConfig.class))).thenAnswer(inv -> inv.getArgument(0));
        when(businessRepo.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));
        when(businessSettingsRepo.save(any(BusinessSettings.class))).thenAnswer(inv -> inv.getArgument(0));
        when(categoryRepo.findBySlug(anyString())).thenReturn(Optional.empty());
        when(botWorkspaceRegistry.findBotIdByWorkspaceTenantId(anyString())).thenReturn(Optional.empty());
    }

    @Test
    void happyPath_todosSaveInvocados_responseConTresCamposNoNulos() {
        RegisterTenantRequest request = new RegisterTenantRequest(
                "Juan Perez",
                "juan@example.com",
                null,
                "+5491112345678",
                "Peluquería Juan",
                null,
                null
        );

        RegisterTenantResponse response = useCase.execute(request);

        assertNotNull(response.tenantId(), "tenantId no debe ser nulo");
        assertNotNull(response.businessId(), "businessId no debe ser nulo");
        assertNotNull(response.accessCode(), "accessCode no debe ser nulo");
        assertEquals(8, response.accessCode().length(), "accessCode debe tener exactamente 8 caracteres");

        verify(tenantAccountRepo).save(any(TenantAccount.class));
        verify(userRepo).save(any(User.class));
        verify(tenantConfigRepo).save(any(TenantConfig.class));
        verify(businessRepo).save(any(Business.class));
        verify(businessSettingsRepo).save(any(BusinessSettings.class));
    }

    @Test
    void happyPath_numeroWhatsApp_guardaTenantSinEmail() {
        RegisterTenantRequest request = new RegisterTenantRequest(
                "Ana",
                null,
                "59899123456",
                "+59899123456",
                "Salón Ana",
                null,
                null
        );

        RegisterTenantResponse response = useCase.execute(request);

        assertNotNull(response.tenantId());
        verify(tenantAccountRepo).existsByNumero("59899123456");
        verify(tenantAccountRepo).save(any(TenantAccount.class));
    }

    @Test
    void emailDuplicado_lanzaDuplicateTenantEmailException() {
        when(tenantAccountRepo.existsByEmail("duplicado@example.com")).thenReturn(true);

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Maria Lopez",
                "duplicado@example.com",
                null,
                null,
                "Negocio Duplicado",
                null,
                null
        );

        assertThrows(DuplicateTenantEmailException.class, () -> useCase.execute(request));

        verify(tenantAccountRepo, never()).save(any());
        verify(businessRepo, never()).save(any());
    }

    @Test
    void numeroDuplicado_lanzaDuplicateTenantNumeroException() {
        when(tenantAccountRepo.existsByNumero("59899123456")).thenReturn(true);

        RegisterTenantRequest request = new RegisterTenantRequest(
                "X",
                null,
                "59899123456",
                "+59899123456",
                "Negocio X",
                null,
                null
        );

        assertThrows(DuplicateTenantNumeroException.class, () -> useCase.execute(request));
        verify(tenantAccountRepo, never()).save(any());
    }

    @Test
    void sinEmailNiNumero_lanzaIllegalArgumentException() {
        RegisterTenantRequest request = new RegisterTenantRequest(
                "X",
                null,
                null,
                null,
                "Negocio X",
                null,
                null
        );

        assertThrows(IllegalArgumentException.class, () -> useCase.execute(request));
    }

    @Test
    void categoriaSlugInvalido_casodeUsoContinuaSinError() {
        when(categoryRepo.findBySlug("slug-inexistente")).thenReturn(Optional.empty());

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Pedro García",
                "pedro@example.com",
                null,
                null,
                "Negocio Pedro",
                "slug-inexistente",
                null
        );

        RegisterTenantResponse response = useCase.execute(request);

        assertNotNull(response.tenantId());
        verify(businessCategoryRepo, never()).associate(any(UUID.class), any(UUID.class));
    }

    @Test
    void categoriaSlugValido_businessCategoryAssociateEsInvocado() {
        UUID categoryId = UUID.randomUUID();
        Category category = new Category(
                categoryId, "Peluquería", "peluqueria", null, null, true, null, null
        );
        when(categoryRepo.findBySlug("peluqueria")).thenReturn(Optional.of(category));

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Ana Torres",
                "ana@example.com",
                null,
                null,
                "Peluquería Ana",
                "peluqueria",
                null
        );

        RegisterTenantResponse response = useCase.execute(request);

        assertNotNull(response.tenantId());
        verify(businessCategoryRepo).associate(response.businessId(), categoryId);
    }

    @Test
    void emailNormalizadoAMinusculas() {
        RegisterTenantRequest request = new RegisterTenantRequest(
                "Carlos Ruiz",
                "  CARLOS@EXAMPLE.COM  ",
                null,
                null,
                "Negocio Carlos",
                null,
                null
        );

        useCase.execute(request);

        verify(tenantAccountRepo).existsByEmail("carlos@example.com");
        verify(tenantAccountRepo).existsByGoogleLinkedEmail("carlos@example.com");
    }

    @Test
    void emailYaVinculadoAGoogle_lanzaDuplicateTenantEmailException() {
        when(tenantAccountRepo.existsByGoogleLinkedEmail("taken@example.com")).thenReturn(true);

        RegisterTenantRequest request = new RegisterTenantRequest(
                "X",
                "taken@example.com",
                null,
                null,
                "Negocio X",
                null,
                null
        );

        assertThrows(DuplicateTenantEmailException.class, () -> useCase.execute(request));
        verify(tenantAccountRepo, never()).save(any());
    }

    @Test
    void workspaceTenantId_reusaTenantDelBotYAsignaBotId() {
        when(tenantAccountRepo.findByTenantId("workspace-tenant-1")).thenReturn(Optional.empty());
        when(botWorkspaceRegistry.findBotIdByWorkspaceTenantId("workspace-tenant-1")).thenReturn(Optional.of(7L));

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Dueño",
                "owner@example.com",
                null,
                null,
                "Mi negocio",
                null,
                "workspace-tenant-1"
        );

        RegisterTenantResponse response = useCase.execute(request);

        assertEquals("workspace-tenant-1", response.tenantId());
        ArgumentCaptor<Business> cap = ArgumentCaptor.forClass(Business.class);
        verify(businessRepo).save(cap.capture());
        assertEquals(7L, cap.getValue().getBotId());
    }

    @Test
    void workspaceTenantId_sinBot_lanzaIllegalArgumentException() {
        when(tenantAccountRepo.findByTenantId("sin-bot")).thenReturn(Optional.empty());
        when(botWorkspaceRegistry.findBotIdByWorkspaceTenantId("sin-bot")).thenReturn(Optional.empty());

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Dueño",
                "x@example.com",
                null,
                null,
                "Negocio",
                null,
                "sin-bot"
        );

        assertThrows(IllegalArgumentException.class, () -> useCase.execute(request));
        verify(tenantAccountRepo, never()).save(any());
    }

    @Test
    void workspaceTenantId_cuentaAgendaYaExiste_lanzaIllegalStateException() {
        when(tenantAccountRepo.findByTenantId("ocupado"))
                .thenReturn(Optional.of(mock(TenantAccount.class)));
        when(botWorkspaceRegistry.findBotIdByWorkspaceTenantId("ocupado")).thenReturn(Optional.of(1L));

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Dueño",
                "y@example.com",
                null,
                null,
                "Negocio",
                null,
                "ocupado"
        );

        assertThrows(IllegalStateException.class, () -> useCase.execute(request));
    }
}
