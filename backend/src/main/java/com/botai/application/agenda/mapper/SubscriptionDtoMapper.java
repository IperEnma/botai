package com.botai.application.agenda.mapper;

import com.botai.application.agenda.dto.CreditTransactionResponse;
import com.botai.application.agenda.dto.SubscriptionResponse;
import com.botai.application.agenda.dto.WalletResponse;
import com.botai.application.agenda.usecase.subscription.GetMyWalletUseCase;
import com.botai.domain.agenda.model.CreditTransaction;
import com.botai.domain.agenda.model.UserSubscription;

public final class SubscriptionDtoMapper {

    private SubscriptionDtoMapper() {
    }

    public static SubscriptionResponse toResponse(UserSubscription sub) {
        if (sub == null) return null;
        return new SubscriptionResponse(
                sub.getId(),
                sub.getUserId(),
                sub.getPlanId(),
                sub.getBusinessId(),
                sub.getSaldoActual(),
                sub.getFechaInicio(),
                sub.getFechaExpiracion(),
                sub.getEstado(),
                sub.getCreatedAt(),
                sub.getUpdatedAt()
        );
    }

    public static CreditTransactionResponse toResponse(CreditTransaction tx) {
        if (tx == null) return null;
        return new CreditTransactionResponse(
                tx.getId(),
                tx.getSubscriptionId(),
                tx.getMonto(),
                tx.getMotivo(),
                tx.getBookingId(),
                tx.getCreatedAt()
        );
    }

    public static WalletResponse toWalletResponse(GetMyWalletUseCase.Wallet wallet) {
        if (wallet == null) return null;
        return new WalletResponse(
                toResponse(wallet.subscription()),
                wallet.transactions().stream()
                        .map(SubscriptionDtoMapper::toResponse)
                        .toList()
        );
    }
}
