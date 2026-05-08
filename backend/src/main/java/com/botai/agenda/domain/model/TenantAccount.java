package com.botai.agenda.domain.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Cuenta de tenant registrado en el módulo AGENDA.
 * POJO inmutable — no depende de Spring ni JPA.
 * <p>Identificador de login de negocio: {@link #email} (correo) o {@link #numero} (teléfono solo dígitos), al menos uno.</p>
 */
public final class TenantAccount {

    private final String tenantId;
    private final String nombrePropietario;
    /** Correo de registro (no confundir con {@link #googleLinkedEmail}). */
    private final String email;
    /** Gmail u otro correo vinculado para resolver sesión Google. */
    private final String googleLinkedEmail;
    /** Identificador de cuenta por WhatsApp: solo dígitos, sin sufijos. */
    private final String numero;
    private final String telefono;
    private final String accessCode;
    private final boolean activo;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    public TenantAccount(String tenantId,
                         String nombrePropietario,
                         String email,
                         String googleLinkedEmail,
                         String numero,
                         String telefono,
                         String accessCode,
                         boolean activo,
                         LocalDateTime createdAt,
                         LocalDateTime updatedAt) {
        this.tenantId = Objects.requireNonNull(tenantId, "tenantId");
        this.nombrePropietario = Objects.requireNonNull(nombrePropietario, "nombrePropietario");
        this.email = blankToNull(email);
        this.googleLinkedEmail = blankToNull(googleLinkedEmail);
        this.numero = blankToNull(numero);
        this.telefono = telefono;
        this.accessCode = Objects.requireNonNull(accessCode, "accessCode");
        this.activo = activo;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        if (this.email == null && this.numero == null) {
            throw new IllegalArgumentException("TenantAccount requiere email o numero");
        }
    }

    private static String blankToNull(String s) {
        if (s == null || s.isBlank()) {
            return null;
        }
        return s;
    }

    public String getTenantId() { return tenantId; }
    public String getNombrePropietario() { return nombrePropietario; }
    public String getEmail() { return email; }
    public String getGoogleLinkedEmail() { return googleLinkedEmail; }
    public String getNumero() { return numero; }
    public String getTelefono() { return telefono; }
    public String getAccessCode() { return accessCode; }
    public boolean isActivo() { return activo; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
