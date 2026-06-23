import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/room_model.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';

class AdminRooms extends ConsumerStatefulWidget {
  const AdminRooms({super.key});

  @override
  ConsumerState<AdminRooms> createState() => _AdminRoomsState();
}

class _AdminRoomsState extends ConsumerState<AdminRooms> {
  String? _selectedGhId;

  Color _borderColor(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return AppColors.success;
      case 'OCCUPIED':
        return AppColors.error;
      case 'BLOCKED':
        return AppColors.warning;
      case 'MAINTENANCE':
        return AppColors.info;
      default:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final guestHousesAsync = ref.watch(guestHousesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // GH filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
            child: guestHousesAsync.when(
              loading: () => const SizedBox(height: 36),
              error: (_, __) => const SizedBox(height: 36),
              data: (ghs) {
                final allItems = [
                  const MapEntry('', 'All Properties'),
                  ...ghs.map((gh) => MapEntry(gh.id, gh.name)),
                ];
                return SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: allItems.map((item) {
                      final isActive = (_selectedGhId ?? '') == item.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(item.value),
                          selected: isActive,
                          onSelected: (_) {
                            final id = item.key.isEmpty ? null : item.key;
                            setState(() => _selectedGhId = id);
                            ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: id);
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primarySurface,
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                          ),
                          side: BorderSide(color: isActive ? AppColors.primary : AppColors.border),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          // Room list
          Expanded(
            child: roomsAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: LoadingShimmer.table(rows: 8),
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
                      onPressed: () => ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: _selectedGhId),
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
                    subtitle: 'Try selecting a different guest house',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: _selectedGhId),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final room = rooms[i];
                      final borderColor = _borderColor(room.status);
                      return _RoomTile(room: room, accentColor: borderColor);
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

class _RoomTile extends StatelessWidget {
  final RoomModel room;
  final Color accentColor;

  const _RoomTile({required this.room, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  room.roomNumber,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: accentColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Room ${room.roomNumber}', style: AppTextStyles.cardTitle),
                  if (room.guestHouse != null)
                    Text(room.guestHouse!.name, style: AppTextStyles.caption),
                ],
              ),
            ),
            StatusChip(status: room.status),
          ],
        ),
      ),
    );
  }
}
