import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/guest_house_model.dart';
import '../../models/room_model.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/app_header.dart';
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
      case 'BLOCKED':
        return AppColors.warning;
      case 'OCCUPIED':
        return AppColors.error;
      default:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);
    final guestHousesAsync = ref.watch(guestHousesProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 900;

    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final childAspectRatio = isMobile ? 1.1 : 1.5;

    Widget buildDropdown({required bool isMobile}) {
      return guestHousesAsync.when(
        loading: () => SizedBox(
            width: isMobile ? double.infinity : 200,
            child: const LinearProgressIndicator(color: AppColors.primary)),
        error: (_, __) => const SizedBox.shrink(),
        data: (guestHouses) {
          final items = <GuestHouseModel>[
            const GuestHouseModel(id: '', name: 'All Properties'),
            ...guestHouses,
          ];
          return Container(
            height: 40,
            width: isMobile ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGhId ?? '',
                isExpanded: isMobile,
                style: AppTextStyles.bodyMedium,
                items: items.map((gh) {
                  return DropdownMenuItem(
                    value: gh.id,
                    child: Text(gh.name),
                  );
                }).toList(),
                onChanged: (val) {
                  final id = val?.isEmpty == true ? null : val;
                  setState(() => _selectedGhId = id);
                  ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: id);
                },
              ),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        AppHeader(
          title: 'Rooms',
          subtitle: 'Room availability across all properties',
          actions: isMobile
              ? [
                  IconButton(
                    onPressed: () => ref
                        .read(roomsProvider.notifier)
                        .fetchRooms(guestHouseId: _selectedGhId),
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                  ),
                ]
              : [
                  buildDropdown(isMobile: false),
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(roomsProvider.notifier)
                        .fetchRooms(guestHouseId: _selectedGhId),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
        ),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: buildDropdown(isMobile: true),
          ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: roomsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
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
                          .fetchRooms(guestHouseId: _selectedGhId),
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
                    subtitle: 'No rooms are registered in the system',
                  );
                }
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: isMobile ? 12 : 16,
                    mainAxisSpacing: isMobile ? 12 : 16,
                    childAspectRatio: childAspectRatio,
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

  const _RoomCard({
    required this.room,
    required this.borderColor,
  });

  @override
  State<_RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<_RoomCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
              color: widget.borderColor,
              width: _hovered ? 2 : 1),
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
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.room.roomNumber,
                style: AppTextStyles.cardTitle.copyWith(
                  fontSize: isMobile ? 16 : 18,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                widget.room.guestHouse?.name ?? '',
                style: AppTextStyles.caption.copyWith(
                  fontSize: isMobile ? 10 : 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 6 : 12),
              StatusChip(status: widget.room.status),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep empty shimmer widget for completeness
// ignore: unused_element
Widget _buildShimmerGrid() {
  return GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
    ),
    itemCount: 6,
    itemBuilder: (_, __) => LoadingShimmer(
      width: double.infinity,
      height: 120,
      borderRadius: 12,
    ),
  );
}
