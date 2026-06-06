import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/agenda_phone.dart';
import '../../../../../features/agenda/register/konecta_tokens.dart';
import '../../../../../features/agenda/tenant/tabs/clientes/clientes_controller.dart';
import '../../../../../widgets/agenda_phone_field.dart';
import '../../../../../models/agenda/public_client.dart';
import '../../../../../providers/agenda/agenda_api_provider.dart';
import '../booking_draft.dart';
import '../booking_wizard_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step widget
// ─────────────────────────────────────────────────────────────────────────────

class StepCliente extends ConsumerStatefulWidget {
  const StepCliente({
    super.key,
    required this.controller,
    required this.businessId,
  });

  final BookingWizardController controller;
  final String businessId;

  @override
  ConsumerState<StepCliente> createState() => _StepClienteState();
}

class _StepClienteState extends ConsumerState<StepCliente> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  BookingCliente? _selected;

  // Clients loaded from backend — persists across app sessions
  List<BookingCliente> _allClientes = [];
  bool _loading = true;

  bool _showNewForm = false;
  final _newNombreCtrl = TextEditingController();
  final _newTelefonoCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.controller.draft.cliente;
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final api = ref.read(agendaApiServiceProvider);
      final results = await api.tenantSearchClients(
        businessId: widget.businessId,
        q: '',
      );
      if (mounted) {
        setState(() {
          _allClientes = results.map(_fromPublic).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  BookingCliente _fromPublic(PublicClient c) => BookingCliente(
        id: c.id,
        nombre: c.nombre,
        telefono: c.telefono,
        visitCount: 0,
        isFiel: false,
        isVip: false,
      );

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newNombreCtrl.dispose();
    _newTelefonoCtrl.dispose();
    super.dispose();
  }

  void _select(BookingCliente c) {
    if (!isValidAgendaPhone(c.telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Este cliente no tiene teléfono. Creá uno nuevo o actualizalo con un número válido.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _selected = c;
      _showNewForm = false;
    });
    widget.controller.setCliente(c);
  }

  Future<void> _saveNewClient() async {
    final nombre = _newNombreCtrl.text.trim();
    final telefono = normalizeAgendaPhoneDigits(_newTelefonoCtrl.text);
    if (nombre.isEmpty || !isValidAgendaPhone(telefono)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre y teléfono (mín. 7 dígitos) son obligatorios.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(agendaApiServiceProvider);
      final created = await api.tenantCreateClient(
        businessId: widget.businessId,
        nombre: nombre,
        telefono: telefono,
      );
      if (!mounted) return;
      final newClient = _fromPublic(created);
      setState(() {
        _allClientes = [newClient, ..._allClientes];
        _selected = newClient;
        _showNewForm = false;
        _query = '';
        _searchCtrl.clear();
        _newNombreCtrl.clear();
        _newTelefonoCtrl.clear();
        _saving = false;
      });
      // Refresca la sección Clientes para que el nuevo cliente aparezca con
      // sus stats (visitas/última visita/gasto) al volver a esa pestaña.
      ref.invalidate(clientesProvider(widget.businessId));
      widget.controller.setCliente(newClient);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _initials(String nombre) {
    final parts = nombre.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.trim().isEmpty
        ? _allClientes
        : () {
            final q = _query.toLowerCase();
            return _allClientes
                .where((c) =>
                    c.nombre.toLowerCase().contains(q) ||
                    (c.telefono?.toLowerCase().contains(q) ?? false))
                .toList();
          }();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Para quién es?',
            style: KTokens.tHero,
          ),
          const SizedBox(height: 6),
          Text(
            'Buscá un cliente existente o creá uno nuevo.',
            style: GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted),
          ),
          const SizedBox(height: 18),
          Text(
            'CLIENTE',
            style: KTokens.tEyebrow.copyWith(fontSize: 10, letterSpacing: 1.4),
          ),
          const SizedBox(height: 8),
          // Search
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
            onChanged: (v) => setState(() {
              _query = v;
              _showNewForm = false;
            }),
            decoration: InputDecoration(
              prefixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search, size: 18, color: KTokens.inkSoft),
              hintText: 'Buscar cliente por nombre o teléfono…',
              hintStyle:
                  GoogleFonts.inter(fontSize: 13, color: KTokens.inkPlaceholder),
              filled: true,
              fillColor: KTokens.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KTokens.rMd),
                borderSide: BorderSide(color: KTokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KTokens.rMd),
                borderSide: BorderSide(color: KTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KTokens.rMd),
                borderSide: const BorderSide(color: KTokens.accent, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
          const SizedBox(height: 8),
          // Results list
          if (filtered.isNotEmpty || _query.trim().isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(KTokens.rMd),
                border: Border.all(color: KTokens.border),
              ),
              child: Column(
                children: [
                  ...filtered.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final c = entry.value;
                    final isSelected = _selected?.id == c.id;
                    final isLast = idx == filtered.length - 1 &&
                        _query.trim().isEmpty;
                    return _ClienteRow(
                      cliente: c,
                      idx: idx,
                      isSelected: isSelected,
                      showDivider: !isLast,
                      initials: _initials(c.nombre),
                      onTap: () => _select(c),
                    );
                  }),
                  if (_query.trim().isNotEmpty) ...[
                    if (filtered.isNotEmpty)
                      Divider(height: 1, color: KTokens.border),
                    _CreateClienteRow(
                      query: _query,
                      onTap: () => setState(() => _showNewForm = true),
                    ),
                  ],
                ],
              ),
            ),
          // Inline new client form
          if (_showNewForm) ...[
            const SizedBox(height: 12),
            _NewClienteForm(
              nombreCtrl: _newNombreCtrl,
              telefonoCtrl: _newTelefonoCtrl,
              saving: _saving,
              onSave: _saveNewClient,
              onCancel: () => setState(() => _showNewForm = false),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Client row
// ─────────────────────────────────────────────────────────────────────────────

class _ClienteRow extends StatelessWidget {
  const _ClienteRow({
    required this.cliente,
    required this.idx,
    required this.isSelected,
    required this.showDivider,
    required this.initials,
    required this.onTap,
  });

  final BookingCliente cliente;
  final int idx;
  final bool isSelected;
  final bool showDivider;
  final String initials;
  final VoidCallback onTap;

  Color _colorFor(int i) => KTokens.proPalette[i % KTokens.proPalette.length];

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(idx);
    return Column(
      children: [
        InkWell(
          onTap: isValidAgendaPhone(cliente.telefono) ? onTap : null,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? KTokens.accentSoft : Colors.transparent,
              border: isSelected
                  ? Border.all(color: KTokens.accent, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(KTokens.rMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.25),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: KTokens.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: KTokens.ink,
                        ),
                      ),
                      Text(
                        isValidAgendaPhone(cliente.telefono)
                            ? '${cliente.telefono} · ${cliente.visitCount} visitas'
                            : 'Sin teléfono — no se puede usar para reservar',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: isValidAgendaPhone(cliente.telefono)
                              ? KTokens.inkSoft
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cliente.isFiel) ...[
                      _Badge('FIEL'),
                      const SizedBox(width: 4),
                    ],
                    if (cliente.isVip) _Badge('VIP'),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: KTokens.border),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: KTokens.accentSoft,
        borderRadius: BorderRadius.circular(KTokens.rPill),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: KTokens.accent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create-client row
// ─────────────────────────────────────────────────────────────────────────────

class _CreateClienteRow extends StatelessWidget {
  const _CreateClienteRow({required this.query, required this.onTap});
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KTokens.rMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: KTokens.accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(KTokens.rMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.add, size: 16, color: KTokens.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Crear cliente nuevo "$query"',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: KTokens.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New-client form
// ─────────────────────────────────────────────────────────────────────────────

class _NewClienteForm extends StatelessWidget {
  const _NewClienteForm({
    required this.nombreCtrl,
    required this.telefonoCtrl,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController nombreCtrl;
  final TextEditingController telefonoCtrl;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: KTokens.inkPlaceholder),
        filled: true,
        fillColor: KTokens.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: BorderSide(color: KTokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: BorderSide(color: KTokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KTokens.rMd),
          borderSide: const BorderSide(color: KTokens.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KTokens.accentSoft,
        borderRadius: BorderRadius.circular(KTokens.rMd),
        border: Border.all(color: KTokens.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NUEVO CLIENTE',
            style: KTokens.tEyebrow.copyWith(fontSize: 10, letterSpacing: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nombreCtrl,
            style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
            decoration: _inputDec('Nombre completo'),
          ),
          const SizedBox(height: 8),
          AgendaPhoneField(controller: telefonoCtrl, required: true),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton(
                onPressed: saving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  side: BorderSide(color: KTokens.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KTokens.rMd),
                  ),
                ),
                child: Text('Cancelar',
                    style:
                        GoogleFonts.inter(fontSize: 13, color: KTokens.inkMuted)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KTokens.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KTokens.rMd),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Guardar',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
