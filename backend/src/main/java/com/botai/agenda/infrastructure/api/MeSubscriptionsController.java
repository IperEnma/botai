package com.botai.agenda.infrastructure.api;

import com.botai.agenda.application.dto.PurchaseSubscriptionRequest;
import com.botai.agenda.application.dto.SubscriptionResponse;
import com.botai.agenda.application.dto.WalletResponse;
import com.botai.agenda.application.mapper.SubscriptionDtoMapper;
import com.botai.agenda.application.usecase.subscription.GetMyWalletUseCase;
import com.botai.agenda.application.usecase.subscription.ListMySubscriptionsUseCase;
import com.botai.agenda.application.usecase.subscription.PurchaseSubscriptionUseCase;
import com.botai.agenda.domain.repository.BusinessRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * Endpoints para el usuario final autenticado. La identidad viene por header
 * {@code X-User-Id}; hasta que exista un módulo de auth completo esto es
 * suficiente para avanzar con Slice 2 sin bloquear otros fronts.
 *
 * <p>Queda bajo {@code /api/agenda/me/**}, alcance protegido por
 * {@code AgendaFeatureGuard}.</p>
 */
@RestController
@RequestMapping("/api/agenda/me")
@Tag(name = "Agenda Me · Subscriptions", description = "Compra y consulta de suscripciones del usuario autenticado")
@Validated
public class MeSubscriptionsController {

    private static final String USER_ID_HEADER = "X-User-Id";

    private final PurchaseSubscriptionUseCase purchaseSubscription;
    private final ListMySubscriptionsUseCase listMySubscriptions;
    private final GetMyWalletUseCase getMyWallet;
    private final BusinessRepository businessRepository;

    public MeSubscriptionsController(PurchaseSubscriptionUseCase purchaseSubscription,
                                     ListMySubscriptionsUseCase listMySubscriptions,
                                     GetMyWalletUseCase getMyWallet,
                                     BusinessRepository businessRepository) {
        this.purchaseSubscription = purchaseSubscription;
        this.listMySubscriptions = listMySubscriptions;
        this.getMyWallet = getMyWallet;
        this.businessRepository = businessRepository;
    }

    @PostMapping("/businesses/{businessId}/subscriptions")
    @Operation(summary = "Comprar una suscripción contra un plan del negocio")
    public ResponseEntity<SubscriptionResponse> purchase(
            @PathVariable("businessId") UUID businessId,
            @RequestHeader(USER_ID_HEADER) UUID userId,
            @Valid @RequestBody PurchaseSubscriptionRequest request) {
        String tenantId = businessRepository.findById(businessId)
                .map(b -> b.getTenantId())
                .orElseThrow(() -> new IllegalArgumentException("Negocio no encontrado: " + businessId));
        var created = purchaseSubscription.execute(tenantId, businessId, userId, request.planId());
        return ResponseEntity.status(HttpStatus.CREATED).body(SubscriptionDtoMapper.toResponse(created));
    }

    @GetMapping("/subscriptions")
    @Operation(summary = "Lista mis suscripciones")
    public List<SubscriptionResponse> mySubscriptions(
            @RequestHeader(USER_ID_HEADER) UUID userId,
            @Parameter(description = "Si true, solo las con estado=ACTIVE")
            @RequestParam(name = "onlyActive", defaultValue = "false") boolean onlyActive) {
        return listMySubscriptions.execute(userId, onlyActive).stream()
                .map(SubscriptionDtoMapper::toResponse)
                .toList();
    }

    @GetMapping("/subscriptions/{subscriptionId}/wallet")
    @Operation(summary = "Detalle de mi billetera: saldo + historial de movimientos")
    public WalletResponse wallet(
            @RequestHeader(USER_ID_HEADER) UUID userId,
            @PathVariable("subscriptionId") UUID subscriptionId) {
        return SubscriptionDtoMapper.toWalletResponse(getMyWallet.execute(userId, subscriptionId));
    }
}
