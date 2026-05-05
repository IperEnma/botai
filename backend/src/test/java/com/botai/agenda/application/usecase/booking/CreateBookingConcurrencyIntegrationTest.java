package com.botai.agenda.application.usecase.booking;

import com.botai.agenda.AbstractAgendaIntegrationTest;
import com.botai.agenda.domain.exception.BookingSlotTakenException;
import com.botai.agenda.domain.exception.NoCreditsException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;

import java.time.LocalDateTime;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Test de concurrencia de {@link CreateBookingUseCase}.
 *
 * <p>Lo que validamos: si {@code N} threads intentan reservar contra la
 * <b>misma suscripción</b> con {@code saldo=1}, solo uno gana y los demás
 * reciben {@code NoCreditsException} (o {@code BookingSlotTakenException} si
 * compiten también por el mismo slot). El lock pesimista en
 * {@code agenda_user_subscriptions} tiene que serializar el flujo y evitar
 * doble descuento.</p>
 *
 * <p>Opt-in vía variable de entorno {@code AGENDA_IT=true} (ver
 * {@link AbstractAgendaIntegrationTest}).</p>
 */
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_CLASS)
class CreateBookingConcurrencyIntegrationTest extends AbstractAgendaIntegrationTest {

    private static final String TENANT_ID = "test-tenant-booking-concurrency";

    @Autowired
    private CreateBookingUseCase createBooking;

    @Autowired
    private JdbcTemplate jdbc;

    private UUID businessId;
    private UUID serviceId;
    private UUID userId;
    private UUID planId;
    private UUID subscriptionId;

    @BeforeEach
    void seed() {
        // Limpieza total para aislamiento entre corridas.
        jdbc.update("DELETE FROM agenda_credit_transactions WHERE subscription_id IN " +
                "(SELECT s.id FROM agenda_user_subscriptions s JOIN agenda_businesses b ON s.business_id = b.id WHERE b.tenant_id = ?)",
                TENANT_ID);
        jdbc.update("DELETE FROM agenda_bookings WHERE business_id IN (SELECT id FROM agenda_businesses WHERE tenant_id = ?)", TENANT_ID);
        jdbc.update("DELETE FROM agenda_user_subscriptions WHERE business_id IN (SELECT id FROM agenda_businesses WHERE tenant_id = ?)", TENANT_ID);
        jdbc.update("DELETE FROM agenda_plans WHERE business_id IN (SELECT id FROM agenda_businesses WHERE tenant_id = ?)", TENANT_ID);
        jdbc.update("DELETE FROM agenda_services WHERE business_id IN (SELECT id FROM agenda_businesses WHERE tenant_id = ?)", TENANT_ID);
        jdbc.update("DELETE FROM agenda_businesses WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_users WHERE tenant_id = ?", TENANT_ID);
        jdbc.update("DELETE FROM agenda_tenant_config WHERE tenant_id = ?", TENANT_ID);

        jdbc.update("INSERT INTO agenda_tenant_config (tenant_id, agenda_enabled) VALUES (?, TRUE)", TENANT_ID);

        userId = UUID.randomUUID();
        businessId = UUID.randomUUID();
        serviceId = UUID.randomUUID();
        planId = UUID.randomUUID();
        subscriptionId = UUID.randomUUID();

        jdbc.update(
                "INSERT INTO agenda_users (id, tenant_id, nombre, tipo_usuario) VALUES (?, ?, ?, 'CLIENT')",
                userId, TENANT_ID, "User Concurrencia"
        );
        jdbc.update(
                "INSERT INTO agenda_businesses (id, tenant_id, nombre) VALUES (?, ?, ?)",
                businessId, TENANT_ID, "Negocio Concurrencia"
        );
        jdbc.update(
                "INSERT INTO agenda_services (id, business_id, nombre, duracion_min) VALUES (?, ?, ?, ?)",
                serviceId, businessId, "Servicio 30min", 30
        );
        jdbc.update(
                "INSERT INTO agenda_plans (id, business_id, nombre_plan, tipo, total_creditos, validez_dias, precio, activo) " +
                        "VALUES (?, ?, ?, 'POR_CREDITOS', 10, 30, 1000, TRUE)",
                planId, businessId, "Plan 10 créditos"
        );
        LocalDateTime now = LocalDateTime.now();
        jdbc.update(
                "INSERT INTO agenda_user_subscriptions " +
                        "(id, user_id, plan_id, business_id, saldo_actual, fecha_inicio, fecha_expiracion, estado) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, 'ACTIVE')",
                subscriptionId, userId, planId, businessId, 1,
                now.minusDays(1), now.plusDays(30)
        );
    }

