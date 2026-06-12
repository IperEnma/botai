package com.botai.domain.agenda.repository;

import com.botai.domain.agenda.model.ClientWithStats;
import com.botai.domain.agenda.model.User;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository {

    User save(User user);

    Optional<User> findById(UUID id);

    Optional<User> findByTenantIdAndEmail(String tenantId, String email);

    /**
     * Resuelve un usuario por email global (sin tenant).
     *
     * <p>Usado por {@code AgendaPrincipalLoader} para autenticar miembros
     * invitados — el JWT no matchea {@code TenantAccount} pero sí existe un
     * {@code User} cuyo email coincide y vive dentro de un tenant.</p>
     */
    Optional<User> findByEmail(String email);

    /** Cliente activo cuyo teléfono coincide tras normalización canónica. */
    Optional<User> findClientByTenantIdAndTelefono(String tenantId, String telefonoNormalized);

    List<User> searchClients(String tenantId, String q);

    /**
     * Igual filtro que {@link #searchClients} pero proyectando estadísticas agregadas
     * desde {@code agenda_bookings} (+ {@code agenda_services} para gasto).
     */
    List<ClientWithStats> searchClientsWithStats(String tenantId, String q);
}
