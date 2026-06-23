import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/metric_card.dart';

class BMDashboard extends ConsumerWidget {
  const BMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(bmDashboardProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(bmDashboardProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting (mirror of admin shell top bar style but inside body)
              Text(greeting, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text('Booking Manager', style: AppTextStyles.pageTitle),
              Text(dateStr, style: AppTextStyles.caption),
              const SizedBox(height: 20),

              // KPIs
              dashAsync.when(
                loading: () => LayoutBuilder(builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: List.generate(4, (_) => LoadingShimmer.metric()),
                  );
                }),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Failed to load dashboard')),
                      TextButton(
                        onPressed: () => ref.refresh(bmDashboardProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (stats) {
                  final pendingLeads = stats['pendingLeads'] ?? 0;
                  final availableRooms = stats['availableRooms'] ?? 0;
                  final totalBookings = stats['totalBookings'] ?? 0;
                  final confirmedBookings = stats['confirmedBookings'] ?? 0;

                  return LayoutBuilder(builder: (context, constraints) {
                    final cols = constraints.maxWidth < 500 ? 2 : 4;
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: cols == 2 ? 1.5 : 1.6,
                      children: [
                        MetricCard(
                          title: 'Pending Leads',
                          value: '$pendingLeads',
                          icon: Icons.pending_actions_rounded,
                          color: AppColors.warning,
                          trend: pendingLeads > 0 ? '!' : null,
                        ),
                        MetricCard(
                          title: 'Available Rooms',
                          value: '$availableRooms',
                          icon: Icons.meeting_room_rounded,
                          color: AppColors.success,
                        ),
                        MetricCard(
                          title: 'Total Bookings',
                          value: '$totalBookings',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.info,
                        ),
                        MetricCard(
                          title: 'Confirmed',
                          value: '$confirmedBookings',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    );
                  });
                },
              ),
              const SizedBox(height: 24),

              // Pending approvals alert banner
              dashAsync.when(
                loading: () => LoadingShimmer.card(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) {
                  final pending = stats['pendingLeads'] ?? 0;
                  if (pending == 0) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fact_check_rounded, color: AppColors.warning, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$pending Leads Awaiting Review',
                                    style: AppTextStyles.cardTitle.copyWith(color: AppColors.warning)),
                                Text('Review and assign rooms to pending leads.',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => context.go('/bm/approvals'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Quick actions
              Text('Quick Actions', style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => context.go('/bm/approvals'),
                      icon: const Icon(Icons.fact_check_rounded, size: 18),
                      label: const Text('Approvals', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => context.go('/bm/room-live'),
                      icon: const Icon(Icons.sensors_rounded, size: 18),
                      label: const Text('Live View', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
