package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.Objects;
import java.util.UUID;

/**
 * Plantilla de notificación configurable por el negocio.
 *
 * <p>El {@code cuerpo} puede incluir placeholders como {@code {dias}},
 * {@code {saldo}} o {@code {nombre}} que el scheduler sustituye antes
 * de enviar.</p>
 */
public final class NotificationTemplate {

    public static final String CODIGO_EXPIRACION = "EXPIRACION_PRONTO";
    public static final String CODIGO_SALDO_BAJO = "SALDO_BAJO";
    public static final String CODIGO_LOYALTY = "LOYALTY_TRIGGERED";

    private final UUID id;
    private final UUID businessId;
    private final String codigo;
    private final NotificationCanal canal;
    private final String titulo;
    private final String cuerpo;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public NotificationTemplate(UUID id, UUID businessId, String codigo,
                                NotificationCanal canal, String titulo, String cuerpo,
                                LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.businessId = Objects.requireNonNull(businessId, "businessId");
        this.codigo = Objects.requireNonNull(codigo, "codigo");
        this.canal = Objects.requireNonNull(canal, "canal");
        this.titulo = Objects.requireNonNull(titulo, "titulo");
        this.cuerpo = Objects.requireNonNull(cuerpo, "cuerpo");
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public UUID getId() { return id; }
    public UUID getBusinessId() { return businessId; }
    public String getCodigo() { return codigo; }
    public NotificationCanal getCanal() { return canal; }
    public String getTitulo() { return titulo; }
    public String getCuerpo() { return cuerpo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
