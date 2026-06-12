package com.botai.infrastructure.agenda.persistence.jpa;

import com.botai.application.agenda.support.AgendaPhoneNormalizer;
import com.botai.domain.agenda.model.ClientWithStats;
import com.botai.domain.agenda.model.User;
import com.botai.domain.agenda.repository.UserRepository;
import com.botai.infrastructure.agenda.persistence.entity.UserEntity;
import com.botai.infrastructure.agenda.persistence.mapper.UserMapper;
import com.botai.infrastructure.agenda.persistence.projection.ClientStatsRow;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaUserRepository implements UserRepository {

    private final UserJpaRepository jpa;

    public JpaUserRepository(UserJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public User save(User user) {
        UserEntity entity = UserMapper.toEntity(user);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        UserEntity saved = jpa.save(entity);
        return UserMapper.toDomain(saved);
    }

    @Override
    public Optional<User> findById(UUID id) {
        return jpa.findById(id).map(UserMapper::toDomain);
    }

    @Override
    public Optional<User> findByTenantIdAndEmail(String tenantId, String email) {
        return jpa.findByTenantIdAndEmail(tenantId, email).map(UserMapper::toDomain);
    }

    @Override
    public Optional<User> findByEmail(String email) {
        if (email == null || email.isBlank()) return Optional.empty();
        return jpa.findFirstByEmailOrderByCreatedAtAsc(email).map(UserMapper::toDomain);
    }

    @Override
    public Optional<User> findClientByTenantIdAndTelefono(String tenantId, String telefonoNormalized) {
        if (tenantId == null || tenantId.isBlank() || telefonoNormalized == null || telefonoNormalized.isBlank()) {
            return Optional.empty();
        }
        return jpa.findActiveClientsWithTelefono(tenantId).stream()
                .map(UserMapper::toDomain)
                .filter(u -> AgendaPhoneNormalizer.phonesMatch(u.getTelefono(), telefonoNormalized))
                .findFirst();
    }

    @Override
    public List<User> searchClients(String tenantId, String q) {
        return jpa.searchClients(tenantId, q).stream().map(UserMapper::toDomain).toList();
    }

    @Override
    public List<ClientWithStats> searchClientsWithStats(String tenantId, String q) {
        return jpa.searchClientsWithStats(tenantId, q).stream()
                .map(JpaUserRepository::toDomain)
                .toList();
    }

    private static ClientWithStats toDomain(ClientStatsRow row) {
        return new ClientWithStats(
                row.id(),
                row.nombre(),
                row.email(),
                row.telefono(),
                row.clienteDesde(),
                row.visitas() != null ? row.visitas() : 0L,
                row.inasistencias() != null ? row.inasistencias() : 0L,
                row.ultimaVisita(),
                row.gastoAcumulado() != null ? row.gastoAcumulado() : BigDecimal.ZERO
        );
    }
}
