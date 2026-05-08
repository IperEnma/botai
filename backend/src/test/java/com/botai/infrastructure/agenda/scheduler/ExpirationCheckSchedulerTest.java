package com.botai.infrastructure.agenda.scheduler;

import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.domain.agenda.model.NotificationTemplate;
import com.botai.domain.agenda.model.SubscriptionEstado;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.notification.NotificationPort;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.domain.agenda.repository.NotificationTemplateRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ExpirationCheckSchedulerTest {

    private UserSubscriptionRepository subscriptionRepository;
    private BusinessSettingsRepository settingsRepository;
    private NotificationTemplateRepository templateRepository;
    private NotificationPort notificationPort;
    private ExpirationCheckScheduler scheduler;

    private final LocalDateTime NOW = LocalDateTime.of(2026, 5, 10, 9, 0);
    private final UUID BUSINESS_ID = UUID.randomUUID();
    private final UUID USER_ID = UUID.randomUUID();
    private final UUID PLAN_ID = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        subscriptionRepository = mock(UserSubscriptionRepository.class);
        settingsRepository = mock(BusinessSettingsRepository.class);
        templateRepository = mock(NotificationTemplateRepository.class);
        notificationPort = mock(NotificationPort.class);

        Clock fixedClock = Clock.fixed(NOW.toInstant(ZoneOffset.UTC), ZoneOffset.UTC);

        scheduler = new ExpirationCheckScheduler(
                subscriptionRepository,
                settingsRepository,
                templateRepository,
                notificationPort,
                fixedClock
        );

        when(settingsRepository.findByBusinessId(any()))
                .thenReturn(Optional.of(BusinessSettings.defaults(BUSINESS_ID)));
        when(templateRepository.findByBusinessIdAndCodigoAndCanal(any(), any(), any()))
                .thenReturn(Optional.empty());
    }

    // ── vencimiento próximo ───────────────────────────────────────────────────

    @Test
    void subscripcionVenceEnVentana_enviaNotificacion() {
        // defaults: expirationAlertDays = 7 → alerta si vence en <= 7 días
        UserSubscription sub = subExpirando(NOW.plusDays(5));
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of(sub));
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of());

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort).send(eq(BUSINESS_ID), eq(USER_ID), any(), any(),
                eq(NotificationCanal.IN_APP));
    }

    @Test
    void subscripcionVenceFueraDeVentana_noEnviaNotificacion() {
        // Vence en 10 días, ventana es 7 → fuera de alerta
        UserSubscription sub = subExpirando(NOW.plusDays(10));
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of(sub));
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of());

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort, never()).send(any(), any(), any(), any(), any());
    }

    @Test
    void conPlantillaConfigurada_usaCuerpoDeTemplate() {
        UserSubscription sub = subExpirando(NOW.plusDays(3));
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of(sub));
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of());

        NotificationTemplate template = new NotificationTemplate(
                UUID.randomUUID(), BUSINESS_ID, NotificationTemplate.CODIGO_EXPIRACION,
                NotificationCanal.IN_APP, "¡Renueva!", "Vence en {dias} días.",
                NOW, NOW);
        when(templateRepository.findByBusinessIdAndCodigoAndCanal(
                BUSINESS_ID, NotificationTemplate.CODIGO_EXPIRACION, NotificationCanal.IN_APP))
                .thenReturn(Optional.of(template));

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort).send(eq(BUSINESS_ID), eq(USER_ID),
                eq("¡Renueva!"), eq("Vence en 3 días."), eq(NotificationCanal.IN_APP));
    }

    @Test
    void variasSubscripcionesVenciendo_enviaUnaNotificacionPorCada() {
        UserSubscription sub1 = subExpirando(NOW.plusDays(2));
        UserSubscription sub2 = subExpirando(NOW.plusDays(4));
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of(sub1, sub2));
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of());

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort, times(2)).send(any(), any(), any(), any(), any());
    }

    // ── saldo bajo ────────────────────────────────────────────────────────────

    @Test
    void saldoPorDebajoDelUmbral_enviaNotificacion() {
        // defaults: expirationAlertCredits = 2
        UserSubscription sub = subConSaldo(1);
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of());
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of(sub));

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort).send(eq(BUSINESS_ID), eq(USER_ID), any(), any(),
                eq(NotificationCanal.IN_APP));
    }

    @Test
    void saldoExactamenteEnUmbral_enviaNotificacion() {
        UserSubscription sub = subConSaldo(2); // defaults: umbral = 2
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of());
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of(sub));

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort).send(any(), any(), any(), any(), any());
    }

    @Test
    void saldoSobreElUmbralDelNegocio_noEnviaNotificacion() {
        // El candidato tiene saldo 3 pero el umbral del negocio es 2 (defaults)
        UserSubscription sub = subConSaldo(3);
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of());
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of(sub));

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort, never()).send(any(), any(), any(), any(), any());
    }

    @Test
    void conPlantillaSaldoBajo_usaCuerpoDeTemplate() {
        UserSubscription sub = subConSaldo(1);
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of());
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of(sub));

        NotificationTemplate template = new NotificationTemplate(
                UUID.randomUUID(), BUSINESS_ID, NotificationTemplate.CODIGO_SALDO_BAJO,
                NotificationCanal.IN_APP, "Saldo crítico", "Solo te quedan {saldo} créditos.",
                NOW, NOW);
        when(templateRepository.findByBusinessIdAndCodigoAndCanal(
                BUSINESS_ID, NotificationTemplate.CODIGO_SALDO_BAJO, NotificationCanal.IN_APP))
                .thenReturn(Optional.of(template));

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort).send(any(), any(), eq("Saldo crítico"),
                eq("Solo te quedan 1 créditos."), any());
    }

    // ── sin candidatos ────────────────────────────────────────────────────────

    @Test
    void sinCandidatos_noEnviaNotificaciones() {
        when(subscriptionRepository.findAllActiveExpiringSoon(any(), any()))
                .thenReturn(List.of());
        when(subscriptionRepository.findAllActiveWithLowBalance(anyInt()))
                .thenReturn(List.of());

        scheduler.checkExpirationsAndLowBalance();

        verify(notificationPort, never()).send(any(), any(), any(), any(), any());
    }

    // ── fixtures ──────────────────────────────────────────────────────────────

    private UserSubscription subExpirando(LocalDateTime expiracion) {
        return new UserSubscription(UUID.randomUUID(), USER_ID, PLAN_ID, BUSINESS_ID,
                5, NOW.minusDays(30), expiracion,
                SubscriptionEstado.ACTIVE, NOW.minusDays(30), NOW.minusDays(30));
    }

    private UserSubscription subConSaldo(int saldo) {
        return new UserSubscription(UUID.randomUUID(), USER_ID, PLAN_ID, BUSINESS_ID,
                saldo, NOW.minusDays(30), NOW.plusDays(30),
                SubscriptionEstado.ACTIVE, NOW.minusDays(30), NOW.minusDays(30));
    }
}
