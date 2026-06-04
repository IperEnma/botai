package com.botai.application.agenda.support;

import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.model.UserType;
import com.botai.domain.agenda.repository.UserRepository;

import java.util.Locale;
import java.util.Optional;

/**
 * Alta/reutilización de clientes Agenda: mismo teléfono canónico o mismo email → mismo {@link User}.
 */
public final class AgendaClientResolver {

    private AgendaClientResolver() {}

    public static User resolveOrCreate(UserRepository userRepository,
                                       String tenantId,
                                       String nombre,
                                       String email,
                                       String telefonoRaw) {
        String phoneNorm = AgendaPhoneNormalizer.normalize(telefonoRaw);
        if (!AgendaPhoneNormalizer.isValid(phoneNorm)) {
            throw new IllegalArgumentException("Teléfono obligatorio (mínimo 7 dígitos)");
        }
        String nombreTrim = nombre != null ? nombre.trim() : "";
        if (nombreTrim.isBlank()) {
            throw new IllegalArgumentException("Nombre del cliente obligatorio");
        }

        if (email != null && !email.isBlank()) {
            String emailNorm = email.trim().toLowerCase(Locale.ROOT);
            Optional<User> byEmail = userRepository.findByTenantIdAndEmail(tenantId, emailNorm);
            if (byEmail.isPresent()) {
                return mergePhoneAndNombre(userRepository, byEmail.get(), nombreTrim, emailNorm, phoneNorm);
            }
        }

        Optional<User> byPhone = userRepository.findClientByTenantIdAndTelefono(tenantId, phoneNorm);
        if (byPhone.isPresent()) {
            User u = byPhone.get();
            String emailNorm = email != null && !email.isBlank()
                    ? email.trim().toLowerCase(Locale.ROOT)
                    : u.getEmail();
            return mergePhoneAndNombre(userRepository, u, nombreTrim, emailNorm, phoneNorm);
        }

        return userRepository.save(new User(
                null,
                tenantId,
                nombreTrim,
                email != null && !email.isBlank() ? email.trim().toLowerCase(Locale.ROOT) : null,
                phoneNorm,
                UserType.CLIENT,
                true,
                null,
                null
        ));
    }

    private static User mergePhoneAndNombre(UserRepository userRepository,
                                            User existing,
                                            String nombre,
                                            String email,
                                            String phoneNorm) {
        String newNombre = nombre.isBlank() ? existing.getNombre() : nombre;
        String newEmail = email != null && !email.isBlank() ? email : existing.getEmail();
        String newPhone = phoneNorm;
        if (newNombre.equals(existing.getNombre())
                && java.util.Objects.equals(newEmail, existing.getEmail())
                && phoneNorm.equals(AgendaPhoneNormalizer.normalize(existing.getTelefono()))) {
            return existing;
        }
        return userRepository.save(new User(
                existing.getId(),
                existing.getTenantId(),
                newNombre,
                newEmail,
                newPhone,
                existing.getTipoUsuario(),
                existing.isActivo(),
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        ));
    }
}
