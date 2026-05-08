import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/agenda_user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/agenda/tenant_admin_resolved_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../register/konecta_tokens.dart';

/// Cuando [GET /me/tenant-admin] responde 404: la sesión de Google no está asociada aún a la
/// cuenta Agenda creada por **teléfono** (clave `{dígitos}@wa.konecta.app`, solo formato técnico).
/// No se mezcla teléfono con correo; la vinculación es explícita con el código de acceso.
class AgendaNoTenantAdminScreen extends ConsumerStatefulWidget {
  const AgendaNoTenantAdminScreen({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  ConsumerState<AgendaNoTenantAdminScreen> createState() =>
      _AgendaNoTenantAdminScreenState();
}

class _AgendaNoTenantAdminScreenState
    extends ConsumerState<AgendaNoTenantAdminScreen> {
  final _codeCtrl = TextEditingController();
  bool _linking = false;
  String? _linkError;
  bool _creating = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 8) {
      setState(() => _linkError = 'Ingresá el código de 8 caracteres.');
      return;
    }
    setState(() {
      _linking = true;
      _linkError = null;
    });
    try {
      await ref.read(agendaApiServiceProvider).linkTenantAdminWithAccessCode(code);
      if (!mounted) return;
      ref.invalidate(tenantAdminResolvedProvider);
    } on AgendaApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _linking = false;
        if (e.status == 404) {
          _linkError = 'Código no encontrado. Revisá mayúsculas y números.';
        } else if (e.status == 409) {
          _linkError = e.message;
        } else {
          _linkError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _linking = false;
        _linkError = e.toString();
      });
    }
  }

  Future<void> _createWithGoogle() async {
    if (_creating) return;
    setState(() {
      _creating = true;
      _linkError = null;
    });
    try {
      final auth = ref.read(authStateProvider);
      final user = auth.user;
      final email = user?.email.trim() ?? '';
      if (!auth.isAuthenticated || user == null || email.isEmpty) {
        setState(() => _linkError = 'No hay sesión de Google activa.');
        return;
      }
      final trimmedName = user.name?.trim();
      final nombre = (trimmedName != null && trimmedName.isNotEmpty)
          ? trimmedName
          : email.split('@').first;
      await ref.read(agendaUserProvider.notifier).saveGoogleRegistration(
            nombre: nombre,
            email: email,
          );
      if (!mounted) return;
      context.go('/agenda/intent');
    } catch (e) {
      if (!mounted) return;
      setState(() => _linkError = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720.0;

    return ColoredBox(
      color: KTokens.bg,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 24,
                vertical: 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'No encontramos tu negocio',
                    style: GoogleFonts.inter(
                      fontSize: wide ? 24 : 20,
                      fontWeight: FontWeight.w700,
                      color: KTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para continuar, creá tu negocio ahora.\n'
                    'Si ya tenías una cuenta, podés vincularla con tu código.',
                    style: KTokens.tHint,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _creating ? null : _createWithGoogle,
                    child: _creating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear mi negocio'),
                  ),
                  const SizedBox(height: 18),
                  Text('Ya tengo un código', style: KTokens.tEyebrow),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _codeCtrl,
                    maxLength: 16,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Código de acceso',
                      hintText: 'Ej. K7MN2PQX',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(KTokens.rMd),
                      ),
                    ),
                    onSubmitted: (_) => _linking ? null : _link(),
                  ),
                  if (_linkError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _linkError!,
                      style: KTokens.tHint.copyWith(color: KTokens.errorColor),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _linking ? null : _link,
                    child: _linking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Vincular con este código'),
                  ),
                  const SizedBox(height: 28),
                  Text('Otras opciones', style: KTokens.tEyebrow),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go('/agenda/register'),
                    child: const Text('Registrar un negocio nuevo'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.go('/home/bots'),
                    child: const Text('Ir a mis bots'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/agenda/search'),
                    child: const Text('Buscar en el catálogo público'),
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onRetry,
                      child: const Text('Reintentar carga'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
