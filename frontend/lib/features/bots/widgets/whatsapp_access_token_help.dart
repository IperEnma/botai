import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../agenda/register/konecta_tokens.dart';

/// Botón de ayuda: cómo generar el Access Token en Meta Business Settings.
class WhatsAppAccessTokenHelpButton extends StatelessWidget {
  const WhatsAppAccessTokenHelpButton({
    super.key,
    this.compact = false,
    this.style = WhatsAppAccessTokenHelpStyle.material,
  });

  final bool compact;
  final WhatsAppAccessTokenHelpStyle style;

  @override
  Widget build(BuildContext context) {
    if (style == WhatsAppAccessTokenHelpStyle.konecta) {
      return TextButton.icon(
        onPressed: () => showWhatsAppAccessTokenHelp(context),
        icon: const Icon(Icons.help_outline, size: 16, color: KTokens.inkSoft),
        label: Text(
          compact ? '?' : 'CÓMO GENERARLO',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            letterSpacing: 0.6,
            color: KTokens.inkSoft,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.help_outline, size: 20),
      tooltip: 'Cómo generar el Access Token',
      onPressed: () => showWhatsAppAccessTokenHelp(context),
      visualDensity: VisualDensity.compact,
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
                'Generá un token de usuario del sistema en Meta Business Settings '
                '(token permanente recomendado para producción).',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(height: 1.45),
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
                    'Asignalo como Administrador si la app lo requiere.',
              ),
              const _HelpStep(
                n: 4,
                text:
                    'Seleccioná el usuario creado → Agregar activos → '
                    'asigná la app de Meta que usa WhatsApp con control total.',
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
