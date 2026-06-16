import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/status_chip.dart';

class GHMDashboard extends ConsumerWidget {
  const GHMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(ghmDashboardProvider);
    final user = ref.watch(authProvider).user;
    final roomsAsync = ref.watch(roomsProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;

    final gridCrossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final gridChildAspectRatio = isMobile ? 1.4 : 1.8;

    return Column(
      children: [
        AppHeader(
          title: 'Dashboard',
          subtitle: 'Guest House Manager — Overview',
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(ghmDashboardProvider);
                ref
                    .read(roomsProvider.notifier)
                    .fetchRooms(guestHouseId: user?.guestHouseId);
              },
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
                // KPI Row
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
                              ref.refresh(ghmDashboardProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (stats) {
                    final card1 = MetricCard(
                      title: 'Occupied Rooms',
                      value: '${stats['occupiedRooms'] ?? 0}',
                      icon: Icons.hotel_rounded,
                      color: AppColors.error,
                      subtitle: 'Guests checked in',
                    );
                    final card2 = MetricCard(
                      title: 'Available Rooms',
                      value: '${stats['availableRooms'] ?? 0}',
                      icon: Icons.meeting_room_rounded,
                      color: AppColors.success,
                      subtitle: 'Ready for booking',
                    );
                    final card3 = MetricCard(
                      title: 'Blocked Rooms',
                      value: '${stats['blockedRooms'] ?? 0}',
                      icon: Icons.block_rounded,
                      color: AppColors.warning,
                      subtitle: 'Reserved rooms',
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
                Text('Room Status', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 16),

                // Mini room grid
                roomsAsync.when(
                  loading: () => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: gridChildAspectRatio,
                    ),
                    itemCount: 8,
                    itemBuilder: (_, __) => LoadingShimmer(
                      width: double.infinity,
                      height: 80,
                      borderRadius: 10,
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (rooms) {
                    if (rooms.isEmpty) return const SizedBox.shrink();
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCrossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: gridChildAspectRatio,
                      ),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        final borderColor =
                            _borderColor(room.status);
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(
                                color: borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  room.roomNumber,
                                  style: AppTextStyles.cardTitle
                                      .copyWith(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                StatusChip(status: room.status),
                              ],
                            ),
                          ),
                        );
                      },
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

  Color _borderColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return AppColors.success;
      case 'BLOCKED':
        return AppColors.warning;
      case 'OCCUPIED':
        return AppColors.error;
      default:
        return AppColors.border;
    }
  }
}
