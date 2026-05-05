package com.botai.agenda.application.usecase.tenant;

import com.botai.agenda.application.dto.RegisterTenantRequest;
import com.botai.agenda.application.dto.RegisterTenantResponse;
import com.botai.agenda.domain.exception.DuplicateTenantEmailException;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.model.Category;
import com.botai.agenda.domain.model.TenantAccount;
import com.botai.agenda.domain.model.TenantConfig;
import com.botai.agenda.domain.model.User;
import com.botai.agenda.domain.repository.BusinessCategoryRepository;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
import com.botai.agenda.domain.repository.CategoryRepository;
import com.botai.agenda.domain.repository.TenantAccountRepository;
import com.botai.agenda.domain.repository.TenantConfigRepository;
import com.botai.agenda.domain.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

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

        useCase = new RegisterTenantUseCase(
                tenantAccountRepo,
                userRepo,
                tenantConfigRepo,
                businessRepo,
                businessSettingsRepo,
                categoryRepo,
                businessCategoryRepo
        );

        // Defaults: email no existe
        when(tenantAccountRepo.existsByEmail(anyString())).thenReturn(false);
        when(tenantAccountRepo.save(any(TenantAccount.class))).thenAnswer(inv -> inv.getArgument(0));
        when(userRepo.save(any(User.class))).thenAnswer(inv -> inv.getArgument(0));
        when(tenantConfigRepo.save(any(TenantConfig.class))).thenAnswer(inv -> inv.getArgument(0));
        when(businessRepo.save(any(Business.class))).thenAnswer(inv -> inv.getArgument(0));
        when(businessSettingsRepo.save(any(BusinessSettings.class))).thenAnswer(inv -> inv.getArgument(0));
        when(categoryRepo.findBySlug(anyString())).thenReturn(Optional.empty());
    }

    @Test
    void happyPath_todosSaveInvocados_responseConTresCamposNoNulos() {
        RegisterTenantRequest request = new RegisterTenantRequest(
                "Juan Perez",
                "juan@example.com",
                "+5491112345678",
                "Peluquería Juan",
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
    void emailDuplicado_lanzaDuplicateTenantEmailException() {
        when(tenantAccountRepo.existsByEmail("duplicado@example.com")).thenReturn(true);

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Maria Lopez",
                "duplicado@example.com",
                null,
                "Negocio Duplicado",
                null
        );

        assertThrows(DuplicateTenantEmailException.class, () -> useCase.execute(request));

        // No deben invocarse los saves si el email ya existe
        verify(tenantAccountRepo, never()).save(any());
        verify(businessRepo, never()).save(any());
    }

    @Test
    void categoriaSlugInvalido_casodeUsoContinuaSinError() {
        when(categoryRepo.findBySlug("slug-inexistente")).thenReturn(Optional.empty());

        RegisterTenantRequest request = new RegisterTenantRequest(
                "Pedro García",
                "pedro@example.com",
                null,
                "Negocio Pedro",
                "slug-inexistente"
        );

        RegisterTenantResponse response = useCase.execute(request);

        assertNotNull(response.tenantId());
        // La categoría no existía, no se debe llamar associate
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
                "Peluquería Ana",
                "peluqueria"
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
                "Negocio Carlos",
                null
        );

        useCase.execute(request);

        // La verificacion de existencia debe haberse hecho con el email normalizado
        verify(tenantAccountRepo).existsByEmail("carlos@example.com");
    }
}
