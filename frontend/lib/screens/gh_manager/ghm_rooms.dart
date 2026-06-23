import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';

class GHMRooms extends ConsumerWidget {
  const GHMRooms({super.key});

  Color _borderColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE': return AppColors.success;
      case 'OCCUPIED': return AppColors.error;
      case 'BLOCKED': return AppColors.warning;
      case 'MAINTENANCE': return AppColors.info;
      default: return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final roomsAsync = ref.watch(roomsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Legend bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.surface,
            child: Row(
              children: [
                _LegendDot(color: AppColors.success, label: 'Available'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.error, label: 'Occupied'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.warning, label: 'Blocked'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 20),
                  onPressed: () => ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: user?.guestHouseId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Rooms
          Expanded(
            child: roomsAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: List.generate(9, (_) => LoadingShimmer(width: double.infinity, height: 100, borderRadius: 12)),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    const Text('Failed to load rooms'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: user?.guestHouseId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (rooms) {
                if (rooms.isEmpty) {
                  return EmptyState(
                    icon: Icons.meeting_room_rounded,
                    title: 'No rooms found',
                    subtitle: 'No rooms are assigned to this guest house',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: user?.guestHouseId),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      return _RoomCard(room: rooms[index], borderColor: _borderColor(rooms[index].status));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final Color borderColor;

  const _RoomCard({required this.room, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            room.roomNumber,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          StatusChip(status: room.status),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
