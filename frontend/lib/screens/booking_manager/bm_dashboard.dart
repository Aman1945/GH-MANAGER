import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/loading_shimmer.dart';

class BMDashboard extends ConsumerWidget {
  const BMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(bmDashboardProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Column(
      children: [
        AppHeader(
          title: 'Dashboard',
          subtitle: 'Booking Manager Overview',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.refresh(bmDashboardProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dashAsync.when(
                  loading: () => isMobile
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: LoadingShimmer.metric()),
                                const SizedBox(width: 16),
                                Expanded(child: LoadingShimmer.metric()),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LoadingShimmer.metric(),
                          ],
                        )
                      : Row(
                          children: List.generate(3, (_) {
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
                        Text('Failed to load dashboard',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                        const Spacer(),
                        TextButton(
                          onPressed: () =>
                              ref.refresh(bmDashboardProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (stats) {
                    final card1 = MetricCard(
                      title: 'Pending Leads',
                      value: '${stats['pendingLeads'] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.warning,
                      subtitle: 'Awaiting review',
                    );
                    final card2 = MetricCard(
                      title: 'Available Rooms',
                      value: '${stats['availableRooms'] ?? 0}',
                      icon: Icons.meeting_room_rounded,
                      color: AppColors.success,
                      subtitle: 'Ready to assign',
                    );
                    final card3 = MetricCard(
                      title: 'Total Bookings',
                      value: '${stats['totalBookings'] ?? 0}',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.info,
                      subtitle: 'All time',
                    );

                    return isMobile
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: card1),
                                  const SizedBox(width: 16),
                                  Expanded(child: card2),
                                ],
                              ),
                              const SizedBox(height: 16),
                              card3,
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: card1),
                              const SizedBox(width: 16),
                              Expanded(child: card2),
                              const SizedBox(width: 16),
                              Expanded(child: card3),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 28),

                // Quick action card
                dashAsync.when(
                  loading: () => LoadingShimmer.card(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) {
                    final pending = stats['pendingLeads'] ?? 0;
                    return Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.warningLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.fact_check_rounded,
                                        color: AppColors.warning,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Pending Approvals',
                                        style: AppTextStyles.cardTitle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  pending > 0
                                      ? 'You have $pending leads waiting for your review.'
                                      : 'No pending leads at the moment.',
                                  style: AppTextStyles.bodySmall,
                                ),
                                if (pending > 0) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/bm/approvals'),
                                    icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16),
                                    label: const Text('Review Approvals'),
                                  ),
                                ],
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.fact_check_rounded,
                                    color: AppColors.warning,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pending Approvals',
                                        style: AppTextStyles.cardTitle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        pending > 0
                                            ? 'You have $pending leads waiting for your review.'
                                            : 'No pending leads at the moment.',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (pending > 0)
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/bm/approvals'),
                                    icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 16),
                                    label: const Text('Review Approvals'),
                                  ),
                              ],
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
