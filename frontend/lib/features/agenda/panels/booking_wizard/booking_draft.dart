import 'package:flutter/material.dart';

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

  bool isStepComplete(BookingStep s) => switch (s) {
        BookingStep.cliente => cliente != null,
        BookingStep.servicio => servicio != null,
        BookingStep.profesional => profesionalId != null || anyProfessional,
        BookingStep.fechaHora => date != null && time != null,
      };

  bool get isValid => BookingStep.values.every(isStepComplete);
}
