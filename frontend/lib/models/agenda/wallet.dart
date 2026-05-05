import 'agenda_json.dart';

class CreditTransaction {
  final String id;
  final String subscriptionId;
  final int monto;
  final String motivo;
  final DateTime createdAt;

  const CreditTransaction({
    required this.id,
    required this.subscriptionId,
    required this.monto,
    required this.motivo,
    required this.createdAt,
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: AgendaJson.parseString(json['id']),
      subscriptionId: AgendaJson.parseString(json['subscriptionId']),
      monto: AgendaJson.parseInt(json['monto']),
      motivo: AgendaJson.parseString(json['motivo']),
      createdAt: AgendaJson.parseDateTime(json['createdAt']),
    );
  }

  bool get isCredit => monto > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditTransaction && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

class Wallet {
  final String subscriptionId;
  final int saldoActual;
  final DateTime? fechaExpiracion;
  final List<CreditTransaction> movimientos;

  const Wallet({
    required this.subscriptionId,
    required this.saldoActual,
    this.fechaExpiracion,
    this.movimientos = const [],
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final rawMovs = json['movimientos'];
    final movimientos = rawMovs is List
        ? rawMovs
            .whereType<Map>()
            .map((e) =>
                CreditTransaction.fromJson(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <CreditTransaction>[];

    return Wallet(
      subscriptionId: AgendaJson.parseString(json['subscriptionId']),
      saldoActual: AgendaJson.parseInt(json['saldoActual']),
      fechaExpiracion: AgendaJson.parseDateTimeOrNull(json['fechaExpiracion']),
      movimientos: movimientos,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Wallet && other.subscriptionId == subscriptionId);

  @override
  int get hashCode => subscriptionId.hashCode;
}
