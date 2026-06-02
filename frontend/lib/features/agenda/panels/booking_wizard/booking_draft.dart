import 'package:flutter/material.dart';

import '../../../../core/agenda_phone.dart';
import '../../../../models/agenda/agenda_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums & value types
// ─────────────────────────────────────────────────────────────────────────────

enum BookingStep { cliente, servicio, profesional, fechaHora }

class BookingCliente {
  final String id;
  final String nombre;
  final String? telefono;
  final int visitCount;
  final bool isFiel;
  final bool isVip;

  const BookingCliente({
    required this.id,
    required this.nombre,
    this.telefono,
    required this.visitCount,
    required this.isFiel,
    required this.isVip,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Draft
// ─────────────────────────────────────────────────────────────────────────────

class BookingDraft {
  BookingCliente? cliente;
  AgendaService? servicio;
  String? profesionalId;
  bool anyProfessional;
  DateTime? date;
  TimeOfDay? time;
  String notes;
  bool sendWhatsApp;

  BookingDraft({
    this.cliente,
    this.servicio,
    this.profesionalId,
    this.anyProfessional = false,
    this.date,
    this.time,
    this.notes = '',
    this.sendWhatsApp = true,
  });

  /// Según configuración del servicio (`GENERAL` vs `BY_STAFF`).
  bool get requiresStaffStep => servicio?.requiresStaffSelection ?? false;

  List<BookingStep> get activeSteps => [
        BookingStep.cliente,
        BookingStep.servicio,
        if (requiresStaffStep) BookingStep.profesional,
        BookingStep.fechaHora,
      ];

  static bool clienteTieneTelefonoValido(BookingCliente? c) =>
      c != null && isValidAgendaPhone(c.telefono);

  bool isStepComplete(BookingStep s) => switch (s) {
        BookingStep.cliente => clienteTieneTelefonoValido(cliente),
        BookingStep.servicio => servicio != null,
        BookingStep.profesional => !requiresStaffStep ||
            profesionalId != null ||
            anyProfessional,
        BookingStep.fechaHora => date != null && time != null,
      };

  bool get isValid => activeSteps.every(isStepComplete);

  /// `null` = sin profesional (agenda general o “cualquiera”).
  String? get effectiveStaffMemberId {
    if (!requiresStaffStep || anyProfessional) return null;
    return profesionalId;
  }
}
