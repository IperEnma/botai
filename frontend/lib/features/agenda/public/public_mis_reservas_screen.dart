import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/agenda_phone.dart';
import '../../../models/agenda/booking.dart';
import '../../../models/agenda/business.dart';
import '../../../providers/agenda/agenda_api_provider.dart';
import '../../../providers/agenda/public/public_business_slug_provider.dart';
import '../../../providers/agenda/public/public_client_session_provider.dart';
import '../../../services/agenda_api_exception.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../../../widgets/agenda_phone_field.dart';
import 'public_felito_shell.dart';
import 'public_reservar_layout.dart';

enum _MisReservasStep { gate, verifyCode, bookings }

/// Mis reservas públicas: /reservar/:slug/mis-reservas (OTP + sesión reutilizable).
class PublicMisReservasScreen extends ConsumerStatefulWidget {
  const PublicMisReservasScreen({
    super.key,
    required this.slug,
    this.companySlug,
  });

  final String slug;
  final String? companySlug;

  @override
  ConsumerState<PublicMisReservasScreen> createState() =>
      _PublicMisReservasScreenState();
}

class _PublicMisReservasScreenState extends ConsumerState<PublicMisReservasScreen> {
  _MisReservasStep _step = _MisReservasStep.gate;
  List<Booking> _bookings = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _otpHint;
  String? _sessionToken;
  final Set<String> _ratedBookingIds = <String>{};

  final _telCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _telCtrl.dispose();
    _codeCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  String _profilePath() {
    final base = '/reservar/${widget.slug}';
    final company = widget.companySlug;
    if (company != null && company.isNotEmpty) {
      return '$base?company=$company';
    }
    return base;
  }

  String _bookingPath() {
    final base = '/reservar/${widget.slug}/reservar';
    final company = widget.companySlug;
    if (company != null && company.isNotEmpty) {
      return '$base?company=$company';
    }
    return base;
  }

  Future<void> _bootstrap() async {
    final business = await ref.read(publicBusinessBySlugProvider(widget.slug).future);
    final storage = ref.read(publicClientSessionStorageProvider);
    final stored = await storage.load(widget.slug);
    if (!mounted) return;

    StoredPublicClientSession? session = stored;
    if (session != null && session.businessId != business.id) {
      await storage.clear(widget.slug);
      session = null;
    }

    if (session != null) {
      _telCtrl.text = session.phone;
      if (session.nombre != null) _nombreCtrl.text = session.nombre!;
      _sessionToken = session.token;
      await _loadBookings(business, session);
      return;
    }

    setState(() {
      _loading = false;
      _step = _MisReservasStep.gate;
    });
  }

  Future<void> _loadBookings(Business business, StoredPublicClientSession session) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final list = await api.listPublicClientBookings(
        sessionToken: session.token,
        businessId: business.id,
      );
      if (!mounted) return;
      setState(() {
        _bookings = list;
        _step = _MisReservasStep.bookings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      await ref.read(publicClientSessionStorageProvider).clear(widget.slug);
      setState(() {
        _bookings = const [];
        _step = _MisReservasStep.gate;
        _loading = false;
        _error = 'Tu sesión expiró. Verificá tu teléfono de nuevo.';
      });
    }
  }

