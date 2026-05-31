import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sucursal activa del admin Agenda (no va en la URL; el tenant viene del login).
final selectedAgendaBusinessIdProvider = StateProvider<String?>((ref) => null);
