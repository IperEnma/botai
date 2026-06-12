package com.botai.application.agenda.usecase.tenant;

import com.botai.application.agenda.dto.RegisterTenantRequest;
import com.botai.application.agenda.dto.RegisterTenantResponse;
import com.botai.application.agenda.support.AgendaPublicSlug;
import com.botai.application.agenda.support.CompanySlugSupport;
import com.botai.application.agenda.usecase.rbac.AgendaRoleBootstrapService;
import com.botai.domain.agenda.exception.DuplicateTenantEmailException;
import com.botai.domain.agenda.exception.DuplicateTenantNumeroException;
import com.botai.domain.agenda.model.Business;
import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.TenantAccount;
import com.botai.domain.agenda.model.TenantConfig;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.model.UserType;
import com.botai.domain.agenda.repository.BotWorkspaceRegistry;
import com.botai.domain.agenda.repository.BusinessCategoryRepository;
import com.botai.domain.agenda.repository.BusinessRepository;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.domain.agenda.repository.CategoryRepository;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import com.botai.domain.agenda.repository.TenantConfigRepository;
import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.domain.agenda.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

/**
 * Registro público de un nuevo tenant en el módulo AGENDA.
 *
 * <p>Compatibilidad de canales: exactamente uno de {@code email} (correo) o {@code numero} (WhatsApp, dígitos).
 * El admin {@link User} lleva email solo en el camino por correo; en el camino WhatsApp el email del usuario queda null.</p>
 *
 * <p>En una única transacción crea: cuenta de tenant, usuario admin,
 * configuración de tenant con AGENDA habilitada, negocio y sus settings.
 * Opcionalmente asocia el negocio a una categoría por slug.</p>
 *
 * <p>Un solo {@code tenant_id} por workspace: si el cliente envía {@code workspaceTenantId} (el {@code tenant_id}
 * del bot ya creado), se reutiliza en Agenda y se vincula {@code agenda_businesses.bot_id}.</p>
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
    private final BotWorkspaceRegistry botWorkspaceRegistry;
    private final AgendaRoleBootstrapService roleBootstrap;

    public RegisterTenantUseCase(TenantAccountRepository tenantAccountRepository,
                                 UserRepository userRepository,
                                 TenantConfigRepository tenantConfigRepository,
                                 BusinessRepository businessRepository,
                                 BusinessSettingsRepository businessSettingsRepository,
                                 CategoryRepository categoryRepository,
                                 BusinessCategoryRepository businessCategoryRepository,
                                 BotWorkspaceRegistry botWorkspaceRegistry,
                                 AgendaRoleBootstrapService roleBootstrap) {
        this.tenantAccountRepository = tenantAccountRepository;
        this.userRepository = userRepository;
        this.tenantConfigRepository = tenantConfigRepository;
        this.businessRepository = businessRepository;
        this.businessSettingsRepository = businessSettingsRepository;
        this.categoryRepository = categoryRepository;
        this.businessCategoryRepository = businessCategoryRepository;
        this.botWorkspaceRegistry = botWorkspaceRegistry;
        this.roleBootstrap = roleBootstrap;
    }

    @Transactional
    public RegisterTenantResponse execute(RegisterTenantRequest request) {
        String rawEmail = request.email() != null ? request.email().trim() : "";
        String normNumero = request.numero() != null ? request.numero().replaceAll("\\D", "") : "";

        boolean hasEmail = !rawEmail.isEmpty();
        boolean hasNumero = !normNumero.isEmpty();
        if (hasEmail == hasNumero) {
            throw new IllegalArgumentException("Debe indicar exactamente uno: email o numero.");
        }

        String tenantEmail = null;
        String tenantNumero = null;
        String adminUserEmail = null;

        if (hasNumero) {
            if (normNumero.length() < 8) {
                throw new IllegalArgumentException("numero debe tener al menos 8 dígitos.");
            }
            if (tenantAccountRepository.existsByNumero(normNumero)) {
                throw new DuplicateTenantNumeroException(normNumero);
            }
            tenantNumero = normNumero;
        } else {
            String email = rawEmail.toLowerCase(Locale.ROOT);
            if (!email.contains("@")) {
                throw new IllegalArgumentException("email inválido.");
            }
            if (tenantAccountRepository.existsByEmail(email)) {
                throw new DuplicateTenantEmailException(email);
            }
            if (tenantAccountRepository.existsByGoogleLinkedEmail(email)) {
                throw new DuplicateTenantEmailException(email);
            }
            tenantEmail = email;
            adminUserEmail = email;
        }

        String tenantId;
        Long linkedBotId;
        if (request.workspaceTenantId() != null) {
            tenantId = request.workspaceTenantId();
            if (tenantId.length() > 64) {
                throw new IllegalArgumentException("workspaceTenantId demasiado largo.");
            }
            if (tenantAccountRepository.findByTenantId(tenantId).isPresent()) {
                throw new IllegalStateException("Ya existe cuenta Agenda para este workspace (tenant_id).");
            }
            linkedBotId = botWorkspaceRegistry.findBotIdByWorkspaceTenantId(tenantId)
                    .orElseThrow(() -> new IllegalArgumentException(
                            "No existe bot con ese tenant_id. Cree el bot con tenantId=workspaceTenantId o omita workspaceTenantId."));
        } else {
            tenantId = UUID.randomUUID().toString();
            linkedBotId = botWorkspaceRegistry.findBotIdByWorkspaceTenantId(tenantId).orElse(null);
        }

        String accessCode = generateAccessCode();

        TenantAccount account = new TenantAccount(
                tenantId,
                request.nombrePropietario().trim(),
                tenantEmail,
                null,
                tenantNumero,
                AgendaPhoneNormalizer.normalizeOrNull(request.telefono()),
                accessCode,
                true,
                null,
                null
        );
        tenantAccountRepository.save(account);

        UUID userId = UUID.randomUUID();
        User adminUser = new User(
                userId,
                tenantId,
                request.nombrePropietario().trim(),
                adminUserEmail,
                AgendaPhoneNormalizer.normalizeOrNull(request.telefono()),
                UserType.ADMIN,
                true,
                null,
                null
        );
        userRepository.save(adminUser);

        roleBootstrap.grantOwnerOnRegistration(userId, tenantId);

        TenantConfig config = new TenantConfig(tenantId, true, true, true, true);
        tenantConfigRepository.save(config);

        UUID businessId = UUID.randomUUID();
        String nombreNegocio = request.nombreNegocio().trim();
        String publicSlug = AgendaPublicSlug.forNewBusiness(businessId, nombreNegocio);
        String companySlug = AgendaPublicSlug.compactSlug(nombreNegocio);
        Business business = new Business(
                businessId,
                tenantId,
                nombreNegocio,
                null,
                userId,
                List.of(),
                true,
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                publicSlug,
                companySlug,
                linkedBotId,
                null,
                null,
                null
        );
        businessRepository.save(business);

        businessSettingsRepository.save(BusinessSettings.defaults(businessId));

        if (request.categoriaSlug() != null && !request.categoriaSlug().isBlank()) {
            categoryRepository.findBySlug(request.categoriaSlug().trim())
                    .ifPresent(category -> {
                        try {
                            businessCategoryRepository.associate(businessId, category.getId());
                        } catch (Exception e) {
                            log.warn("AGENDA: no se pudo asociar categoría slug={} al negocio id={}: {}",
                                    request.categoriaSlug(), businessId, e.getMessage());
                        }
                    });
        }

        String loginKey = tenantEmail != null ? tenantEmail : "numero:" + tenantNumero;
        log.info("AGENDA: tenant registrado tenantId={} loginKey={} businessId={}", tenantId, loginKey, businessId);

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
