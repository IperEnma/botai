import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';

/// Ayuda inline: cómo generar el Access Token en Meta Business Settings.
class WhatsAppAccessTokenHelpButton extends StatelessWidget {
  const WhatsAppAccessTokenHelpButton({
    super.key,
    this.style = WhatsAppAccessTokenHelpStyle.material,
  });

  final WhatsAppAccessTokenHelpStyle style;

  @override
  Widget build(BuildContext context) {
    final isKonecta = style == WhatsAppAccessTokenHelpStyle.konecta;

    if (isKonecta) {
      return TextButton(
        onPressed: () => showWhatsAppAccessTokenHelp(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: KTokens.inkMuted,
        ),
        child: Text(
          '¿Cómo generarlo?',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: KTokens.inkMuted.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Cómo generar el Access Token',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: () => showWhatsAppAccessTokenHelp(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }
}

enum WhatsAppAccessTokenHelpStyle { material, konecta }

Future<void> showWhatsAppAccessTokenHelp(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Access Token de WhatsApp'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estos pasos los hacés vos con tu cuenta de Meta Business '
                '(administrador del portfolio). Konecta no genera ni ve tu token.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 8),
              Text(
                'Generá un token de usuario del sistema en Meta Business Settings '
                '(permanente recomendado para producción).',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 16),
              const _HelpStep(
                n: 1,
                text:
                    'Entrá a Meta Business Settings (business.facebook.com/settings).',
              ),
              const _HelpStep(
                n: 2,
                text: 'Menú lateral: Usuarios → Usuarios del sistema.',
              ),
              const _HelpStep(
                n: 3,
                text:
                    'Clic en Agregar y creá un usuario del sistema. '
                    'Asignale rol de Administrador del portfolio (vos, como dueño del negocio, '
                    'tenés que tener permisos de admin en Meta Business para hacer esto).',
              ),
              const _HelpStep(
                n: 4,
                text:
                    'Con ese usuario seleccionado: Agregar activos → '
                    'elegí la app de Meta de tu negocio que usa WhatsApp y otorgale control total '
                    '(también lo hacés vos desde tu Business Settings).',
              ),
              const _HelpStep(
                n: 5,
                text:
                    'Con el usuario seleccionado: Generar nuevo token. '
                    'En el modal elegí tu app, la caducidad más larga posible '
                    '(a veces aparece “Nunca”) y estos permisos:',
              ),
              const SizedBox(height: 12),
              _PermissionTile(
                name: 'whatsapp_business_messaging',
                detail:
                    'Enviar y responder mensajes; leer mensajes recibidos por la API.',
              ),
              const SizedBox(height: 8),
              _PermissionTile(
                name: 'whatsapp_business_management',
                detail:
                    'Administrar activos de WhatsApp Business; consultar números y configuración.',
              ),
              const SizedBox(height: 12),
              const _HelpStep(
                n: 6,
                text:
                    'Generá el token, copialo de inmediato y pegalo acá. '
                    'Meta no vuelve a mostrar el token completo después.',
              ),
              const SizedBox(height: 12),
              Text(
                'El token se guarda cifrado en el servidor; no hace falta volver a pegarlo '
                'salvo que lo regeneres en Meta.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({required this.n, required this.text});

  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '$n',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.45)),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.name, required this.detail});

  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(detail, style: TextStyle(fontSize: 12, color: Colors.grey[800], height: 1.35)),
        ],
      ),
    );
  }
}
