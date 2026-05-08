package com.botai.application.agenda.usecase.tenant;

import com.botai.application.agenda.dto.TenantAdminContextResponse;
import com.botai.domain.agenda.exception.DuplicateTenantEmailException;
import com.botai.domain.agenda.exception.DuplicateTenantNumeroException;
import com.botai.domain.agenda.model.TenantAccount;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

/**
 * Agrega un identificador adicional (email o numero) a una cuenta existente.
 *
 * <p>Reglas:
 * <ul>
 *   <li>Debe indicar exactamente uno: email o numero.</li>
 *   <li>Si el campo ya está seteado con el mismo valor → idempotente (OK).</li>
 *   <li>Si está seteado con otro valor → 409.</li>
 *   <li>Si el valor ya existe en otra cuenta → 409 (DuplicateTenant*).</li>
 * </ul>
 * </p>
 */
@Service
public class LinkTenantIdentifierUseCase {

    private final TenantAccountRepository tenantAccountRepository;

    public LinkTenantIdentifierUseCase(TenantAccountRepository tenantAccountRepository) {
        this.tenantAccountRepository = tenantAccountRepository;
    }

    @Transactional
    public TenantAdminContextResponse execute(String adminEmail, String emailToLink, String numeroToLink) {
        if (adminEmail == null || adminEmail.isBlank()) {
            throw new IllegalArgumentException("Falta email de sesión.");
        }
        String normalizedAdminEmail = adminEmail.strip().toLowerCase(Locale.ROOT);

        boolean hasEmail = emailToLink != null && !emailToLink.isBlank();
        boolean hasNumero = numeroToLink != null && !numeroToLink.isBlank();
        if (hasEmail == hasNumero) {
            throw new IllegalArgumentException("Debe indicar exactamente uno: email o numero.");
        }

        TenantAccount account = tenantAccountRepository.findByEmail(normalizedAdminEmail)
                .or(() -> tenantAccountRepository.findByGoogleLinkedEmail(normalizedAdminEmail))
                .orElseThrow(() -> new IllegalStateException("No se encontró cuenta Agenda para este usuario."));

        if (hasEmail) {
            String normalizedEmail = emailToLink.strip().toLowerCase(Locale.ROOT);
            if (account.getEmail() != null) {
                if (account.getEmail().equalsIgnoreCase(normalizedEmail)) {
                    return new TenantAdminContextResponse(account.getTenantId());
                }
                throw new IllegalStateException("Este negocio ya tiene un email configurado.");
            }
            if (tenantAccountRepository.existsByEmail(normalizedEmail)
                    || tenantAccountRepository.existsByGoogleLinkedEmail(normalizedEmail)) {
                throw new DuplicateTenantEmailException(normalizedEmail);
            }
            TenantAccount updated = new TenantAccount(
                    account.getTenantId(),
                    account.getNombrePropietario(),
                    normalizedEmail,
                    account.getGoogleLinkedEmail(),
                    account.getNumero(),
                    account.getTelefono(),
                    account.getAccessCode(),
                    account.isActivo(),
                    account.getCreatedAt(),
                    account.getUpdatedAt()
            );
            tenantAccountRepository.save(updated);
            return new TenantAdminContextResponse(updated.getTenantId());
        }

        String digits = numeroToLink.replaceAll("\\D", "");
        if (digits.length() < 8) {
            throw new IllegalArgumentException("numero debe tener al menos 8 dígitos.");
        }
        if (account.getNumero() != null) {
            if (account.getNumero().equals(digits)) {
                return new TenantAdminContextResponse(account.getTenantId());
            }
            throw new IllegalStateException("Este negocio ya tiene un número configurado.");
        }
        if (tenantAccountRepository.existsByNumero(digits)) {
            throw new DuplicateTenantNumeroException(digits);
        }

        TenantAccount updated = new TenantAccount(
                account.getTenantId(),
                account.getNombrePropietario(),
                account.getEmail(),
                account.getGoogleLinkedEmail(),
                digits,
                account.getTelefono(),
                account.getAccessCode(),
                account.isActivo(),
                account.getCreatedAt(),
                account.getUpdatedAt()
        );
        tenantAccountRepository.save(updated);
        return new TenantAdminContextResponse(updated.getTenantId());
    }
}

