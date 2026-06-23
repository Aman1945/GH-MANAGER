import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';

class RoomOccupationScreen extends StatefulWidget {
  const RoomOccupationScreen({super.key});

  @override
  State<RoomOccupationScreen> createState() => _RoomOccupationScreenState();
}

class _RoomOccupationScreenState extends State<RoomOccupationScreen> {
  List<RoomModel> _rooms = [];
  bool _loading = true;
  String? _error;
  DateTime? _lastRefreshed;
  Timer? _refreshTimer;
  final _timeFormat = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadRooms());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;
    setState(() {
      _loading = _rooms.isEmpty;
      _error = null;
    });
    try {
      final raw = await ApiService().getRooms();
      final rooms = raw.map((e) => RoomModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _loading = false;
          _lastRefreshed = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Map<String, List<RoomModel>> _groupByGuestHouse() {
    final Map<String, List<RoomModel>> grouped = {};
    for (final room in _rooms) {
      final name = room.guestHouse?.name ?? 'Unknown';
      grouped.putIfAbsent(name, () => []).add(room);
    }
    return Map.fromEntries(grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByGuestHouse();
    final total = _rooms.length;
    final available = _rooms.where((r) => r.status == 'AVAILABLE').length;
    final occupied = _rooms.where((r) => r.status == 'OCCUPIED').length;
    final blocked = _rooms.where((r) => r.status == 'BLOCKED').length;
    final maintenance = _rooms.where((r) => r.status == 'MAINTENANCE').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadRooms, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRooms,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Refresh indicator
                        if (_lastRefreshed != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE · Updated ${_timeFormat.format(_lastRefreshed!)} · Auto-refreshes every 30s',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),

                        // Summary bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$total Total Rooms',
                                  style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  _StatChip(color: AppColors.success, label: 'Available', count: available),
                                  _StatChip(color: AppColors.error, label: 'Occupied', count: occupied),
                                  _StatChip(color: AppColors.warning, label: 'Blocked', count: blocked),
                                  _StatChip(color: AppColors.info, label: 'Maintenance', count: maintenance),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Per-GH sections
                        ...grouped.entries.map((entry) => _GuestHouseSection(
                          name: entry.key,
                          rooms: entry.value,
                        )),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _StatChip({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            '$label ($count)',
            style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _GuestHouseSection extends StatelessWidget {
  final String name;
  final List<RoomModel> rooms;

  const _GuestHouseSection({required this.name, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final avail = rooms.where((r) => r.status == 'AVAILABLE').length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(name, style: AppTextStyles.sectionTitle.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('$avail/${rooms.length} available',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: rooms.map((room) => _RoomTile(room: room)).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;

  const _RoomTile({required this.room});

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE': return AppColors.success;
      case 'OCCUPIED': return AppColors.error;
      case 'BLOCKED': return AppColors.warning;
      case 'MAINTENANCE': return AppColors.info;
      default: return AppColors.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'AVAILABLE': return Icons.check_circle_outline_rounded;
      case 'OCCUPIED': return Icons.person_rounded;
      case 'BLOCKED': return Icons.lock_outline_rounded;
      case 'MAINTENANCE': return Icons.build_outlined;
      default: return Icons.help_outline_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'AVAILABLE': return 'AVAIL';
      case 'OCCUPIED': return 'OCC';
      case 'BLOCKED': return 'BLOCK';
      case 'MAINTENANCE': return 'MAINT';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(room.status);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_statusIcon(room.status), color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            room.roomNumber,
            style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
          Text(
            _statusLabel(room.status),
            style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.85), fontSize: 8, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
