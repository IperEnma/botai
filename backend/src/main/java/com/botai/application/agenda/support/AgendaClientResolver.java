package com.botai.application.agenda.support;

import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.model.UserType;
import com.botai.domain.agenda.repository.UserRepository;

import java.util.Locale;
import java.util.Objects;
import java.util.Optional;
import java.util.UUID;

/**
 * Alta/reutilización de clientes Agenda: mismo teléfono canónico o mismo email → mismo {@link User}.
 */
public final class AgendaClientResolver {

    /** Placeholder hasta que el cliente indique su nombre al reservar. */
    public static final String PENDING_NAME = "Cliente";

    private AgendaClientResolver() {}

    public record ClientEnsureResult(User user, boolean needsName) {}

    /**
     * Devuelve el cliente existente por teléfono o crea uno mínimo (nombre pendiente).
     */
    public static ClientEnsureResult ensureClientByPhone(UserRepository userRepository,
                                                         String tenantId,
                                                         String telefonoRaw) {
        String phoneNorm = AgendaPhoneNormalizer.normalize(telefonoRaw);
        if (!AgendaPhoneNormalizer.isValid(phoneNorm)) {
            throw new IllegalArgumentException("Teléfono obligatorio (mínimo 7 dígitos)");
        }
        Optional<User> byPhone = userRepository.findClientByTenantIdAndTelefono(tenantId, phoneNorm);
        if (byPhone.isPresent()) {
            User u = byPhone.get();
            boolean needsName = PENDING_NAME.equals(u.getNombre());
            return new ClientEnsureResult(u, needsName);
        }
        User created = userRepository.save(new User(
                null,
                tenantId,
                PENDING_NAME,
                null,
                phoneNorm,
                UserType.CLIENT,
                true,
                null,
                null
        ));
        return new ClientEnsureResult(created, true);
    }

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

        // Teléfono verificado (OTP) tiene prioridad: no reasignar un número ya usado por otro cliente.
        Optional<User> byPhone = userRepository.findClientByTenantIdAndTelefono(tenantId, phoneNorm);
        if (byPhone.isPresent()) {
            return mergeNombreAndEmail(userRepository, byPhone.get(), nombreTrim, email);
        }

        if (email != null && !email.isBlank()) {
            String emailNorm = email.trim().toLowerCase(Locale.ROOT);
            Optional<User> byEmail = userRepository.findByTenantIdAndEmail(tenantId, emailNorm);
            if (byEmail.isPresent()) {
                return mergePhoneAndNombre(userRepository, byEmail.get(), nombreTrim, emailNorm, phoneNorm);
            }
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

    private static User mergeNombreAndEmail(UserRepository userRepository,
                                            User existing,
                                            String nombre,
                                            String emailRaw) {
        String newNombre = nombre.isBlank() ? existing.getNombre() : nombre;
        String newEmail = emailRaw != null && !emailRaw.isBlank()
                ? emailRaw.trim().toLowerCase(Locale.ROOT)
                : existing.getEmail();
        if (newNombre.equals(existing.getNombre()) && Objects.equals(newEmail, existing.getEmail())) {
            return existing;
        }
        if (newEmail != null && !newEmail.isBlank() && !Objects.equals(newEmail, existing.getEmail())) {
            releaseEmailFromOtherClient(userRepository, existing.getTenantId(), existing.getId(), newEmail);
        }
        return userRepository.save(copyUser(existing, newNombre, newEmail, existing.getTelefono()));
    }

    private static User mergePhoneAndNombre(UserRepository userRepository,
                                            User existing,
                                            String nombre,
                                            String email,
                                            String phoneNorm) {
        String newNombre = nombre.isBlank() ? existing.getNombre() : nombre;
        String newEmail = email != null && !email.isBlank() ? email : existing.getEmail();
        if (newNombre.equals(existing.getNombre())
                && Objects.equals(newEmail, existing.getEmail())
                && phoneNorm.equals(AgendaPhoneNormalizer.normalize(existing.getTelefono()))) {
            return existing;
        }
        return userRepository.save(copyUser(existing, newNombre, newEmail, phoneNorm));
    }

    /** Evita violar uk_agenda_users_tenant_email al unificar identidad en el cliente del teléfono. */
    private static void releaseEmailFromOtherClient(UserRepository userRepository,
                                                    String tenantId,
                                                    UUID keepUserId,
                                                    String email) {
        userRepository.findByTenantIdAndEmail(tenantId, email)
                .filter(u -> !keepUserId.equals(u.getId()))
                .filter(u -> u.getTipoUsuario() == UserType.CLIENT)
                .ifPresent(other -> userRepository.save(
                        copyUser(other, other.getNombre(), null, other.getTelefono())));
    }

    private static User copyUser(User existing, String nombre, String email, String telefono) {
        return new User(
                existing.getId(),
                existing.getTenantId(),
                nombre,
                email,
                telefono,
                existing.getTipoUsuario(),
                existing.isActivo(),
                existing.getCreatedAt(),
                existing.getUpdatedAt()
        );
    }
}
