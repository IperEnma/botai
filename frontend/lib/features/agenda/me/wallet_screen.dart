import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/wallet.dart';
import '../../../providers/agenda/me/wallet_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../theme/agenda_tokens.dart';

const _kPrimary = Color(0xFF6366F1);
const _kAccent  = Color(0xFF8B5CF6);
const _kSurface = Color(0xFFF8FAFC);
const _kDark    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key, required this.subscriptionId});

  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider(subscriptionId));

    return Scaffold(
      backgroundColor: _kSurface,
      body: _Body(state: state, subscriptionId: subscriptionId),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.subscriptionId});

  final WalletState state;
  final String subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(walletProvider(subscriptionId).notifier).load(),
      );
    }

    final wallet = state.wallet;
    if (wallet == null) return const AgendaLoadingView();

    return Column(
      children: [
        _WalletHero(
          wallet: wallet,
          onRefresh: () =>
              ref.read(walletProvider(subscriptionId).notifier).load(),
        ),
        Expanded(
          child: wallet.movimientos.isEmpty
              ? const AgendaEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Sin movimientos',
                  subtitle: 'Los movimientos de créditos aparecerán acá.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: wallet.movimientos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _TransactionCard(tx: wallet.movimientos[i]),
                ),
        ),
      ],
    );
  }
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.wallet, required this.onRefresh});

  final Wallet wallet;
  final VoidCallback onRefresh;

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final vencimiento = wallet.fechaExpiracion;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16,
        24,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: onRefresh,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Saldo disponible',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            '${wallet.saldoActual}',
            style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1),
          ),
          Text(
            'créditos',
            style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
          if (vencimiento != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_outlined,
                      size: 13, color: Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    'Vence el ${_formatDate(vencimiento)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.tx});

  final CreditTransaction tx;

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 365) return 'hace ${(diff.inDays / 365).floor()} año(s)';
    if (diff.inDays > 30) return 'hace ${(diff.inDays / 30).floor()} mes(es)';
    if (diff.inDays > 0) return 'hace ${diff.inDays} día(s)';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    final color = isCredit
        ? AgendaTokens.creditPositive
        : AgendaTokens.creditNegative;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCredit
                    ? Icons.add_rounded
                    : Icons.remove_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.motivo,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kDark),
                  ),
                  Text(
                    _formatRelative(tx.createdAt),
                    style:
                        GoogleFonts.poppins(fontSize: 11, color: _kMuted),
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : ''}${tx.monto}',
              style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
