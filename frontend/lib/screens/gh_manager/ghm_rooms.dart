import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/room_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';

class GHMRooms extends ConsumerWidget {
  const GHMRooms({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final roomsAsync = ref.watch(roomsProvider);

    return Column(
      children: [
        AppHeader(
          title: 'Room Status',
          subtitle: 'Live room availability',
          actions: [
            // Legend
            Row(
              children: [
                _LegendDot(color: AppColors.success, label: 'Available'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.warning, label: 'Blocked'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.error, label: 'Occupied'),
              ],
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(roomsProvider.notifier)
                  .fetchRooms(guestHouseId: user?.guestHouseId),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: roomsAsync.when(
              loading: () => GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 140 / 140,
                ),
                itemCount: 9,
                itemBuilder: (_, __) => LoadingShimmer(
                  width: double.infinity,
                  height: 140,
                  borderRadius: 12,
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load rooms',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(roomsProvider.notifier)
                          .fetchRooms(
                              guestHouseId: user?.guestHouseId),
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
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    return _RoomCard(
                      room: rooms[index],
                      borderColor: _borderColor(rooms[index].status),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatefulWidget {
  final RoomModel room;
  final Color borderColor;

  const _RoomCard({required this.room, required this.borderColor});

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: widget.borderColor,
            width: _hovered ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.room.roomNumber,
                style: AppTextStyles.metricValue.copyWith(
                  fontSize: 32,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.room.guestHouse != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.room.guestHouse!.name,
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              StatusChip(status: widget.room.status),
            ],
          ),
        ),
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
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
