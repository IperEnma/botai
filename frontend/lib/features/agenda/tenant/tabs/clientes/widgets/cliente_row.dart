import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../register/konecta_tokens.dart';
import '../cliente.dart';
import 'tag_chip.dart';

/// Grid widths (matches the column header in cliente_table.dart).
const _kColCliente = 2.2;
const _kColVisitas = 1.0;
const _kColServ = 1.4;
const _kColGasto = 1.0;
const _kColTag = 0.8;

class ClienteTableHeader extends StatelessWidget {
  const ClienteTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: (_kColCliente * 10).toInt(), child: const _Hdr('CLIENTE')),
          Expanded(flex: (_kColVisitas * 10).toInt(), child: const _Hdr('VISITAS')),
          Expanded(flex: (_kColServ * 10).toInt(), child: const _Hdr('SERVICIO TOP')),
          Expanded(flex: (_kColGasto * 10).toInt(), child: const _Hdr('GASTADO')),
          Expanded(flex: (_kColTag * 10).toInt(), child: const _Hdr('ÚLT.')),
        ],
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  const _Hdr(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        letterSpacing: 1.4,
        color: KTokens.inkSoft,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class ClienteRow extends StatelessWidget {
  const ClienteRow({
    super.key,
    required this.cliente,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final Cliente cliente;
  final ClienteTag tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final top = cliente.servicioTop?.servicio ?? '—';
    final visitas = cliente.visitas.toString();
    final gasto = '\$ ${_money(cliente.gastoAcumulado)}';

    return Semantics(
      button: true,
      label:
          '${cliente.nombre}, ${cliente.visitas} visitas, etiqueta ${tag.label}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: selected ? KTokens.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(KTokens.rMd),
              border: Border.all(
                color: selected
                    ? const Color(0x333B2F63)
                    : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: (_kColCliente * 10).toInt(),
                  child: _ClienteCell(cliente: cliente),
                ),
                Expanded(
                  flex: (_kColVisitas * 10).toInt(),
                  child: _Mono(visitas),
                ),
                Expanded(
                  flex: (_kColServ * 10).toInt(),
                  child: Text(
                    top,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: KTokens.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: (_kColGasto * 10).toInt(),
                  child: _Mono(gasto),
                ),
                Expanded(
                  flex: (_kColTag * 10).toInt(),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TagChip(tag: tag),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClienteCell extends StatelessWidget {
  const _ClienteCell({required this.cliente});

  final Cliente cliente;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClienteAvatar(cliente: cliente, size: 36),
        const SizedBox(width: 12),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                cliente.telefono,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  color: KTokens.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Mono extends StatelessWidget {
  const _Mono(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12.5,
          color: KTokens.ink,
        ),
      );
}

class ClienteAvatar extends StatelessWidget {
  const ClienteAvatar({
    super.key,
    required this.cliente,
    this.size = 36,
  });

  final Cliente cliente;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(cliente.id);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        cliente.iniciales,
        style: GoogleFonts.inter(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

String _money(double v) {
  // 54000 → 54.000  (separador de miles con punto, sin decimales).
  final whole = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final pos = whole.length - i;
    buf.write(whole[i]);
    if (pos > 1 && (pos - 1) % 3 == 0) buf.write('.');
  }
  return buf.toString();
}
