import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/agenda_phone.dart';
import '../../../../widgets/agenda_phone_field.dart';
import '../../register/konecta_tokens.dart';
import '../../shared/k_button.dart';
import 'clientes/cliente.dart';
import 'clientes/clientes_controller.dart';
import 'clientes/ficha/ficha_panel.dart';
import 'clientes/widgets/cliente_table.dart';
import 'clientes/widgets/stat_strip.dart';

const _kFichaBreak = 1100.0;
const _kFichaWidth = 384.0;

class ClientesTab extends ConsumerWidget {
  const ClientesTab({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= _kFichaBreak;
    // Watch para reaccionar a cambios de selección/filtro sin volver a leer todo.
    ref.watch(clientesProvider(businessId));
    final notifier = ref.watch(clientesProvider(businessId).notifier);

    final directory = _DirectoryColumn(
      isWide: isWide,
      businessId: businessId,
      onOpenFicha: !isWide
          ? (c) => _openFichaSheet(context, ref, c)
          : null,
    );

    if (!isWide) {
      return Scaffold(
        backgroundColor: KTokens.bg,
        body: directory,
      );
    }

    final selected = notifier.selected;

    return Container(
      color: KTokens.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: directory),
          Container(
            width: _kFichaWidth,
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: KTokens.border)),
            ),
            child: selected == null
                ? const _EmptyFicha()
                : FichaPanel(
                    cliente: selected,
                    now: notifier.now,
                    onAgendar: () => _onAgendar(context, selected),
                    onWhatsapp: () => _onWhatsapp(context, selected),
                  ),
          ),
        ],
      ),
    );
  }

  void _openFichaSheet(BuildContext context, WidgetRef ref, Cliente cliente) {
    final notifier = ref.read(clientesProvider(businessId).notifier);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FichaScreen(
          cliente: cliente,
          now: notifier.now,
          onAgendar: () => _onAgendar(context, cliente),
          onWhatsapp: () => _onWhatsapp(context, cliente),
        ),
      ),
    );
  }

  void _onAgendar(BuildContext context, Cliente cliente) {
    // Hook al wizard de "Agendar un cliente" — pendiente de cablear.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Agendar para ${cliente.nombre} (pendiente)'),
    ));
  }

  void _onWhatsapp(BuildContext context, Cliente cliente) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Abrir WhatsApp con ${cliente.telefono} (pendiente)'),
    ));
  }
}

// ─── Directory column ────────────────────────────────────────────────────────

class _DirectoryColumn extends ConsumerWidget {
  const _DirectoryColumn({
    required this.isWide,
    required this.businessId,
    this.onOpenFicha,
  });

  final bool isWide;
  final String businessId;
  final ValueChanged<Cliente>? onOpenFicha;

