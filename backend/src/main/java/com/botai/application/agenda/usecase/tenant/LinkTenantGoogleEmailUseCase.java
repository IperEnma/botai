package com.botai.application.agenda.usecase.tenant;

import com.botai.application.agenda.dto.TenantAdminContextResponse;
import com.botai.domain.agenda.exception.TenantAccessCodeNotFoundException;
import com.botai.domain.agenda.exception.TenantGoogleLinkConflictException;
import com.botai.domain.agenda.model.TenantAccount;
import com.botai.domain.agenda.repository.TenantAccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Optional;

/**
 * Vincula el correo de Google (sesión) a una cuenta creada con {@code numero} (WhatsApp) o {@code email}.
 * Persiste en {@code google_linked_email}; no modifica {@code numero} ni el correo principal de registro.
 */
@Service
public class LinkTenantGoogleEmailUseCase {

    private final TenantAccountRepository tenantAccountRepository;

    public LinkTenantGoogleEmailUseCase(TenantAccountRepository tenantAccountRepository) {
        this.tenantAccountRepository = tenantAccountRepository;
    }

    @Transactional
    public TenantAdminContextResponse execute(String googleEmail, String rawAccessCode) {
        String normalizedEmail = googleEmail.strip().toLowerCase(Locale.ROOT);

        Optional<TenantAccount> alreadyLinked = tenantAccountRepository.findByGoogleLinkedEmail(normalizedEmail);
        if (alreadyLinked.isPresent()) {
            return new TenantAdminContextResponse(alreadyLinked.get().getTenantId());
        }

        if (tenantAccountRepository.findByEmail(normalizedEmail).isPresent()) {
            throw new TenantGoogleLinkConflictException(
                    "Este correo ya está registrado como email principal de un negocio.");
        }

        String code = normalizeAccessCode(rawAccessCode);
        if (code.length() != 8) {
            throw new IllegalArgumentException("El código debe tener 8 caracteres (letras y números).");
        }

        TenantAccount account = tenantAccountRepository.findByAccessCode(code)
                .orElseThrow(TenantAccessCodeNotFoundException::new);

        if (!account.isActivo()) {
            throw new IllegalStateException("Esta cuenta está inactiva.");
        }

        if (account.getGoogleLinkedEmail() != null
                && !account.getGoogleLinkedEmail().equalsIgnoreCase(normalizedEmail)) {
            throw new TenantGoogleLinkConflictException(
                    "Este negocio ya está vinculado a otro correo de Google.");
        }

        if (account.getGoogleLinkedEmail() != null) {
            return new TenantAdminContextResponse(account.getTenantId());
        }

        if (tenantAccountRepository.existsByGoogleLinkedEmail(normalizedEmail)) {
            throw new TenantGoogleLinkConflictException("Este correo de Google ya está en uso.");
        }

        TenantAccount updated = new TenantAccount(
                account.getTenantId(),
                account.getNombrePropietario(),
                account.getEmail(),
                normalizedEmail,
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

    private static String normalizeAccessCode(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.trim().toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9]", "");
    }
}
