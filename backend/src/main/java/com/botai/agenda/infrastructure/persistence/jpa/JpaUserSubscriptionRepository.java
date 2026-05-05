package com.botai.agenda.infrastructure.persistence.jpa;

import com.botai.agenda.domain.model.SubscriptionEstado;
import com.botai.agenda.domain.model.UserSubscription;
import com.botai.agenda.domain.repository.UserSubscriptionRepository;
import com.botai.agenda.infrastructure.persistence.entity.UserSubscriptionEntity;
import com.botai.agenda.infrastructure.persistence.mapper.UserSubscriptionMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public class JpaUserSubscriptionRepository implements UserSubscriptionRepository {

    private final UserSubscriptionJpaRepository jpa;

    public JpaUserSubscriptionRepository(UserSubscriptionJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public UserSubscription save(UserSubscription subscription) {
        UserSubscriptionEntity entity = UserSubscriptionMapper.toEntity(subscription);
        if (entity.getId() == null) {
            entity.setId(UUID.randomUUID());
        }
        UserSubscriptionEntity saved = jpa.save(entity);
        return UserSubscriptionMapper.toDomain(saved);
    }

    @Override
    public Optional<UserSubscription> findById(UUID id) {
        return jpa.findById(id).map(UserSubscriptionMapper::toDomain);
    }

    @Override
    public Optional<UserSubscription> findByIdForUpdate(UUID id) {
        return jpa.findByIdForUpdate(id).map(UserSubscriptionMapper::toDomain);
    }

    @Override
    public List<UserSubscription> findAllByUserId(UUID userId) {
        return jpa.findAllByUserId(userId).stream()
                .map(UserSubscriptionMapper::toDomain)
                .toList();
    }

    @Override
    public List<UserSubscription> findAllByUserIdAndEstado(UUID userId, SubscriptionEstado estado) {
        return jpa.findAllByUserIdAndEstado(userId, estado).stream()
                .map(UserSubscriptionMapper::toDomain)
                .toList();
    }

    @Override
    public List<UserSubscription> findAllByBusinessIdAndEstado(UUID businessId, SubscriptionEstado estado) {
        return jpa.findAllByBusinessIdAndEstado(businessId, estado).stream()
                .map(UserSubscriptionMapper::toDomain)
                .toList();
    }

    @Override
    public List<UserSubscription> findAllActiveExpiringSoon(LocalDateTime desde, LocalDateTime hasta) {
        return jpa.findAllActiveExpiringSoon(desde, hasta).stream()
                .map(UserSubscriptionMapper::toDomain)
                .toList();
    }

    @Override
    public List<UserSubscription> findAllActiveWithLowBalance(int maxSaldo) {
        return jpa.findAllActiveWithLowBalance(maxSaldo).stream()
                .map(UserSubscriptionMapper::toDomain)
                .toList();
    }
}
