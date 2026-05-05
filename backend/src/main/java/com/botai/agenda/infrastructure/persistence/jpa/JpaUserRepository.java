package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.User;
import com.botai.agenda.domain.repository.UserRepository;
import com.botai.agenda.infrastructure.persistence.entity.UserEntity;
import com.botai.agenda.infrastructure.persistence.mapper.UserMapper;
import org.springframework.stereotype.Repository;

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
}