  Future<void> _sendOtp(Business business, PublicReservarTheme theme) async {
    if (!_formKey.currentState!.validate()) return;
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    if (!isValidAgendaPhone(telefono)) {
      _showError(theme, 'Ingresá un teléfono válido con código de país.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final result = await api.sendPublicPhoneVerification(
        businessId: business.id,
        telefono: telefono,
      );
      if (!mounted) return;
      setState(() {
        _otpHint = result.message;
        _step = _MisReservasStep.verifyCode;
      });
    } catch (e) {
      if (!mounted) return;
      _showError(theme, 'No se pudo enviar el código: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verify(Business business, PublicReservarTheme theme) async {
    final telefono = normalizeAgendaPhoneDigits(_telCtrl.text);
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresá el código de WhatsApp.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = ref.read(agendaApiServiceProvider);
      final result = await api.verifyPublicPhoneCode(
        businessId: business.id,
        telefono: telefono,
        code: code,
      );
      final session = StoredPublicClientSession.fresh(
        token: result.clientSessionToken,
        businessId: business.id,
        phone: telefono,
        needsName: result.client.needsName,
        nombre: result.client.needsName ? null : result.client.nombre,
      );
      await ref.read(publicClientSessionStorageProvider).save(widget.slug, session);
      ref.invalidate(publicClientSessionProvider(widget.slug));
      if (!mounted) return;
      setState(() {
        _sessionToken = session.token;
        _bookings = result.bookings;
        _step = _MisReservasStep.bookings;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Código inválido o expirado.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(PublicReservarTheme theme, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: theme.textStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _openRating(
    Business business,
    PublicReservarTheme theme,
    Booking booking,
  ) async {
    final token = _sessionToken;
    if (token == null || token.isEmpty) {
      _showError(theme, 'Tu sesión expiró. Verificá tu teléfono de nuevo.');
      return;
    }

    final result = await showModalBottomSheet<_RatingResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RatingSheet(theme: theme, serviceName: booking.servicioNombre),
    );
    if (result == null || !mounted) return;

    try {
      final api = ref.read(agendaApiServiceProvider);
      await api.publicCreateReview(
        businessId: business.id,
        bookingId: booking.id,
        rating: result.rating,
        comentario: result.comentario,
        clientSessionToken: token,
      );
      if (!mounted) return;
      setState(() => _ratedBookingIds.add(booking.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Gracias por tu calificación!',
            style: theme.textStyle(color: Colors.white),
          ),
          backgroundColor: theme.primary,
        ),
      );
    } on AgendaApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        // Ya existe reseña para este booking: marcar como calificado, sin reintentar.
        setState(() => _ratedBookingIds.add(booking.id));
        _showError(theme, 'Ya calificaste este turno.');
      } else if (e.status == 403) {
        _showError(theme, 'No podés calificar este turno.');
      } else if (e.isUnprocessable) {
        _showError(theme, e.message);
      } else {
        _showError(theme, 'No se pudo enviar la calificación: ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      _showError(theme, 'No se pudo enviar la calificación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessAsync = ref.watch(publicBusinessBySlugProvider(widget.slug));

    return businessAsync.when(
      loading: () => const Scaffold(body: AgendaLoadingView()),
      error: (e, _) => Scaffold(
        body: AgendaErrorView(
          message: 'No se pudo cargar el negocio: $e',
          onRetry: () => ref.refresh(publicBusinessBySlugProvider(widget.slug)),
        ),
      ),
      data: (business) {
        final theme = PublicReservarTheme.fromHex(
          colorPrimario: business.colorPrimario,
          colorFondo: business.colorFondo,
          colorTarjeta: business.colorTarjeta,
          fontFamily: business.fontFamily,
          logoUrl: business.logoUrl,
        );

        if (_loading) {
          return PublicFelitoBookingShell(
            businessName: business.nombre,
            progressCurrent: 1,
            progressTotal: 2,
            progressStepLabel: 'Mis reservas',
            onBack: () => context.go(_profilePath()),
            child: const Center(
              child: CircularProgressIndicator(color: FelitoPublicD.purple),
            ),
          );
        }

        return PublicFelitoBookingShell(
          businessName: business.nombre,
          progressCurrent: _step == _MisReservasStep.bookings ? 2 : 1,
          progressTotal: 2,
          progressStepLabel: 'Mis reservas',
          onBack: () {
            if (_step == _MisReservasStep.verifyCode) {
              setState(() => _step = _MisReservasStep.gate);
            } else {
              context.go(_profilePath());
            }
          },
          footer: felitoFooterLink(
            label: 'Reservar un turno',
            onTap: () => context.go(_bookingPath()),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _buildBody(business, theme),
          ),
        );
      },
    );
  }

  Widget _buildBody(Business business, PublicReservarTheme theme) {
    switch (_step) {
      case _MisReservasStep.gate:
        return _GateStep(
          theme: theme,
          formKey: _formKey,
          telCtrl: _telCtrl,
          error: _error,
          submitting: _submitting,
          onSend: () => _sendOtp(business, theme),
        );
      case _MisReservasStep.verifyCode:
        return _VerifyStep(
          theme: theme,
          codeCtrl: _codeCtrl,
          phone: normalizeAgendaPhoneDigits(_telCtrl.text),
          hint: _otpHint,
          error: _error,
          submitting: _submitting,
          onVerify: () => _verify(business, theme),
        );
      case _MisReservasStep.bookings:
        return _BookingsList(
          theme: theme,
          bookings: _bookings,
          ratedBookingIds: _ratedBookingIds,
          onRate: (booking) => _openRating(business, theme, booking),
        );
    }
  }
}

class _GateStep extends StatelessWidget {
  const _GateStep({
    required this.theme,
    required this.formKey,
    required this.telCtrl,
    required this.error,
    required this.submitting,
    required this.onSend,
  });

  final PublicReservarTheme theme;
  final GlobalKey<FormState> formKey;
  final TextEditingController telCtrl;
  final String? error;
  final bool submitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          publicReservarScrollSectionTitle(
            theme: t,
            title: 'Mis reservas',
            subtitle:
                'Ingresá el mismo teléfono que usaste al reservar. Te enviamos un código por WhatsApp.',
          ),
          AgendaPhoneField(
            controller: telCtrl,
            required: true,
            useKonectaTokens: false,
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: t.textStyle(color: Colors.red.shade700, size: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: submitting ? null : onSend,
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Enviar código', style: t.textStyle(color: Colors.white, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyStep extends StatelessWidget {
  const _VerifyStep({
    required this.theme,
    required this.codeCtrl,
    required this.phone,
    required this.hint,
    required this.error,
    required this.submitting,
    required this.onVerify,
  });

  final PublicReservarTheme theme;
  final TextEditingController codeCtrl;
  final String phone;
  final String? hint;
  final String? error;
  final bool submitting;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        publicReservarScrollSectionTitle(
          theme: t,
          title: 'Código de WhatsApp',
          subtitle: 'Enviamos un código al $phone.',
        ),
        if (hint != null && hint!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(hint!, style: t.textStyle(color: t.textSub, size: 13)),
          ),
        TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'Código de 6 dígitos',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: t.textStyle(color: Colors.red.shade700, size: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: t.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: submitting ? null : onVerify,
            child: submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Ver mis reservas', style: t.textStyle(color: Colors.white, weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.theme,
    required this.bookings,
    required this.ratedBookingIds,
    required this.onRate,
  });

  final PublicReservarTheme theme;
  final List<Booking> bookings;
  final Set<String> ratedBookingIds;
  final ValueChanged<Booking> onRate;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    if (bookings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          publicReservarScrollSectionTitle(
            theme: t,
            title: 'Sin reservas próximas',
            subtitle: 'Cuando reserves un turno, lo verás acá.',
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Reservar un turno'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        publicReservarScrollSectionTitle(
          theme: t,
          title: 'Tus reservas',
          subtitle: 'Tus turnos en este negocio.',
        ),
        const SizedBox(height: 8),
        for (final b in bookings) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.cardFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.servicioNombre,
                  style: t.textStyle(size: 16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatWhen(b.fechaHoraInicio),
                  style: t.textStyle(color: t.textSub, size: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  b.estado.label,
                  style: t.textStyle(
                    color: t.primary,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
                if (b.estado == BookingEstado.completada) ...[
                  const SizedBox(height: 12),
                  if (ratedBookingIds.contains(b.id))
                    Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 18, color: t.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Calificación enviada',
                          style: t.textStyle(
                            size: 13,
                            weight: FontWeight.w600,
                            color: t.primary,
                          ),
                        ),
                      ],
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.primary,
                          side: BorderSide(color: t.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => onRate(b),
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: Text(
                          'Calificar',
                          style: t.textStyle(
                            size: 13,
                            weight: FontWeight.w600,
                            color: t.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _formatWhen(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} · $h:$m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rating sheet (estrellas 1..5 + comentario opcional)
// ─────────────────────────────────────────────────────────────────────────────

class _RatingResult {
  const _RatingResult({required this.rating, this.comentario});
  final int rating;
  final String? comentario;
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.theme, required this.serviceName});

  final PublicReservarTheme theme;
  final String serviceName;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _rating = 0;
  final _comentarioCtrl = TextEditingController();

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Calificá tu turno',
            style: t.textStyle(size: 20, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            widget.serviceName,
            style: t.textStyle(size: 14, color: t.textSub),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final pos = i + 1;
              final filled = _rating >= pos;
              return IconButton(
                onPressed: () => setState(() => _rating = pos),
                iconSize: 40,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                constraints: const BoxConstraints(),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? t.primary : t.primary.withValues(alpha: 0.35),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            maxLength: 500,
            style: t.textStyle(size: 14),
            decoration: InputDecoration(
              hintText: 'Contanos cómo te fue (opcional)',
              hintStyle: t.textStyle(size: 14, color: t.textSub),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                disabledBackgroundColor: t.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _rating == 0
                  ? null
                  : () {
                      final comentario = _comentarioCtrl.text.trim();
                      Navigator.of(context).pop(
                        _RatingResult(
                          rating: _rating,
                          comentario: comentario.isEmpty ? null : comentario,
                        ),
                      );
                    },
              child: Text(
                'Enviar calificación',
                style: t.textStyle(
                  size: 15,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
