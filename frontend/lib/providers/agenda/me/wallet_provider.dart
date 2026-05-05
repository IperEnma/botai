import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/agenda/wallet.dart';
import '../../../services/agenda_api_exception.dart';
import '../agenda_api_provider.dart';

class WalletState {
  final Wallet? wallet;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.wallet,
    this.isLoading = false,
    this.error,
  });

  WalletState copyWith({
    Wallet? wallet,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier(this._ref, this._subscriptionId)
      : super(const WalletState(isLoading: true)) {
    load();
  }

  final Ref _ref;
  final String _subscriptionId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = _ref.read(agendaApiServiceProvider);
      final wallet = await api.myWallet(_subscriptionId);
      state = WalletState(wallet: wallet);
    } on AgendaApiException catch (e) {
      state = WalletState(error: e.message);
    }
  }
}

final walletProvider = StateNotifierProvider.autoDispose
    .family<WalletNotifier, WalletState, String>((ref, subscriptionId) {
  return WalletNotifier(ref, subscriptionId);
});
