import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/subscription.dart';
import '../../../providers/agenda/me/subscriptions_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';
import '../theme/agenda_tokens.dart';

const _kPrimary = Color(0xFF6366F1);
const _kAccent  = Color(0xFF8B5CF6);
const _kSurface = Color(0xFFF8FAFC);
const _kDark    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);

class MySubscriptionsScreen extends ConsumerWidget {
  const MySubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsProvider);

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          _SubsHero(
            onRefresh: () =>
                ref.read(subscriptionsProvider.notifier).load(),
          ),
          Expanded(child: _Body(state: state)),
        ],
      ),
    );
  }
}

class _SubsHero extends StatelessWidget {
  const _SubsHero({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        24,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.card_membership_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis suscripciones',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  'Tus planes activos y créditos',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final SubscriptionsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(subscriptionsProvider.notifier).load(),
      );
    }

    if (state.items.isEmpty) {
      return const AgendaEmptyState(
        icon: Icons.card_membership_outlined,
        title: 'Sin suscripciones',
        subtitle: 'Comprá un plan en un negocio para empezar.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'Solo activas',
                selected: state.onlyActive,
                onSelected: (v) =>
                    ref.read(subscriptionsProvider.notifier).load(onlyActive: v),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: state.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _SubscriptionCard(sub: state.items[i]),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? _kPrimary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : _kMuted),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.sub});

  final Subscription sub;

  Color _statusColor() {
    switch (sub.estado) {
      case SubscriptionEstado.activa:
        return const Color(0xFF22C55E);
      case SubscriptionEstado.expirada:
        return const Color(0xFFEF4444);
      case SubscriptionEstado.cancelada:
        return Colors.grey;
      case SubscriptionEstado.agotada:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final vencimiento = sub.fechaExpiracion;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(
              '/agenda/me/subscriptions/${sub.id}/wallet'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        sub.estado.label,
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor),
                      ),
                    ),
                    Text(
                      '${sub.saldoActual} créditos',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.label_outline_rounded,
                        size: 14, color: _kMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Plan: ${sub.planId}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
                if (vencimiento != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.event_outlined, size: 14, color: _kMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Vence: ${_formatDate(vencimiento)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: vencimiento.isBefore(DateTime.now())
                              ? AgendaTokens.creditNegative
                              : _kMuted,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver billetera',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: _kPrimary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
