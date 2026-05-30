import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bot.dart';
import '../models/whatsapp_webhook_setup.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final botsProvider = StateNotifierProvider<BotsNotifier, BotsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BotsNotifier(apiService);
});

final selectedBotProvider = StateProvider<Bot?>((ref) => null);

class BotsState {
  final List<Bot> bots;
  final bool isLoading;
  final String? error;

  BotsState({
    this.bots = const [],
    this.isLoading = false,
    this.error,
  });

  BotsState copyWith({
    List<Bot>? bots,
    bool? isLoading,
    String? error,
  }) {
    return BotsState(
      bots: bots ?? this.bots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BotsNotifier extends StateNotifier<BotsState> {
  final ApiService _apiService;

  BotsNotifier(this._apiService) : super(BotsState());

  Future<void> loadBots() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bots = await _apiService.getBots();
      state = state.copyWith(bots: bots, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Bot?> createBot(Bot bot) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final newBot = await _apiService.createBot(bot);
      state = state.copyWith(
        bots: [...state.bots, newBot],
        isLoading: false,
      );
      return newBot;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Bot?> updateBot(Bot bot, {String? whatsappAccessTokenPlain}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedBot = await _apiService.updateBot(
        bot,
        whatsappAccessTokenPlain: whatsappAccessTokenPlain,
      );
      final bots = state.bots.map((b) => b.id == bot.id ? updatedBot : b).toList();
      state = state.copyWith(bots: bots, isLoading: false);
      return updatedBot;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> deleteBot(String botId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.deleteBot(botId);
      final bots = state.bots.where((b) => b.id != botId).toList();
      state = state.copyWith(bots: bots, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<WhatsAppWebhookSetupInfo> fetchWhatsAppWebhookSetup(String botId) {
    return _apiService.getWhatsAppWebhookSetup(botId);
  }
}
