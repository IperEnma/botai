package com.botai.agenda.application.usecase.tenant;

import com.botai.agenda.application.dto.RegisterTenantRequest;
import com.botai.agenda.application.dto.RegisterTenantResponse;
import com.botai.agenda.domain.exception.DuplicateTenantEmailException;
import com.botai.agenda.domain.model.Business;
import com.botai.agenda.domain.model.BusinessSettings;
import com.botai.agenda.domain.model.TenantAccount;
import com.botai.agenda.domain.model.TenantConfig;
import com.botai.agenda.domain.model.User;
import com.botai.agenda.domain.model.UserType;
import com.botai.agenda.domain.repository.BusinessCategoryRepository;
import com.botai.agenda.domain.repository.BusinessRepository;
import com.botai.agenda.domain.repository.BusinessSettingsRepository;
import com.botai.agenda.domain.repository.CategoryRepository;
import com.botai.agenda.domain.repository.TenantAccountRepository;
import com.botai.agenda.domain.repository.TenantConfigRepository;
import com.botai.agenda.domain.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;
import java.util.UUID;

/**
 * Registro público de un nuevo tenant en el módulo AGENDA.
 *
 * <p>En una única transacción crea: cuenta de tenant, usuario admin,
 * configuración de tenant con AGENDA habilitada, negocio y sus settings.
 * Opcionalmente asocia el negocio a una categoría por slug.</p>
 */
@Service
public class RegisterTenantUseCase {

    private static final Logger log = LoggerFactory.getLogger(RegisterTenantUseCase.class);

    private static final String ACCESS_CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    private static final int ACCESS_CODE_LENGTH = 8;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final TenantAccountRepository tenantAccountRepository;
    private final UserRepository userRepository;
    private final TenantConfigRepository tenantConfigRepository;
    private final BusinessRepository businessRepository;
    private final BusinessSettingsRepository businessSettingsRepository;
    private final CategoryRepository categoryRepository;
    private final BusinessCategoryRepository businessCategoryRepository;

    public RegisterTenantUseCase(TenantAccountRepository tenantAccountRepository,
                                 UserRepository userRepository,
                                 TenantConfigRepository tenantConfigRepository,
                                 BusinessRepository businessRepository,
                                 BusinessSettingsRepository businessSettingsRepository,
                                 CategoryRepository categoryRepository,
                                 BusinessCategoryRepository businessCategoryRepository) {
        this.tenantAccountRepository = tenantAccountRepository;
        this.userRepository = userRepository;
        this.tenantConfigRepository = tenantConfigRepository;
        this.businessRepository = businessRepository;
        this.businessSettingsRepository = businessSettingsRepository;
        this.categoryRepository = categoryRepository;
        this.businessCategoryRepository = businessCategoryRepository;
    }

    @Transactional
    public RegisterTenantResponse execute(RegisterTenantRequest request) {
        // 1. Normalizar email
        String email = request.email().trim().toLowerCase();

        // 2. Validar unicidad de email
        if (tenantAccountRepository.existsByEmail(email)) {
            throw new DuplicateTenantEmailException(email);
        }

        // 3. Generar tenantId
        String tenantId = UUID.randomUUID().toString();

        // 4. Generar accessCode único
        String accessCode = generateAccessCode();

        // 5. Crear y guardar TenantAccount
        TenantAccount account = new TenantAccount(
                tenantId,
                request.nombrePropietario().trim(),
                email,
                request.telefono() != null ? request.telefono().trim() : null,
                accessCode,
                true,
                null,
                null
        );
        tenantAccountRepository.save(account);

        // 6. Crear usuario admin para el tenant
        UUID userId = UUID.randomUUID();
        User adminUser = new User(
                userId,
                tenantId,
                request.nombrePropietario().trim(),
                email,
                request.telefono() != null ? request.telefono().trim() : null,
                UserType.ADMIN,
                true,
                null,
                null
        );
        userRepository.save(adminUser);

        // 7. Crear TenantConfig con AGENDA_ENABLED=true
        TenantConfig config = new TenantConfig(tenantId, true, true, true, true);
        tenantConfigRepository.save(config);

        // 8. Crear Business
        UUID businessId = UUID.randomUUID();
        Business business = new Business(
                businessId,
                tenantId,
                request.nombreNegocio().trim(),
                null,
                userId,
                List.of(),
                true,
                null,  // logoUrl
                null,  // colorPrimario
                null,  // instagramUrl
                null,  // tiktokUrl
                null,  // facebookUrl
                null,  // colorFondo
                null,  // fontFamily
                null,
                null,
                null
        );
        businessRepository.save(business);

        // 9. Crear BusinessSettings con defaults
        businessSettingsRepository.save(BusinessSettings.defaults(businessId));

        // 10. Asociar categoría si se proporcionó slug válido
        if (request.categoriaSlug() != null && !request.categoriaSlug().isBlank()) {
            categoryRepository.findBySlug(request.categoriaSlug().trim())
                    .ifPresent(category -> {
                        try {
                            businessCategoryRepository.associate(businessId, category.getId());
                        } catch (Exception e) {
                            // Silenciar errores de asociación de categoría
                            log.warn("AGENDA: no se pudo asociar categoría slug={} al negocio id={}: {}",
                                    request.categoriaSlug(), businessId, e.getMessage());
                        }
                    });
        }

        log.info("AGENDA: tenant registrado tenantId={} email={} businessId={}", tenantId, email, businessId);

        // 11. Retornar respuesta
        return new RegisterTenantResponse(tenantId, businessId, accessCode);
    }

    private String generateAccessCode() {
        StringBuilder sb = new StringBuilder(ACCESS_CODE_LENGTH);
        for (int i = 0; i < ACCESS_CODE_LENGTH; i++) {
            sb.append(ACCESS_CODE_CHARS.charAt(SECURE_RANDOM.nextInt(ACCESS_CODE_CHARS.length())));
        }
        return sb.toString();
    }
}
