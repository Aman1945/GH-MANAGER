import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/metric_card.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  List<TextSpan> _parseSpans(String text, TextStyle base) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > start) spans.add(TextSpan(text: text.substring(start, m.start), style: base));
      spans.add(TextSpan(
          text: m.group(1),
          style: base.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)));
      start = m.end;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start), style: base));
    return spans;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminDashboardProvider);

    return dashAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LoadingShimmer(width: double.infinity, height: 240, borderRadius: 12),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load dashboard', style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.refresh(adminDashboardProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (stats) {
        final totalLeads = (stats['totalLeads'] ?? 0) as int;
        final pendingLeads = (stats['pendingLeads'] ?? 0) as int;
        final occupiedRooms = (stats['occupiedRooms'] ?? 0) as int;
        final totalRooms = (stats['totalRooms'] ?? 32) as int;
        final confirmedBookings = (stats['confirmedBookings'] ?? 0) as int;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminDashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI grid
                LayoutBuilder(
                  builder: (context, constraints) {
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
                          title: 'Total Leads',
                          value: '$totalLeads',
                          icon: Icons.people_outline_rounded,
                          color: AppColors.info,
                          trend: '+${pendingLeads}',
                        ),
                        MetricCard(
                          title: 'Pending Approvals',
                          value: '$pendingLeads',
                          icon: Icons.pending_actions_rounded,
                          color: AppColors.warning,
                          trend: pendingLeads > 0 ? '!' : null,
                        ),
                        MetricCard(
                          title: 'Occupied Rooms',
                          value: '$occupiedRooms/$totalRooms',
                          icon: Icons.hotel_rounded,
                          color: AppColors.error,
                        ),
                        MetricCard(
                          title: 'Confirmed',
                          value: '$confirmedBookings',
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity',
                        style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700)),
                    TextButton(
                      onPressed: () => context.go('/admin/bookings'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _ActivityItem(
                        iconBg: AppColors.infoLight,
                        icon: Icons.verified_user_outlined,
                        iconColor: AppColors.info,
                        title: 'Booking Confirmed',
                        subtitle: 'Guest **Sarah Jenkins** confirmed for Room 304 (3 nights).',
                        time: '2m ago',
                        parseSpans: _parseSpans,
                      ),
                      _ActivityItem(
                        iconBg: AppColors.warningLight,
                        icon: Icons.chat_bubble_outline_rounded,
                        iconColor: AppColors.warning,
                        title: 'New Inquiry',
                        subtitle: 'Lead **Michael Chen** requested availability for corporate event.',
                        time: '15m ago',
                        parseSpans: _parseSpans,
                      ),
                      _ActivityItem(
                        iconBg: AppColors.errorLight,
                        icon: Icons.cleaning_services_outlined,
                        iconColor: AppColors.error,
                        title: 'Cleaning Alert',
                        subtitle: "Room 102 reported as 'Dirty'. Scheduled cleaning delayed.",
                        time: '1h ago',
                        parseSpans: _parseSpans,
                      ),
                      _ActivityItem(
                        iconBg: AppColors.successLight,
                        icon: Icons.star_outline_rounded,
                        iconColor: AppColors.success,
                        title: 'New Review',
                        subtitle: '5-star rating received from **Emily Watson**.',
                        time: '3h ago',
                        isLast: true,
                        parseSpans: _parseSpans,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Text('Quick Actions',
                    style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700)),
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
                        onPressed: () => context.go('/admin/create-lead'),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('New Lead', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        onPressed: () => context.go('/admin/room-live'),
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
        );
      },
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isLast;
  final List<TextSpan> Function(String, TextStyle) parseSpans;

  const _ActivityItem({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.parseSpans,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppTextStyles.bodySmall;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 13)),
                    Text(time, style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(children: parseSpans(subtitle, base)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
