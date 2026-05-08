package com.botai.application.agenda.usecase.subscription;

import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Lista las suscripciones del usuario autenticado.
 *
 * <p>Sin filtros, devuelve todas. Con {@code onlyActive=true}, solo las que
 * tienen {@code estado=ACTIVE}. No se filtra por vigencia acá — la "caducidad
 * efectiva" se calcula en Sprint 3 al momento de reservar.</p>
 */
@Service
public class ListMySubscriptionsUseCase {

    private final UserSubscriptionRepository subscriptionRepository;

    public ListMySubscriptionsUseCase(UserSubscriptionRepository subscriptionRepository) {
        this.subscriptionRepository = subscriptionRepository;
    }

    @Transactional(readOnly = true)
    public List<UserSubscription> execute(UUID userId, boolean onlyActive) {
        return onlyActive
                ? subscriptionRepository.findAllByUserIdAndEstado(userId, SubscriptionEstado.ACTIVE)
                : subscriptionRepository.findAllByUserId(userId);
    }
}
