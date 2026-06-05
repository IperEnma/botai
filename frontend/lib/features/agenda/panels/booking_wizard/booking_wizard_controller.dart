import 'package:flutter/material.dart';

import '../../../../models/agenda/agenda_service.dart';
import '../../../../services/agenda_api_exception.dart';
import '../../../../services/agenda_api_service.dart';
import 'booking_draft.dart';

class BookingWizardController extends ChangeNotifier {
  BookingWizardController({
    required this.businessId,
    DateTime? initialDate,
    String? initialProId,
  })  : draft = BookingDraft(
          date: initialDate,
          time: initialDate != null
              ? TimeOfDay(hour: initialDate.hour, minute: initialDate.minute)
              : null,
          profesionalId: initialProId,
          anyProfessional: false,
        ),
        step = BookingStep.cliente;

  final String businessId;
  BookingStep step;
  final BookingDraft draft;
  bool isSubmitting = false;
  String? conflictError;

  bool get canAdvance => draft.isStepComplete(step);
  bool get isLastStep => step == BookingStep.fechaHora;

  void next() {
    if (!canAdvance) return;
    final steps = draft.activeSteps;
    final idx = steps.indexOf(step);
    if (idx >= 0 && idx < steps.length - 1) {
      step = steps[idx + 1];
      notifyListeners();
    }
  }

  void back() {
    final steps = draft.activeSteps;
    final idx = steps.indexOf(step);
    if (idx > 0) {
      step = steps[idx - 1];
      notifyListeners();
    }
  }

  void goTo(BookingStep s) {
    final steps = draft.activeSteps;
    if (!steps.contains(s)) return;
    final targetIdx = steps.indexOf(s);
    for (var i = 0; i < targetIdx; i++) {
      if (!draft.isStepComplete(steps[i])) return;
    }
    step = s;
    notifyListeners();
  }

  void setCliente(BookingCliente c) {
    draft.cliente = c;
    notifyListeners();
  }

  void setServicio(AgendaService s) {
    draft.servicio = s;
    draft.profesionalId = null;
    draft.anyProfessional = !s.requiresStaffSelection;
    draft.date = null;
    draft.time = null;
    if (step == BookingStep.profesional && !draft.requiresStaffStep) {
      step = BookingStep.servicio;
    }
    notifyListeners();
  }

  void setProfesional(String? id, {bool any = false}) {
    draft.profesionalId = id;
    draft.anyProfessional = any;
    draft.date = null;
    draft.time = null;
    notifyListeners();
  }

  void setDate(DateTime date) {
    draft.date = date;
    draft.time = null;
    notifyListeners();
  }

  void setDateTime(DateTime date, TimeOfDay time) {
    draft.date = date;
    draft.time = time;
    notifyListeners();
  }

  void setNotes(String notes) {
    draft.notes = notes;
    notifyListeners();
  }

  void setSendWhatsApp(bool value) {
    draft.sendWhatsApp = value;
    notifyListeners();
  }

  Future<void> confirm(
    AgendaApiService api,
    VoidCallback onSuccess,
    void Function(String) onError,
  ) async {
    if (!draft.isValid) return;
    if (!BookingDraft.clienteTieneTelefonoValido(draft.cliente)) {
      onError('El cliente debe tener un teléfono válido (mínimo 7 dígitos) para reservar.');
      return;
    }
    isSubmitting = true;
    conflictError = null;
    notifyListeners();

    try {
      final d = draft;
      final date = d.date!;
      final time = d.time!;
      final fechaHora = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      await api.tenantCreatePendingBooking(
        businessId: businessId,
        clientId: d.cliente!.id,
        serviceId: d.servicio!.id,
        staffMemberId: d.effectiveStaffMemberId,
        fechaHoraInicio: fechaHora,
        notas: d.notes.isEmpty ? null : d.notes,
      );

      isSubmitting = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      isSubmitting = false;
      conflictError = null;
      notifyListeners();
      onError(_friendlyError(e));
    }
  }
}

String _friendlyError(Object e) {
  if (e is AgendaApiException) {
    switch (e.code) {
      case 'BOOKING_SLOT_TAKEN':
        return 'Este horario ya no está disponible. Por favor elegí otro.';
      case 'SERVICE_NOT_FOUND':
        return 'El servicio seleccionado no está disponible.';
      case 'BUSINESS_NOT_FOUND':
        return 'El negocio no fue encontrado.';
      case 'VALIDATION_ERROR':
        if (e.detail != null && e.detail!.contains('fechaHoraInicio')) {
          return 'Este horario ya pasó. Por favor elegí otro.';
        }
        return 'Revisá los datos del turno e intentá de nuevo.';
      default:
        return 'Ocurrió un error al agendar. Por favor intentá de nuevo.';
    }
  }
  return 'Ocurrió un error al agendar. Por favor intentá de nuevo.';
}
