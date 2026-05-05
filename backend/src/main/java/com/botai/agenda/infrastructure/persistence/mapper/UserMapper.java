package com.botai.agenda.infrastructure.persistence.mapper;

import com.botai.agenda.domain.model.User;
import com.botai.agenda.domain.model.UserType;
import com.botai.agenda.infrastructure.persistence.entity.UserEntity;

public final class UserMapper {

    private UserMapper() {
    }

    public static User toDomain(UserEntity entity) {
        if (entity == null) {
            return null;
        }
        return new User(
                entity.getId(),
                entity.getTenantId(),
                entity.getNombre(),
                entity.getEmail(),
                entity.getTelefono(),
                toDomainType(entity.getTipoUsuario()),
                entity.isActivo(),
                entity.getCreatedAt(),
                entity.getUpdatedAt()
        );
    }

    public static UserEntity toEntity(User user) {
        if (user == null) {
            return null;
        }
        UserEntity entity = new UserEntity();
        entity.setId(user.getId());
        entity.setTenantId(user.getTenantId());
        entity.setNombre(user.getNombre());
        entity.setEmail(user.getEmail());
        entity.setTelefono(user.getTelefono());
        entity.setTipoUsuario(toEntityType(user.getTipoUsuario()));
        entity.setActivo(user.isActivo());
        entity.setCreatedAt(user.getCreatedAt());
        entity.setUpdatedAt(user.getUpdatedAt());
        return entity;
    }

    private static UserType toDomainType(UserEntity.UserType type) {
        if (type == null) {
            return null;
        }
        return switch (type) {
            case ADMIN -> UserType.ADMIN;
            case CLIENT -> UserType.CLIENT;
        };
    }

    private static UserEntity.UserType toEntityType(UserType type) {
        if (type == null) {
            return null;
        }
        return switch (type) {
            case ADMIN -> UserEntity.UserType.ADMIN;
            case CLIENT -> UserEntity.UserType.CLIENT;
        };
    }
}
