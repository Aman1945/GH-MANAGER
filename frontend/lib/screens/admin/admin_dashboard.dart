import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/loading_shimmer.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminDashboardProvider);
    final user = ref.watch(authProvider).user;

    return Column(
      children: [
        AppHeader(
          title: 'Dashboard',
          subtitle: 'Welcome back, ${user?.name ?? 'Admin'}',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.refresh(adminDashboardProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Row
                dashAsync.when(
                  loading: () => Row(
                    children: List.generate(4, (_) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: LoadingShimmer.metric(),
                        ),
                      );
                    }),
                  ),
                  error: (e, _) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Failed to load dashboard data.',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              ref.refresh(adminDashboardProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (stats) => Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          title: 'Pending Leads',
                          value: '${stats['pendingLeads'] ?? 0}',
                          icon: Icons.pending_actions_rounded,
                          color: AppColors.warning,
                          subtitle: 'Awaiting approval',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Blocked Rooms',
                          value: '${stats['blockedRooms'] ?? 0}',
                          icon: Icons.block_rounded,
                          color: AppColors.error,
                          subtitle: 'Rooms reserved',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Confirmed Bookings',
                          value: '${stats['confirmedBookings'] ?? 0}',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          subtitle: 'Active bookings',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricCard(
                          title: 'Occupied Rooms',
                          value: '${stats['occupiedRooms'] ?? 0}',
                          icon: Icons.hotel_rounded,
                          color: AppColors.info,
                          subtitle: 'Guests checked in',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Quick Overview', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),
                dashAsync.when(
                  loading: () => LoadingShimmer.table(rows: 3),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatRow(
                          label: 'Total Leads',
                          value: '${stats['totalLeads'] ?? 0}',
                        ),
                        const Divider(height: 20),
                        _StatRow(
                          label: 'Total Rooms',
                          value: '${stats['totalRooms'] ?? 0}',
                        ),
                        const Divider(height: 20),
                        _StatRow(
                          label: 'Total Bookings',
                          value: '${stats['totalBookings'] ?? 0}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.labelMedium
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
