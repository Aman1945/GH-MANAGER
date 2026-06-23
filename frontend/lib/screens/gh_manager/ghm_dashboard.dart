import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/status_chip.dart';

class GHMDashboard extends ConsumerWidget {
  const GHMDashboard({super.key});

  Color _borderColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE': return AppColors.success;
      case 'OCCUPIED': return AppColors.error;
      case 'BLOCKED': return AppColors.warning;
      default: return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(ghmDashboardProvider);
    final user = ref.watch(authProvider).user;
    final roomsAsync = ref.watch(roomsProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good morning'
        : now.hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr = DateFormat('EEEE, d MMM').format(now);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ghmDashboardProvider);
          ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: user?.guestHouseId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text('GH Manager', style: AppTextStyles.pageTitle),
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
                        onPressed: () => ref.refresh(ghmDashboardProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (stats) {
                  final occupiedRooms = stats['occupiedRooms'] ?? 0;
                  final availableRooms = stats['availableRooms'] ?? 0;
                  final blockedRooms = stats['blockedRooms'] ?? 0;
                  final totalRooms = stats['totalRooms'] ?? (occupiedRooms + availableRooms + blockedRooms);

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
                          title: 'Occupied',
                          value: '$occupiedRooms',
                          icon: Icons.hotel_rounded,
                          color: AppColors.error,
                        ),
                        MetricCard(
                          title: 'Available',
                          value: '$availableRooms',
                          icon: Icons.meeting_room_rounded,
                          color: AppColors.success,
                        ),
                        MetricCard(
                          title: 'Blocked',
                          value: '$blockedRooms',
                          icon: Icons.block_rounded,
                          color: AppColors.warning,
                        ),
                        MetricCard(
                          title: 'Total Rooms',
                          value: '$totalRooms',
                          icon: Icons.home_work_rounded,
                          color: AppColors.info,
                        ),
                      ],
                    );
                  });
                },
              ),

              const SizedBox(height: 24),

              // Room Status grid
              Text('Room Status', style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              roomsAsync.when(
                loading: () => GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.2,
                  children: List.generate(6, (_) => LoadingShimmer(width: double.infinity, height: 80, borderRadius: 10)),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (rooms) {
                  if (rooms.isEmpty) return const SizedBox.shrink();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final borderColor = _borderColor(room.status);
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: borderColor, width: 1.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(room.roomNumber, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
                            const SizedBox(height: 6),
                            StatusChip(status: room.status),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
