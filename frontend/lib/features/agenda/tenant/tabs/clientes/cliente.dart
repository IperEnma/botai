import 'package:flutter/material.dart';

enum ClienteTag { vip, fiel, nuevo }

extension ClienteTagLabel on ClienteTag {
  String get label => switch (this) {
        ClienteTag.vip => 'VIP',
        ClienteTag.fiel => 'FIEL',
        ClienteTag.nuevo => 'NUEVO',
      };
}

class ServicioUso {
  final String servicio;
  final int veces;
  const ServicioUso({required this.servicio, required this.veces});
}

class TurnoHist {
  final DateTime fecha;
  final String servicio;
  final String profesional;
  final double precio;
  const TurnoHist({
    required this.fecha,
    required this.servicio,
    required this.profesional,
    required this.precio,
  });
}

class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final DateTime clienteDesde;
  final int visitas;
  final int inasistencias;
  final double gastoAcumulado;
  final DateTime? ultimaVisita;
  final ClienteTag? tagOverride;
  final List<ServicioUso> servicios;
  final List<TurnoHist> historial;
  final String? notas;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.clienteDesde,
    required this.visitas,
    this.inasistencias = 0,
    required this.gastoAcumulado,
    this.ultimaVisita,
    this.tagOverride,
    this.servicios = const [],
    this.historial = const [],
    this.notas,
  });

  /// Servicio más usado por este cliente (mayor `veces`). `null` si no hay datos.
  ServicioUso? get servicioTop {
    if (servicios.isEmpty) return null;
    return servicios.reduce((a, b) => b.veces > a.veces ? b : a);
  }

  /// Iniciales para el avatar (hasta 2 letras).
  String get iniciales {
    final words = nombre.trim().split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return nombre.substring(0, nombre.length.clamp(1, 2)).toUpperCase();
  }
}

// ─── Derivación de tag (§6) ───────────────────────────────────────────────────

/// Calcula el tag del cliente según las reglas de §6.
///
/// - **VIP** si `visitas >= 15` o gasto en el top 10% del negocio.
/// - **NUEVO** si está dentro de los últimos 60 días o `visitas <= 2`.
/// - **FIEL** resto con `visitas >= 3`.
/// - Cualquier otro caso cae a NUEVO.
ClienteTag deriveTag(
  Cliente c, {
  required double vipThreshold,
  required DateTime now,
}) {
  if (c.tagOverride != null) return c.tagOverride!;
  if (c.visitas >= 15 || c.gastoAcumulado >= vipThreshold) {
    return ClienteTag.vip;
  }
  final daysSince = now.difference(c.clienteDesde).inDays;
  if (daysSince <= 60 || c.visitas <= 2) {
    return ClienteTag.nuevo;
  }
  if (c.visitas >= 3) return ClienteTag.fiel;
  return ClienteTag.nuevo;
}

// ─── KPIs del negocio ─────────────────────────────────────────────────────────

class ClientesKpis {
  final int total;
  final int nuevosEsteMes;
  /// % de clientes con `visitas >= 2`.
  final double recurrencia;
  /// `sum(visitas) / total` (0 si no hay clientes).
  final double visitasPromedio;

  const ClientesKpis({
    required this.total,
    required this.nuevosEsteMes,
    required this.recurrencia,
    required this.visitasPromedio,
  });

  static ClientesKpis from(List<Cliente> clientes, {required DateTime now}) {
    if (clientes.isEmpty) {
      return const ClientesKpis(
        total: 0,
        nuevosEsteMes: 0,
        recurrencia: 0,
        visitasPromedio: 0,
      );
    }
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final nuevos =
        clientes.where((c) => !c.clienteDesde.isBefore(firstOfMonth)).length;
    final recurrentes =
        clientes.where((c) => c.visitas >= 2).length / clientes.length;
    final avg =
        clientes.map((c) => c.visitas).fold<int>(0, (a, b) => a + b) /
            clientes.length;
    return ClientesKpis(
      total: clientes.length,
      nuevosEsteMes: nuevos,
      recurrencia: recurrentes,
      visitasPromedio: avg,
    );
  }
}

// ─── Avatares ─────────────────────────────────────────────────────────────────

const _avatarPalette = <Color>[
  Color(0xFF3B2F63),
  Color(0xFFC0392B),
  Color(0xFF16A085),
  Color(0xFF2F6FDB),
  Color(0xFFE8731A),
  Color(0xFF7C5CD6),
  Color(0xFF0A8C5B),
];

/// Color de avatar estable a partir del id (hash).
Color avatarColorFor(String id) {
  if (id.isEmpty) return _avatarPalette.first;
  final h = id.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7FFFFFFF);
  return _avatarPalette[h % _avatarPalette.length];
}

// ─── Helpers de fecha relativa ────────────────────────────────────────────────

String relativeDay(DateTime? when, DateTime now) {
  if (when == null) return '—';
  final diff = now.difference(when).inDays;
  if (diff <= 0) return 'hoy';
  if (diff == 1) return 'ayer';
  if (diff < 30) return 'hace $diff d';
  final months = (diff / 30).floor();
  if (months < 12) return 'hace $months m';
  final years = (months / 12).floor();
  return 'hace $years a';
}

const _mesesCortos = [
  'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
  'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC',
];

/// `MAY 27`.
String shortDate(DateTime d) =>
    '${_mesesCortos[d.month - 1]} ${d.day.toString().padLeft(2, '0')}';

/// `MAR 2023`.
String monthYear(DateTime d) => '${_mesesCortos[d.month - 1]} ${d.year}';