  Future<void> _showNewClienteDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _NuevoClienteDialog(businessId: businessId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(clientesProvider(businessId).notifier);
    final state = ref.watch(clientesProvider(businessId));

    return Scrollbar(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isWide ? 40 : 20,
          36,
          isWide ? 40 : 20,
          40,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'BASE DE CLIENTES',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  color: KTokens.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text('Clientes', style: KTokens.tDisplay)),
                  KButton.primary(
                    label: 'Nuevo cliente',
                    icon: Icons.add_rounded,
                    compact: true,
                    onPressed: () => _showNewClienteDialog(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              StatStrip(kpis: notifier.kpis),
              const SizedBox(height: 20),

              _Toolbar(
                query: state.query,
                filter: state.filter,
                onQueryChange: notifier.setQuery,
                onFilterChange: notifier.setFilter,
              ),
              const SizedBox(height: 14),

              if (isWide)
                ClienteTable(businessId: businessId)
              else
                ClientesMobileList(
                  businessId: businessId,
                  onOpen: (c) => onOpenFicha?.call(c),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── New cliente dialog ──────────────────────────────────────────────────────

class _NuevoClienteDialog extends ConsumerStatefulWidget {
  const _NuevoClienteDialog({required this.businessId});

  final String businessId;

  @override
  ConsumerState<_NuevoClienteDialog> createState() => _NuevoClienteDialogState();
}

class _NuevoClienteDialogState extends ConsumerState<_NuevoClienteDialog> {
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(fontSize: 13, color: KTokens.inkPlaceholder),
        filled: true,
        fillColor: Colors.white,
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

  Future<void> _save() async {
    final nombre = _nombreCtrl.text.trim();
    final telefono = normalizeAgendaPhoneDigits(_telefonoCtrl.text);
    if (nombre.isEmpty || !isValidAgendaPhone(telefono)) {
      setState(() => _error = 'Nombre y teléfono (mín. 7 dígitos) son obligatorios.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final notifier = ref.read(clientesProvider(widget.businessId).notifier);
    final result = await notifier.create(
      nombre: nombre,
      telefono: telefono,
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cliente creado: ${result.nombre}',
            style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      setState(() {
        _saving = false;
        _error = ref.read(clientesProvider(widget.businessId)).error ??
            'No se pudo crear el cliente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Misma estructura que el `_NewClienteForm` del wizard de Agenda, pero
    // con fondo `KTokens.bg` (#FBFAF7) — el mismo cream/off-white de las
    // pantallas del panel — en lugar del `accentSoft` del wizard embebido.
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: KTokens.bg,
            borderRadius: BorderRadius.circular(KTokens.rMd),
            border: Border.all(color: KTokens.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NUEVO CLIENTE',
                style: KTokens.tEyebrow
                    .copyWith(fontSize: 10, letterSpacing: 1.4),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                style: GoogleFonts.inter(fontSize: 14, color: KTokens.ink),
                decoration: _inputDec('Nombre completo'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              AgendaPhoneField(controller: _telefonoCtrl, required: true),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: KTokens.excClosed),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  KButton.secondary(
                    label: 'Cancelar',
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  KButton.primary(
                    label: 'Guardar',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFicha extends StatelessWidget {
  const _EmptyFicha();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KTokens.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline_rounded,
              size: 36, color: KTokens.inkPlaceholder),
          const SizedBox(height: 12),
          Text(
            'Seleccioná un cliente',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: KTokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Toolbar (search + filter chips) ─────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.filter,
    required this.onQueryChange,
    required this.onFilterChange,
  });

  final String query;
  final ClientesFilter filter;
  final ValueChanged<String> onQueryChange;
  final ValueChanged<ClientesFilter> onFilterChange;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 720;
        final search = _SearchField(
          value: query,
          onChange: onQueryChange,
        );
        final chips = _FilterChips(
          current: filter,
          onChange: onFilterChange,
        );

        if (wide) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              chips,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            search,
            const SizedBox(height: 10),
            chips,
          ],
        );
      },
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.value, required this.onChange});

  final String value;
  final ValueChanged<String> onChange;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
      height: 38,
      decoration: BoxDecoration(
        color: KTokens.surface,
        border: Border.all(color: KTokens.border),
        borderRadius: BorderRadius.circular(KTokens.rSm),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 16, color: KTokens.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onChange,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o teléfono…',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: KTokens.inkPlaceholder,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: KTokens.ink,
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: KTokens.inkSoft),
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _ctrl.clear();
                widget.onChange('');
              },
            ),
        ],
      ),
    ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onChange});

  final ClientesFilter current;
  final ValueChanged<ClientesFilter> onChange;

  static const _items = [
    (ClientesFilter.todos, 'Todos'),
    (ClientesFilter.vip, 'VIP'),
    (ClientesFilter.fiel, 'Fieles'),
    (ClientesFilter.nuevo, 'Nuevos'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final item in _items)
          _Chip(
            label: item.$2,
            selected: current == item.$1,
            onTap: () => onChange(item.$1),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? KTokens.accent : KTokens.surface,
            borderRadius: BorderRadius.circular(KTokens.rPill),
            border: Border.all(
              color: selected ? KTokens.accent : KTokens.borderStrong,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : KTokens.ink,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Full-screen ficha (mobile) ───────────────────────────────────────────────

class _FichaScreen extends StatelessWidget {
  const _FichaScreen({
    required this.cliente,
    required this.now,
    required this.onAgendar,
    required this.onWhatsapp,
  });

  final Cliente cliente;
  final DateTime now;
  final VoidCallback onAgendar;
  final VoidCallback onWhatsapp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KTokens.surface,
      appBar: AppBar(
        backgroundColor: KTokens.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: KTokens.ink, size: 22),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Cerrar',
        ),
        title: Text(
          cliente.nombre,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: KTokens.ink,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: KTokens.border),
        ),
      ),
      body: FichaPanel(
        cliente: cliente,
        now: now,
        compact: true,
        onAgendar: () {
          Navigator.of(context).pop();
          onAgendar();
        },
        onWhatsapp: () {
          Navigator.of(context).pop();
          onWhatsapp();
        },
      ),
    );
  }
}
