import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/agenda/register_tenant.dart';
import '../../services/agenda_api_exception.dart';
import 'agenda_api_provider.dart';

enum RegisterStatus { idle, loading, success, error }

class RegisterState {
  final RegisterStatus status;
  final RegisterTenantResponse? result;
  final String? error;

  const RegisterState({
    this.status = RegisterStatus.idle,
    this.result,
    this.error,
  });

  bool get isLoading => status == RegisterStatus.loading;
  bool get isSuccess => status == RegisterStatus.success;

  RegisterState copyWith({
    RegisterStatus? status,
    RegisterTenantResponse? result,
    String? error,
  }) {
    return RegisterState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error,
    );
  }
}

class RegisterNotifier extends StateNotifier<RegisterState> {
  RegisterNotifier(this._ref) : super(const RegisterState());

  final Ref _ref;

  Future<RegisterTenantResponse?> register({
    required String nombrePropietario,
    required String email,
    String? telefono,
    required String nombreNegocio,
    String? categoriaSlug,
  }) async {
    state = state.copyWith(status: RegisterStatus.loading, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final result = await api.registerTenant(
        nombrePropietario: nombrePropietario,
        email: email,
        telefono: telefono,
        nombreNegocio: nombreNegocio,
        categoriaSlug: categoriaSlug,
      );
      state = RegisterState(status: RegisterStatus.success, result: result);
      return result;
    } on AgendaApiException catch (e) {
      final msg = e.status == 409
          ? 'Ese correo ya tiene una cuenta registrada.'
          : e.message;
      state = RegisterState(status: RegisterStatus.error, error: msg);
      return null;
    } catch (e) {
      state = RegisterState(
          status: RegisterStatus.error, error: 'Error inesperado: $e');
      return null;
    }
  }

  void reset() => state = const RegisterState();
}

final registerProvider =
    StateNotifierProvider.autoDispose<RegisterNotifier, RegisterState>((ref) {
  return RegisterNotifier(ref);
});
