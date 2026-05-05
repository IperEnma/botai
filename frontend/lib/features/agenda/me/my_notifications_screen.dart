import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/agenda/agenda_notification.dart';
import '../../../providers/agenda/me/notifications_provider.dart';
import '../../../widgets/agenda/agenda_state_views.dart';

const _kPrimary = Color(0xFF6366F1);
const _kAccent  = Color(0xFF8B5CF6);
const _kSurface = Color(0xFFF8FAFC);
const _kDark    = Color(0xFF0F172A);
const _kMuted   = Color(0xFF64748B);

class MyNotificationsScreen extends ConsumerWidget {
  const MyNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: _kSurface,
      body: Column(
        children: [
          _NotificationsHero(
            onRefresh: () =>
                ref.read(notificationsProvider.notifier).load(),
          ),
          Expanded(child: _Body(state: state)),
        ],
      ),
    );
  }
}

class _NotificationsHero extends StatelessWidget {
  const _NotificationsHero({required this.onRefresh});

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
            child: const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  'Reservas y suscripciones',
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

  final NotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) return const AgendaLoadingView();
    if (state.error != null) {
      return AgendaErrorView(
        message: state.error!,
        onRetry: () => ref.read(notificationsProvider.notifier).load(),
      );
    }

    if (state.items.isEmpty) {
      return const AgendaEmptyState(
        icon: Icons.notifications_none_outlined,
        title: 'Sin notificaciones',
        subtitle:
            'Tus notificaciones de reservas y suscripciones aparecerán acá.',
      );
    }

    final sorted = [...state.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _NotificationCard(
        notification: sorted[i],
        onTap: () => ref
            .read(notificationsProvider.notifier)
            .markAsRead(sorted[i].id),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final AgendaNotification notification;
  final VoidCallback onTap;

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    return 'hace ${diff.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification.estado.isRead;

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead
              ? Colors.grey.shade100
              : _kPrimary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.notifications_rounded,
                          color: _kPrimary, size: 20),
                    ),
                    if (!isRead)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.titulo,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight:
                              isRead ? FontWeight.w500 : FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification.cuerpo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: _kMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatRelative(notification.createdAt),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: _kMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
