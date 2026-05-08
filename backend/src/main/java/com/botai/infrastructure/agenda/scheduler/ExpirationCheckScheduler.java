package com.botai.infrastructure.agenda.scheduler;

import com.botai.domain.agenda.model.BusinessSettings;
import com.botai.domain.agenda.model.NotificationCanal;
import com.botai.domain.agenda.model.NotificationTemplate;
import com.botai.domain.agenda.model.UserSubscription;
import com.botai.domain.agenda.notification.NotificationPort;
import com.botai.domain.agenda.repository.BusinessSettingsRepository;
import com.botai.domain.agenda.repository.NotificationTemplateRepository;
import com.botai.domain.agenda.repository.UserSubscriptionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * CU-02 — Notificación de Renovación.
 *
 * <p>Se ejecuta diariamente (por defecto a las 9:00 AM, configurable vía
 * {@code agenda.notifications.scheduled-cron}). Evalúa dos condiciones sobre
 * todas las suscripciones activas:</p>
 *
 * <ul>
 *   <li><b>Vencimiento próximo:</b> la suscripción expira dentro de los próximos
 *       {@code expirationAlertDays} días (según la config del negocio, o 7 por
 *       defecto). Envía una notificación usando la plantilla {@code EXPIRACION_PRONTO}
 *       si existe, o un mensaje por defecto si no.</li>
 *   <li><b>Saldo bajo:</b> saldo actual ≤ {@code expirationAlertCredits} (default 2).
 *       Usa la plantilla {@code SALDO_BAJO}.</li>
 * </ul>
 *
 * <p>El threshold de saldo bajo es global (2 créditos) porque se quiere dar
 * la misma experiencia independientemente de cuánto haya configurado el negocio.
 * El {@code expirationAlertCredits} de {@link BusinessSettings} permite
 * personalizarlo por negocio.</p>
 */
@Component
public class ExpirationCheckScheduler {

    private static final Logger log = LoggerFactory.getLogger(ExpirationCheckScheduler.class);

    private final UserSubscriptionRepository subscriptionRepository;
    private final BusinessSettingsRepository settingsRepository;
    private final NotificationTemplateRepository templateRepository;
    private final NotificationPort notificationPort;
    private final Clock clock;

    public ExpirationCheckScheduler(UserSubscriptionRepository subscriptionRepository,
                                    BusinessSettingsRepository settingsRepository,
                                    NotificationTemplateRepository templateRepository,
                                    NotificationPort notificationPort,
                                    Clock clock) {
        this.subscriptionRepository = subscriptionRepository;
        this.settingsRepository = settingsRepository;
        this.templateRepository = templateRepository;
        this.notificationPort = notificationPort;
        this.clock = clock;
    }

    @Scheduled(cron = "${agenda.notifications.scheduled-cron:0 0 9 * * *}")
    @Transactional
    public void checkExpirationsAndLowBalance() {
        LocalDateTime now = LocalDateTime.now(clock);
        log.info("AGENDA scheduler: iniciando revisión CU-02 en {}", now);

        checkExpiringSoon(now);
        checkLowBalance(now);

        log.info("AGENDA scheduler: revisión CU-02 completada");
    }

    private void checkExpiringSoon(LocalDateTime now) {
        // Ventana máxima posible entre todos los negocios; se filtrará por-negocio abajo.
        // Usamos 30 días como límite superior seguro (ningún negocio configura más de 30d).
        LocalDateTime until = now.plusDays(30);
        List<UserSubscription> candidates =
                subscriptionRepository.findAllActiveExpiringSoon(now, until);

        for (UserSubscription sub : candidates) {
            BusinessSettings settings = settingsRepository
                    .findByBusinessId(sub.getBusinessId())
                    .orElseGet(() -> BusinessSettings.defaults(sub.getBusinessId()));

            LocalDateTime alertThreshold = now.plusDays(settings.getExpirationAlertDays());
            if (sub.getFechaExpiracion().isAfter(alertThreshold)) {
                continue; // aún no entra en la ventana de alerta de este negocio
            }

            long diasRestantes = java.time.temporal.ChronoUnit.DAYS.between(
                    now.toLocalDate(), sub.getFechaExpiracion().toLocalDate());

            String titulo = "Tu suscripción vence pronto";
            String cuerpo = "Tu suscripción vence en " + diasRestantes + " día(s). ¡Renuévala para seguir disfrutando!";

            Optional<NotificationTemplate> template = templateRepository
                    .findByBusinessIdAndCodigoAndCanal(
                            sub.getBusinessId(), NotificationTemplate.CODIGO_EXPIRACION,
                            NotificationCanal.IN_APP);
            if (template.isPresent()) {
                titulo = template.get().getTitulo();
                cuerpo = template.get().getCuerpo()
                        .replace("{dias}", String.valueOf(diasRestantes));
            }

            notificationPort.send(sub.getBusinessId(), sub.getUserId(),
                    titulo, cuerpo, NotificationCanal.IN_APP);
            log.debug("AGENDA scheduler: alerta vencimiento user={} dias={}", sub.getUserId(), diasRestantes);
        }
    }

    private void checkLowBalance(LocalDateTime now) {
        // Threshold global para detectar candidatos; el filtro fino es por-negocio abajo.
        int globalMaxSaldo = 5;
        List<UserSubscription> candidates =
                subscriptionRepository.findAllActiveWithLowBalance(globalMaxSaldo);

        for (UserSubscription sub : candidates) {
            BusinessSettings settings = settingsRepository
                    .findByBusinessId(sub.getBusinessId())
                    .orElseGet(() -> BusinessSettings.defaults(sub.getBusinessId()));

            if (sub.getSaldoActual() > settings.getExpirationAlertCredits()) {
                continue; // por encima del umbral de este negocio
            }

            String titulo = "Saldo de créditos bajo";
            String cuerpo = "Te quedan " + sub.getSaldoActual() + " crédito(s). ¡Recarga para no perder tus reservas!";

            Optional<NotificationTemplate> template = templateRepository
                    .findByBusinessIdAndCodigoAndCanal(
                            sub.getBusinessId(), NotificationTemplate.CODIGO_SALDO_BAJO,
                            NotificationCanal.IN_APP);
            if (template.isPresent()) {
                titulo = template.get().getTitulo();
                cuerpo = template.get().getCuerpo()
                        .replace("{saldo}", String.valueOf(sub.getSaldoActual()));
            }

            notificationPort.send(sub.getBusinessId(), sub.getUserId(),
                    titulo, cuerpo, NotificationCanal.IN_APP);
            log.debug("AGENDA scheduler: alerta saldo bajo user={} saldo={}", sub.getUserId(), sub.getSaldoActual());
        }
    }
}
