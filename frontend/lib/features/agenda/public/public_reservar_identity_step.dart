import 'package:flutter/material.dart';

import '../../../core/agenda_icon_registry.dart';
import '../../../widgets/agenda_phone_field.dart';
import 'public_reservar_layout.dart';

enum PublicReservarIdentityPhase { phone, code, attendee }

/// Datos personales: verificación de cuenta (teléfono) + quién asiste al turno.
class PublicReservarIdentityStep extends StatelessWidget {
  const PublicReservarIdentityStep({
    super.key,
    required this.theme,
    required this.phase,
    required this.formKey,
    required this.telCtrl,
    required this.codeCtrl,
    required this.attendeeNombreCtrl,
    required this.emailCtrl,
    required this.bookingForOther,
    required this.onBookingForOtherChanged,
    required this.serviceName,
    required this.categorySlugs,
    required this.dateLabel,
    required this.slotLabel,
    required this.staffLabel,
    required this.showStaffRow,
    this.otpError,
    this.otpHint,
    this.phoneReadOnly = false,
    this.requireAttendeeName = true,
  });

  final PublicReservarTheme theme;
  final PublicReservarIdentityPhase phase;
  final GlobalKey<FormState> formKey;
  final TextEditingController telCtrl;
  final TextEditingController codeCtrl;
  final TextEditingController attendeeNombreCtrl;
  final TextEditingController emailCtrl;
  final bool bookingForOther;
  final ValueChanged<bool> onBookingForOtherChanged;
  final String serviceName;
  final List<String> categorySlugs;
  final String dateLabel;
  final String slotLabel;
  final String staffLabel;
  final bool showStaffRow;
  final String? otpError;
  final String? otpHint;
  final bool phoneReadOnly;
  final bool requireAttendeeName;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BookingSummaryCard(
            theme: t,
            serviceName: serviceName,
            categorySlugs: categorySlugs,
            dateLabel: dateLabel,
            slotLabel: slotLabel,
            staffLabel: staffLabel,
            showStaffRow: showStaffRow,
          ),
          const SizedBox(height: 24),
          if (phase == PublicReservarIdentityPhase.phone) ...[
            _SectionHeader(
              theme: t,
              icon: Icons.verified_user_outlined,
              title: 'Verificá tu número',
              subtitle:
                  'Tu teléfono identifica tu cuenta. Te enviaremos un código por WhatsApp.',
            ),
            const SizedBox(height: 16),
            if (phoneReadOnly)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Teléfono verificado',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(telCtrl.text, style: t.textStyle(size: 16)),
              )
            else
              AgendaPhoneField(
                controller: telCtrl,
                required: true,
                useKonectaTokens: false,
                helperText: 'Código de país + número móvil',
              ),
          ],
          if (phase == PublicReservarIdentityPhase.code) ...[
            _SectionHeader(
              theme: t,
              icon: Icons.sms_outlined,
              title: 'Código de WhatsApp',
              subtitle: otpHint ??
                  'Ingresá el código de 6 dígitos que recibiste.',
            ),
            if (telCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Enviado a ${telCtrl.text}',
                style: t.textStyle(size: 13, weight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Código de verificación',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (otpError != null) ...[
              const SizedBox(height: 8),
              Text(
                otpError!,
                style: t.textStyle(size: 13, color: Colors.red.shade700),
              ),
            ],
          ],
          if (phase == PublicReservarIdentityPhase.attendee) ...[
            _SectionHeader(
              theme: t,
              icon: Icons.person_outline,
              title: '¿Quién asiste al turno?',
              subtitle:
                  'Tu cuenta queda vinculada al teléfono verificado. Podés reservar para vos o para otra persona.',
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: bookingForOther,
              onChanged: onBookingForOtherChanged,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Reservo para otra persona',
                style: t.textStyle(size: 14, weight: FontWeight.w600),
              ),
              subtitle: Text(
                'El turno quedará a nombre de quien indiques abajo.',
                style: t.textStyle(size: 12, color: t.textSub),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: attendeeNombreCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Nombre de quien asiste',
                hintText: 'Ej. María González',
                helperText: bookingForOther
                    ? 'Obligatorio · aparece en el turno'
                    : 'Podés editarlo si hace falta',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) {
                if (!requireAttendeeName) return null;
                if (v == null || v.trim().isEmpty) {
                  return 'Ingresá el nombre de quien asiste';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo de contacto (opcional)',
                hintText: 'tu@email.com',
                helperText: 'Para confirmaciones o recordatorios',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            _InfoBox(
              theme: t,
              text:
                  'Tu teléfono (${telCtrl.text}) queda como cuenta verificada. '
                  'Podés agendar varios turnos con el mismo número, incluso para otras personas.',
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final PublicReservarTheme theme;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: t.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: t.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.textStyle(size: 16, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: t.textStyle(size: 13, color: t.textSub)),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.theme,
    required this.serviceName,
    required this.categorySlugs,
    required this.dateLabel,
    required this.slotLabel,
    required this.staffLabel,
    required this.showStaffRow,
  });

  final PublicReservarTheme theme;
  final String serviceName;
  final List<String> categorySlugs;
  final String dateLabel;
  final String slotLabel;
  final String staffLabel;
  final bool showStaffRow;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          _SummaryRow(
            theme: t,
            icon: AgendaIconRegistry.forService(
              serviceName,
              categorySlugs: categorySlugs,
            ),
            label: 'Servicio',
            value: serviceName,
          ),
          if (showStaffRow)
            _SummaryRow(
              theme: t,
              icon: Icons.person_outline,
              label: 'Profesional',
              value: staffLabel,
            ),
          _SummaryRow(
            theme: t,
            icon: Icons.calendar_today_outlined,
            label: 'Fecha',
            value: dateLabel,
          ),
          _SummaryRow(
            theme: t,
            icon: Icons.access_time,
            label: 'Horario',
            value: slotLabel,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  final PublicReservarTheme theme;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: t.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.textStyle(size: 11, color: t.textSub)),
                Text(value, style: t.textStyle(size: 14, weight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.theme, required this.text});

  final PublicReservarTheme theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: t.textSub),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: t.textStyle(size: 12, color: t.textSub)),
          ),
        ],
      ),
    );
  }
}
