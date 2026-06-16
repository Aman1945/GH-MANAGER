import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_sidebar.dart';

class GHMShell extends ConsumerWidget {
  final Widget child;

  const GHMShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppSidebar(
            role: 'GH_MANAGER',
            currentRoute: location,
            userName: user?.name ?? 'GH Manager',
            userEmail: user?.email ?? '',
            onNavigate: (route) => context.go(route),
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
