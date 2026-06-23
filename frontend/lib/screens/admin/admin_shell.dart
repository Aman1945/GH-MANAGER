import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const AdminShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _tabIndex() {
    if (location.startsWith('/admin/dashboard')) { return 0; }
    if (location.startsWith('/admin/leads') ||
        location.startsWith('/admin/create-lead')) { return 1; }
    if (location.startsWith('/admin/bookings')) { return 2; }
    if (location.startsWith('/admin/room-live')) { return 3; }
    if (location.startsWith('/admin/more') ||
        location.startsWith('/admin/rooms') ||
        location.startsWith('/admin/reports')) { return 4; }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = DateFormat('EEE, d MMM').format(now);

    final currentIndex = _tabIndex();

    // Top bar content per location
    Widget topBar;
    if (location.startsWith('/admin/dashboard')) {
      topBar = _NavTopBar(
        leading: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$greeting, ${user?.name.split(' ').first ?? 'Admin'}',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(dateStr, style: AppTextStyles.bodySmall),
          ],
        ),
        trailing: _AvatarButton(user: user, context: context, ref: ref),
      );
    } else {
      final titles = {
        '/admin/leads': 'Leads',
        '/admin/create-lead': 'New Lead',
        '/admin/bookings': 'Bookings',
        '/admin/rooms': 'Rooms',
        '/admin/room-live': 'Live Status',
        '/admin/reports': 'Reports',
        '/admin/more': 'More',
      };
      final title = titles.entries
          .firstWhere((e) => location.startsWith(e.key),
              orElse: () => const MapEntry('', 'GH Manager'))
          .value;
      topBar = _NavTopBar(
        leading: Text(title, style: AppTextStyles.pageTitle),
        trailing: _AvatarButton(user: user, context: context, ref: ref),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          topBar,
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _NavBar(
        currentIndex: currentIndex,
        items: const [
          _NavItem(
              icon: Icons.grid_view_outlined,
              activeIcon: Icons.grid_view_rounded,
              label: 'Home'),
          _NavItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Leads'),
          _NavItem(
              icon: Icons.calendar_month_outlined,
              activeIcon: Icons.calendar_month_rounded,
              label: 'Bookings'),
          _NavItem(
              icon: Icons.sensors_outlined,
              activeIcon: Icons.sensors_rounded,
              label: 'Live'),
          _NavItem(
              icon: Icons.more_horiz_rounded,
              activeIcon: Icons.more_horiz_rounded,
              label: 'More'),
        ],
        onTap: (i) {
          const routes = [
            '/admin/dashboard',
            '/admin/leads',
            '/admin/bookings',
            '/admin/room-live',
            '/admin/more',
          ];
          context.go(routes[i]);
        },
      ),
    );
  }
}

// ---- shared nav bar components ----

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _NavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(
          top: BorderSide(color: AppColors.navBorderTop, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    splashColor: Colors.white.withValues(alpha: 0.05),
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? Colors.white
                              : AppColors.navUnselected,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isActive
                                ? Colors.white
                                : AppColors.navUnselected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTopBar extends StatelessWidget {
  final Widget leading;
  final Widget? trailing;

  const _NavTopBar({required this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(child: leading),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  final dynamic user;
  final BuildContext context;
  final WidgetRef ref;

  const _AvatarButton(
      {required this.user, required this.context, required this.ref});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final initials = user != null ? _initials(user.name) : 'U';
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => _ProfileDialog(user: user, ref: ref),
        );
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ProfileDialog extends ConsumerWidget {
  final dynamic user;
  final WidgetRef ref;

  const _ProfileDialog({required this.user, required this.ref});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts.isNotEmpty && parts[0].isNotEmpty
        ? parts[0][0].toUpperCase()
        : 'U';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = user != null ? _initials(user.name) : 'U';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary,
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'User',
              style:
                  AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(user?.role ?? '',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
