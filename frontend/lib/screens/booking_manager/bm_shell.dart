import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

class BMShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const BMShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _tabIndex() {
    if (location.startsWith('/bm/dashboard')) return 0;
    if (location.startsWith('/bm/approvals')) return 1;
    if (location.startsWith('/bm/bookings')) return 2;
    if (location.startsWith('/bm/room-live')) return 3;
    if (location.startsWith('/bm/reports')) return 4;
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

    Widget topBar;
    if (location.startsWith('/bm/dashboard')) {
      topBar = _BmTopBar(
        leading: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$greeting, ${user?.name.split(' ').first ?? 'Manager'}',
                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            Text(dateStr, style: AppTextStyles.bodySmall),
          ],
        ),
        trailing: _AvatarBtn(user: user, ref: ref),
      );
    } else {
      final titles = {
        '/bm/approvals': 'Approvals',
        '/bm/bookings': 'Bookings',
        '/bm/room-live': 'Live Status',
        '/bm/reports': 'Reports',
      };
      final title = titles.entries
          .firstWhere((e) => location.startsWith(e.key),
              orElse: () => const MapEntry('', 'GH Manager'))
          .value;
      topBar = _BmTopBar(
        leading: Text(title, style: AppTextStyles.pageTitle),
        trailing: _AvatarBtn(user: user, ref: ref),
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
      bottomNavigationBar: _BmNavBar(
        currentIndex: currentIndex,
        onTap: (i) {
          const routes = [
            '/bm/dashboard',
            '/bm/approvals',
            '/bm/bookings',
            '/bm/room-live',
            '/bm/reports',
          ];
          context.go(routes[i]);
        },
      ),
    );
  }
}

class _BmNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BmNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (icon: Icons.grid_view_outlined, active: Icons.grid_view_rounded, label: 'Home'),
      (icon: Icons.fact_check_outlined, active: Icons.fact_check_rounded, label: 'Approvals'),
      (icon: Icons.calendar_month_outlined, active: Icons.calendar_month_rounded, label: 'Bookings'),
      (icon: Icons.sensors_outlined, active: Icons.sensors_rounded, label: 'Live'),
      (icon: Icons.build_circle_outlined, active: Icons.build_circle_rounded, label: 'Reports'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        border: Border(top: BorderSide(color: AppColors.navBorderTop)),
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
                          isActive ? item.active : item.icon,
                          color: isActive ? Colors.white : AppColors.navUnselected,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? Colors.white : AppColors.navUnselected,
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

class _BmTopBar extends StatelessWidget {
  final Widget leading;
  final Widget? trailing;
  const _BmTopBar({required this.leading, this.trailing});

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

class _AvatarBtn extends ConsumerWidget {
  final dynamic user;
  final WidgetRef ref;
  const _AvatarBtn({required this.user, required this.ref});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = user != null ? _initials(user.name) : 'U';
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _ProfileDlg(user: user),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary,
        child: Text(initials,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _ProfileDlg extends ConsumerWidget {
  final dynamic user;
  const _ProfileDlg({required this.user});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = user != null ? _initials(user.name) : 'U';
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 36, backgroundColor: AppColors.primary,
              child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Text(user?.name ?? 'User', style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
            child: Text(user?.role ?? '', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          )),
        ],
      ),
    );
  }
}
