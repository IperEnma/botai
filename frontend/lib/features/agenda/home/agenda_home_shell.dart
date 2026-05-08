import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/auth_provider.dart';
import '../register/konecta_tokens.dart';

/// Shell lateral para usuarios logueados: entrada a Agenda (`/home`) y panel de bots (`/home/bots`).
class AgendaHomeShell extends ConsumerWidget {
  const AgendaHomeShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  static int selectedIndexForPath(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    if (p.startsWith('/home/bots')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final selectedIndex = selectedIndexForPath(currentPath);

    return Scaffold(
      backgroundColor: KTokens.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 216,
            decoration: BoxDecoration(
              color: KTokens.surface,
              border: Border(right: BorderSide(color: KTokens.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top + 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'konecta',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: KTokens.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _RailTile(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Inicio',
                  selected: selectedIndex == 0,
                  onTap: () => context.go('/home'),
                ),
                _RailTile(
                  icon: Icons.smart_toy_outlined,
                  selectedIcon: Icons.smart_toy,
                  label: 'Mis bots',
                  selected: selectedIndex == 1,
                  onTap: () => context.go('/home/bots'),
                ),
                const Spacer(),
                if (user?.photoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(user!.photoUrl!),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CircleAvatar(
                      radius: 22,
                      child: Text(
                        user?.name?.isNotEmpty == true
                            ? user!.name!.substring(0, 1).toUpperCase()
                            : 'U',
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(authStateProvider.notifier).signOut();
                      context.go('/');
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Salir'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? KTokens.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(KTokens.rMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(KTokens.rMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  size: 20,
                  color: selected ? KTokens.accent : KTokens.inkSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? KTokens.accent : KTokens.inkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
