package com.botai.application.agenda.usecase.rbac;

import com.botai.domain.agenda.model.Role;
import com.botai.domain.agenda.notification.AgendaMailer;
import com.botai.infrastructure.config.AppUrlProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Compone y dispara los mails post-invitación:
 *
 * <ul>
 *   <li>STAFF_OPERATOR / STAFF_VIEWER / RECEPTION → mail de "te agregaron al equipo".</li>
 *   <li>TENANT_ADMIN → mail de bienvenida.</li>
 * </ul>
 *
 * <p>El send es best-effort: si el mailer falla solo se loguea (la invitación
 * ya quedó persistida).</p>
 */
@Service
public class StaffInvitationEmailService {

    private static final Logger log = LoggerFactory.getLogger(StaffInvitationEmailService.class);

    private final AgendaMailer mailer;
    private final AppUrlProperties urls;
    private final String loginPath;

    public StaffInvitationEmailService(AgendaMailer mailer,
                                       AppUrlProperties urls,
                                       @Value("${mail.login-path:/login}") String loginPath) {
        this.mailer = mailer;
        this.urls = urls;
        this.loginPath = loginPath;
    }

    public void sendForInvitation(String nombre, String email, Role role,
                                  List<String> businessNames) {
        try {
            AgendaMailer.MailMessage message = (role == Role.TENANT_ADMIN)
                    ? buildAdminWelcome(nombre, email)
                    : buildStaffInvite(nombre, email, role, businessNames);
            mailer.send(message);
        } catch (RuntimeException ex) {
            log.warn("Fallo al enviar mail de invitación email={} role={}: {}",
                    email, role, ex.getMessage());
        }
    }

    private AgendaMailer.MailMessage buildStaffInvite(String nombre, String email, Role role,
                                                     List<String> businessNames) {
        String roleLabel = roleLabel(role);
        String teamLabel = teamLabel(businessNames);
        String loginUrl = loginUrl();
        String safeNombre = escape(nombre);
        String safeTeam = escape(teamLabel);
        String safeRole = escape(roleLabel);

        String subject = "Te agregaron al equipo de " + teamLabel;
        String html = """
                <!doctype html>
                <html lang="es"><head><meta charset="utf-8"></head>
                <body style="font-family: -apple-system, Segoe UI, Roboto, sans-serif; color:#1f2937; line-height:1.5;">
                  <div style="max-width:560px; margin:0 auto; padding:24px;">
                    <h2 style="margin:0 0 16px 0; color:#111827;">Hola %s,</h2>
                    <p>Te agregaron al equipo de <strong>%s</strong> como <strong>%s</strong>.</p>
                    <p>Para controlar tu agenda, ingresá al panel:</p>
                    <p style="margin:24px 0;">
                      <a href="%s"
                         style="background:#2563eb; color:#fff; padding:12px 20px;
                                border-radius:8px; text-decoration:none; font-weight:600;">
                        Ingresar a Botai Agenda
                      </a>
                    </p>
                    <p style="font-size:13px; color:#6b7280;">
                      O copiá este link en tu navegador:<br>
                      <a href="%s" style="color:#2563eb;">%s</a>
                    </p>
                    <hr style="border:none; border-top:1px solid #e5e7eb; margin:24px 0;">
                    <p style="font-size:12px; color:#9ca3af;">
                      Recibiste este mail porque alguien te invitó a colaborar en %s en Botai Agenda.
                      Si fue un error, podés ignorarlo.
                    </p>
                  </div>
                </body></html>
                """.formatted(safeNombre, safeTeam, safeRole, loginUrl, loginUrl, loginUrl, safeTeam);

        return new AgendaMailer.MailMessage(email, subject, html);
    }

    private AgendaMailer.MailMessage buildAdminWelcome(String nombre, String email) {
        String loginUrl = loginUrl();
        String safeNombre = escape(nombre);

        String subject = "Bienvenido a Botai Agenda";
        String html = """
                <!doctype html>
                <html lang="es"><head><meta charset="utf-8"></head>
                <body style="font-family: -apple-system, Segoe UI, Roboto, sans-serif; color:#1f2937; line-height:1.5;">
                  <div style="max-width:560px; margin:0 auto; padding:24px;">
                    <h2 style="margin:0 0 16px 0; color:#111827;">Hola %s,</h2>
                    <p>Te dieron acceso como <strong>Administrador</strong> en Botai Agenda.</p>
                    <p>Desde el panel vas a poder gestionar sucursales, equipo, servicios y la agenda completa del negocio.</p>
                    <p style="margin:24px 0;">
                      <a href="%s"
                         style="background:#2563eb; color:#fff; padding:12px 20px;
                                border-radius:8px; text-decoration:none; font-weight:600;">
                        Ingresar a Botai Agenda
                      </a>
                    </p>
                    <p style="font-size:13px; color:#6b7280;">
                      O copiá este link en tu navegador:<br>
                      <a href="%s" style="color:#2563eb;">%s</a>
                    </p>
                    <hr style="border:none; border-top:1px solid #e5e7eb; margin:24px 0;">
                    <p style="font-size:12px; color:#9ca3af;">
                      Recibiste este mail porque te asignaron rol de administrador en Botai Agenda.
                      Si fue un error, podés ignorarlo.
                    </p>
                  </div>
                </body></html>
                """.formatted(safeNombre, loginUrl, loginUrl, loginUrl);

        return new AgendaMailer.MailMessage(email, subject, html);
    }

    private String loginUrl() {
        String base = urls.normalizedFrontend();
        String path = (loginPath == null || loginPath.isBlank()) ? "/login" : loginPath;
        if (!path.startsWith("/")) {
            path = "/" + path;
        }
        return base + path;
    }

    private static String teamLabel(List<String> businessNames) {
        if (businessNames == null || businessNames.isEmpty()) {
            return "tu negocio";
        }
        return String.join(", ", businessNames);
    }

    private static String roleLabel(Role role) {
        return switch (role) {
            case STAFF_OPERATOR -> "Profesional";
            case STAFF_VIEWER -> "Profesional (solo lectura)";
            case RECEPTION -> "Recepción";
            case TENANT_ADMIN -> "Administrador";
            default -> role.name();
        };
    }

    private static String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
