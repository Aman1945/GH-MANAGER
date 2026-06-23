import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/lead_model.dart';
import '../../models/room_model.dart';
import '../../providers/approvals_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/confirmation_dialog.dart';

class BMApprovals extends ConsumerWidget {
  const BMApprovals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: approvalsAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LoadingShimmer.card(),
            )),
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load approvals'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(approvalsProvider.notifier).fetchPending(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (leads) {
          if (leads.isEmpty) {
            return EmptyState(
              icon: Icons.check_circle_rounded,
              title: 'All caught up!',
              subtitle: 'No leads awaiting approval.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(approvalsProvider.notifier).fetchPending(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: leads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ApprovalCard(lead: leads[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  final LeadModel lead;
  const _ApprovalCard({required this.lead});

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  final _dateFormat = DateFormat('dd MMM yyyy');
  List<RoomModel> _availableRooms = [];
  String? _selectedRoomId;
  bool _loadingRooms = false;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _allGuestHouses = [];
  String? _selectedGhId;

  @override
  void initState() {
    super.initState();
    _selectedGhId = widget.lead.preferredGuestHouse?.id;
    _fetchGuestHouses();
    if (_selectedGhId != null) _fetchAvailableRooms();
  }

  Future<void> _fetchGuestHouses() async {
    try {
      final raw = await ApiService().getGuestHouses();
      if (mounted) setState(() => _allGuestHouses = raw.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> _fetchAvailableRooms() async {
    final ghId = _selectedGhId;
    if (ghId == null) return;
    setState(() {
      _loadingRooms = true;
      _availableRooms = [];
      _selectedRoomId = null;
    });
    try {
      final raw = await ApiService().getAvailability(
        ghId,
        widget.lead.checkIn.toIso8601String(),
        widget.lead.checkOut.toIso8601String(),
      );
      final rooms = raw.map((e) => RoomModel.fromJson(e as Map<String, dynamic>)).toList();
      if (mounted) setState(() { _availableRooms = rooms; _loadingRooms = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  Future<void> _approve() async {
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a room first'),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final selectedRoom = _availableRooms.firstWhere((r) => r.id == _selectedRoomId);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Approve Lead',
      message: 'Approve and assign Room ${selectedRoom.roomNumber} to ${widget.lead.guestName}?',
      confirmLabel: 'Approve',
    );
    if (confirmed != true) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(approvalsProvider.notifier).approveLead(widget.lead.id, _selectedRoomId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lead approved and booking created'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reject Lead',
      message: 'Reject lead for ${widget.lead.guestName}? This cannot be undone.',
      confirmLabel: 'Reject',
      isDangerous: true,
    );
    if (confirmed != true) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(approvalsProvider.notifier).rejectLead(widget.lead.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lead rejected'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'G';
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(_initials(lead.guestName),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.guestName, style: AppTextStyles.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Lead #${lead.id.length > 6 ? lead.id.substring(lead.id.length - 6) : lead.id}',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                StatusChip(status: lead.status),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Info rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoRow(icon: Icons.phone_outlined, text: lead.phone),
                _InfoRow(icon: Icons.email_outlined, text: lead.email),
                _InfoRow(
                  icon: Icons.home_outlined,
                  text: lead.preferredGuestHouse?.name ?? 'Not specified',
                ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text: '${_dateFormat.format(lead.checkIn)} → ${_dateFormat.format(lead.checkOut)}',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),

          // Assignment section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GH selector
                if (_allGuestHouses.isNotEmpty) ...[
                  Text('Assign Guest House', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surfaceVariant,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGhId,
                        isExpanded: true,
                        hint: Text('Select guest house', style: AppTextStyles.bodySmall),
                        style: AppTextStyles.bodyMedium,
                        items: _allGuestHouses.map((gh) {
                          final id = gh['_id']?.toString() ?? '';
                          final name = gh['name']?.toString() ?? 'Unknown';
                          final location = gh['location']?.toString();
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(location != null ? '$name ($location)' : name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() { _selectedGhId = val; _selectedRoomId = null; _availableRooms = []; });
                          _fetchAvailableRooms();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Room selector
                Text('Assign Room', style: AppTextStyles.label),
                const SizedBox(height: 6),
                if (_loadingRooms)
                  Row(children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Text('Loading available rooms...', style: AppTextStyles.bodySmall),
                  ])
                else if (_availableRooms.isEmpty)
                  Row(children: [
                    const Icon(Icons.info_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Text('No rooms available for these dates', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                  ])
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.surfaceVariant,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRoomId,
                        isExpanded: true,
                        hint: Text('Select a room', style: AppTextStyles.bodySmall),
                        style: AppTextStyles.bodyMedium,
                        items: _availableRooms.map((r) {
                          return DropdownMenuItem(
                            value: r.id,
                            child: Text('Room ${r.roomNumber}${r.guestHouse != null ? ' — ${r.guestHouse!.name}' : ''}'),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedRoomId = val),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Action buttons
                if (_isProcessing)
                  const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _reject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedRoomId == null || _availableRooms.isEmpty ? null : _approve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
