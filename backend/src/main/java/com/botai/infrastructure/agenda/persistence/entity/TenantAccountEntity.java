package com.botai.infrastructure.agenda.persistence.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Cuenta de tenant en {@code agenda_tenant_accounts}.
 * <ul>
 *   <li>Alta por correo: {@code email} obligatorio, {@code numero} null.</li>
 *   <li>Alta por WhatsApp: {@code numero} (dígitos) obligatorio, {@code email} null.</li>
 *   <li>{@code google_linked_email}: opcional; formato email cuando está presente (único entre filas).</li>
 * </ul>
 */
@Entity
@Table(name = "agenda_tenant_accounts")
public class TenantAccountEntity extends BaseAuditableEntity {

    @Id
    @Column(name = "tenant_id", nullable = false, length = 64)
    private String tenantId;

    @Column(name = "nombre_propietario", nullable = false)
    private String nombrePropietario;

    @Column(name = "email", length = 255)
    private String email;

    @Column(name = "google_linked_email", length = 320)
    private String googleLinkedEmail;

    @Column(name = "numero", length = 32)
    private String numero;

    @Column(name = "telefono", length = 32)
    private String telefono;

    @Column(name = "access_code", nullable = false, length = 8)
    private String accessCode;

    @Column(name = "activo", nullable = false)
    private boolean activo = true;

    public String getTenantId() { return tenantId; }
    public void setTenantId(String tenantId) { this.tenantId = tenantId; }

    public String getNombrePropietario() { return nombrePropietario; }
    public void setNombrePropietario(String nombrePropietario) { this.nombrePropietario = nombrePropietario; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getGoogleLinkedEmail() { return googleLinkedEmail; }
    public void setGoogleLinkedEmail(String googleLinkedEmail) { this.googleLinkedEmail = googleLinkedEmail; }

    public String getNumero() { return numero; }
    public void setNumero(String numero) { this.numero = numero; }

    public String getTelefono() { return telefono; }
    public void setTelefono(String telefono) { this.telefono = telefono; }

    public String getAccessCode() { return accessCode; }
    public void setAccessCode(String accessCode) { this.accessCode = accessCode; }

    public boolean isActivo() { return activo; }
    public void setActivo(boolean activo) { this.activo = activo; }
}