    /**
     * N threads apuntan a la misma suscripción y al mismo slot. Solo uno puede
     * ganar: el descuento de crédito + el INSERT del booking se hacen bajo el
     * lock. El resto deben recibir un error de negocio (NoCredits o SlotTaken)
     * y <b>nunca</b> dejar el saldo en negativo ni dos bookings activos.
     */
    @Test
    void soloUnaReservaGanaCuandoTodasCompitenPorElMismoSaldo() throws Exception {
        // OJO: mantenemos threads <= pool de Hikari (default 10) para no saturar
        // conexiones — si cada thread abre una @Transactional y el pool se
        // llena, el timeout deja al resto de la suite sin conexiones.
        int threads = 6;
        LocalDateTime inicio = LocalDateTime.now().plusDays(1).withNano(0).withSecond(0);

        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CountDownLatch start = new CountDownLatch(1);
        AtomicInteger ganadores = new AtomicInteger(0);
        AtomicInteger noCredits = new AtomicInteger(0);
        AtomicInteger slotTaken = new AtomicInteger(0);
        AtomicInteger otros = new AtomicInteger(0);

        Future<?>[] futures = new Future<?>[threads];
        for (int i = 0; i < threads; i++) {
            futures[i] = pool.submit(() -> {
                try {
                    start.await();
                    createBooking.execute(
                            TENANT_ID, businessId, userId,
                            serviceId, subscriptionId, null, inicio, null);
                    ganadores.incrementAndGet();
                } catch (NoCreditsException e) {
                    noCredits.incrementAndGet();
                } catch (BookingSlotTakenException e) {
                    slotTaken.incrementAndGet();
                } catch (Exception e) {
                    otros.incrementAndGet();
                }
                return null;
            });
        }
        start.countDown();
        for (Future<?> f : futures) {
            f.get(30, TimeUnit.SECONDS);
        }
        pool.shutdown();

        // Exactamente una reserva ganadora — el invariante crítico.
        assertEquals(1, ganadores.get(),
                "Solo un thread puede ganar la carrera por el último crédito");
        assertEquals(0, otros.get(),
                "No esperamos excepciones inesperadas (solo NoCredits o SlotTaken). Hubo: " + otros.get());
        assertEquals(threads - 1, noCredits.get() + slotTaken.get(),
                "Todos los perdedores deben fallar con NoCredits o SlotTaken");

        // En la DB: saldo=0, exactamente 1 booking confirmado, exactamente 1 tx con monto=-1.
        Integer saldoFinal = jdbc.queryForObject(
                "SELECT saldo_actual FROM agenda_user_subscriptions WHERE id = ?",
                Integer.class, subscriptionId);
        assertEquals(0, saldoFinal,
                "El saldo final debe ser exactamente 0 — nunca negativo");

        Integer bookingsConfirmados = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_bookings WHERE subscription_id = ? AND estado = 'CONFIRMED'",
                Integer.class, subscriptionId);
        assertEquals(1, bookingsConfirmados,
                "Debe haber exactamente 1 booking CONFIRMED asociado a la suscripción");

        Integer txDescuento = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_credit_transactions WHERE subscription_id = ? AND monto = -1 AND motivo = 'RESERVA'",
                Integer.class, subscriptionId);
        assertEquals(1, txDescuento,
                "Debe haber exactamente 1 transacción RESERVA con monto=-1");
    }

    /**
     * Si la suscripción tiene {@code saldo=2} y los threads usan <b>distintos</b>
     * slots del mismo servicio, pueden ganar dos. El punto es validar que el
     * lock no está serializando todo el universo: dos requests con recursos
     * disjuntos pueden progresar en paralelo (o al menos sin rechazar al
     * segundo por credit).
     */
    @Test
    void dosThreadsConSlotsDistintosYSaldo2AmbosGanan() throws Exception {
        // Repoblamos la subscripción con saldo=2.
        jdbc.update("UPDATE agenda_user_subscriptions SET saldo_actual = 2 WHERE id = ?", subscriptionId);

        LocalDateTime slotA = LocalDateTime.now().plusDays(1).withNano(0).withSecond(0);
        LocalDateTime slotB = slotA.plusHours(2);

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        AtomicInteger ganadores = new AtomicInteger(0);
        AtomicInteger errores = new AtomicInteger(0);

        Future<?> fa = pool.submit(() -> {
            try {
                start.await();
                createBooking.execute(TENANT_ID, businessId, userId, serviceId, subscriptionId, null, slotA, null);
                ganadores.incrementAndGet();
            } catch (Exception e) {
                errores.incrementAndGet();
            }
            return null;
        });
        Future<?> fb = pool.submit(() -> {
            try {
                start.await();
                createBooking.execute(TENANT_ID, businessId, userId, serviceId, subscriptionId, null, slotB, null);
                ganadores.incrementAndGet();
            } catch (Exception e) {
                errores.incrementAndGet();
            }
            return null;
        });
        start.countDown();
        fa.get(30, TimeUnit.SECONDS);
        fb.get(30, TimeUnit.SECONDS);
        pool.shutdown();

        assertEquals(2, ganadores.get(),
                "Con saldo=2 y slots disjuntos, ambos threads deben ganar");
        assertEquals(0, errores.get(), "Ningún thread debería fallar");

        Integer saldoFinal = jdbc.queryForObject(
                "SELECT saldo_actual FROM agenda_user_subscriptions WHERE id = ?",
                Integer.class, subscriptionId);
        assertEquals(0, saldoFinal, "Saldo final debe ser 0 tras dos descuentos");

        Integer bookingsConfirmados = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_bookings WHERE subscription_id = ? AND estado = 'CONFIRMED'",
                Integer.class, subscriptionId);
        assertEquals(2, bookingsConfirmados, "Deben existir 2 bookings CONFIRMED");

        Integer txRESERVA = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_credit_transactions WHERE subscription_id = ? AND motivo = 'RESERVA'",
                Integer.class, subscriptionId);
        assertEquals(2, txRESERVA, "Deben existir 2 transacciones RESERVA (una por booking)");
    }

    /**
     * Escenario del bug original: dos USUARIOS DISTINTOS (suscripciones
     * distintas) compiten por el MISMO slot del mismo servicio.
     *
     * <p>Antes del constraint {@code excl_agenda_bookings_slot} (V6), ambos
     * podían pasar el check de aplicación simultáneamente y ambos insertaban
     * un booking — double-booking real. Ahora la segunda inserción falla con
     * {@code DataIntegrityViolationException} que el adapter convierte en
     * {@link BookingSlotTakenException}.</p>
     */
    @Test
    void dosUsuariosDistintosCompitienPorElMismoSlotSoloUnoGana() throws Exception {
        // Segundo usuario con su propia suscripción y créditos.
        UUID userId2 = UUID.randomUUID();
        UUID planId2 = UUID.randomUUID();
        UUID subscriptionId2 = UUID.randomUUID();
        LocalDateTime now = LocalDateTime.now();

        jdbc.update("INSERT INTO agenda_users (id, tenant_id, nombre, tipo_usuario) VALUES (?, ?, ?, 'CLIENT')",
                userId2, TENANT_ID, "User2 Concurrencia");
        jdbc.update("INSERT INTO agenda_plans (id, business_id, nombre_plan, tipo, total_creditos, validez_dias, precio, activo) " +
                        "VALUES (?, ?, ?, 'POR_CREDITOS', 10, 30, 1000, TRUE)",
                planId2, businessId, "Plan user2");
        jdbc.update("INSERT INTO agenda_user_subscriptions " +
                        "(id, user_id, plan_id, business_id, saldo_actual, fecha_inicio, fecha_expiracion, estado) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, 'ACTIVE')",
                subscriptionId2, userId2, planId2, businessId, 5,
                now.minusDays(1), now.plusDays(30));

        LocalDateTime slot = LocalDateTime.now().plusDays(3).withNano(0).withSecond(0);

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        AtomicInteger ganadores = new AtomicInteger(0);
        AtomicInteger slotTaken = new AtomicInteger(0);
        AtomicInteger otros = new AtomicInteger(0);

        // Thread A: usuario original
        Future<?> fa = pool.submit(() -> {
            try {
                start.await();
                createBooking.execute(TENANT_ID, businessId, userId, serviceId, subscriptionId, null, slot, null);
                ganadores.incrementAndGet();
            } catch (BookingSlotTakenException e) {
                slotTaken.incrementAndGet();
            } catch (Exception e) {
                otros.incrementAndGet();
            }
            return null;
        });

        // Thread B: usuario2 con su propia suscripción — mismo slot, distinto sub_id
        Future<?> fb = pool.submit(() -> {
            try {
                start.await();
                createBooking.execute(TENANT_ID, businessId, userId2, serviceId, subscriptionId2, null, slot, null);
                ganadores.incrementAndGet();
            } catch (BookingSlotTakenException e) {
                slotTaken.incrementAndGet();
            } catch (Exception e) {
                otros.incrementAndGet();
            }
            return null;
        });

        start.countDown();
        fa.get(30, TimeUnit.SECONDS);
        fb.get(30, TimeUnit.SECONDS);
        pool.shutdown();

        assertEquals(1, ganadores.get(),
                "Con el constraint EXCLUDE, exactamente un usuario gana el slot");
        assertEquals(1, slotTaken.get(),
                "El perdedor debe recibir BookingSlotTakenException, no pasar silenciosamente");
        assertEquals(0, otros.get(),
                "No esperamos otras excepciones");

        Integer bookingsConfirmados = jdbc.queryForObject(
                "SELECT COUNT(*) FROM agenda_bookings WHERE service_id = ? AND estado = 'CONFIRMED' AND fecha_hora_inicio = ?",
                Integer.class, serviceId, slot);
        assertEquals(1, bookingsConfirmados,
                "Exactamente 1 booking CONFIRMED en el slot — el constraint funcionó");
    }

    /**
     * Sanidad: el lock no corrompe datos bajo presión (más threads que
     * créditos disponibles, cada uno con un slot distinto). Mantenemos el
     * paralelismo debajo del pool de Hikari default (10) para no saturar
     * conexiones entre tests.
     */
    @Test
    void stressTestSaldo3Threads6SoloTresGanan() throws Exception {
        jdbc.update("UPDATE agenda_user_subscriptions SET saldo_actual = 3 WHERE id = ?", subscriptionId);

        int threads = 6;
        // Cada thread apunta a un slot distinto para evitar colisión por slot y
        // forzar que el único límite real sea el saldo.
        LocalDateTime base = LocalDateTime.now().plusDays(2).withNano(0).withSecond(0);

        ExecutorService pool = Executors.newFixedThreadPool(threads);
        CountDownLatch start = new CountDownLatch(1);
        AtomicInteger ganadores = new AtomicInteger(0);
        AtomicInteger noCredits = new AtomicInteger(0);
        AtomicInteger otros = new AtomicInteger(0);

        Future<?>[] futures = new Future<?>[threads];
        for (int i = 0; i < threads; i++) {
            int idx = i;
            futures[i] = pool.submit(() -> {
                try {
                    start.await();
                    createBooking.execute(
                            TENANT_ID, businessId, userId,
                            serviceId, subscriptionId,
                            null, base.plusMinutes(idx * 60L), null);
                    ganadores.incrementAndGet();
                } catch (NoCreditsException e) {
                    noCredits.incrementAndGet();
                } catch (Exception e) {
                    otros.incrementAndGet();
                }
                return null;
            });
        }
        start.countDown();
        for (Future<?> f : futures) {
            f.get(60, TimeUnit.SECONDS);
        }
        pool.shutdown();

        assertEquals(3, ganadores.get(),
                "Solo deben ganar tantos threads como créditos había (3)");
        assertEquals(threads - 3, noCredits.get(),
                "El resto debe fallar con NoCredits");
        assertEquals(0, otros.get(),
                "No esperamos otras excepciones (hubo " + otros.get() + ")");

        Integer saldoFinal = jdbc.queryForObject(
                "SELECT saldo_actual FROM agenda_user_subscriptions WHERE id = ?",
                Integer.class, subscriptionId);
        assertEquals(0, saldoFinal, "Saldo final debe ser exactamente 0, nunca negativo");
    }
}
