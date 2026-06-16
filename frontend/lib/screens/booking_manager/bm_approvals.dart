import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/lead_model.dart';
import '../../models/room_model.dart';
import '../../providers/approvals_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/confirmation_dialog.dart';

class BMApprovals extends ConsumerWidget {
  const BMApprovals({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsProvider);
    final count = approvalsAsync.valueOrNull?.length ?? 0;

    return Column(
      children: [
        AppHeader(
          title: 'Pending Approvals',
          subtitle: '$count leads awaiting review',
          actions: [
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(approvalsProvider.notifier).fetchPending(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: approvalsAsync.when(
              loading: () => Column(
                children: List.generate(
                    3, (_) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 16),
                          child: LoadingShimmer.card(),
                        )),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load approvals',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref
                              .read(approvalsProvider.notifier)
                              .fetchPending(),
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
                    subtitle: 'No leads are waiting for approval.',
                  );
                }
                return ListView.separated(
                  itemCount: leads.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return _ApprovalCard(lead: leads[index]);
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

  @override
  void initState() {
    super.initState();
    _fetchAvailableRooms();
  }

  Future<void> _fetchAvailableRooms() async {
    final ghId = widget.lead.preferredGuestHouse?.id;
    if (ghId == null) return;
    setState(() => _loadingRooms = true);
    try {
      final raw = await ApiService().getAvailability(
        ghId,
        widget.lead.checkIn.toIso8601String(),
        widget.lead.checkOut.toIso8601String(),
      );
      final rooms = raw
          .map((e) => RoomModel.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _availableRooms = rooms;
          _loadingRooms = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  Future<void> _approve() async {
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a room first'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final selectedRoom = _availableRooms
        .firstWhere((r) => r.id == _selectedRoomId);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Approve Lead',
      message:
          'Approve and assign Room ${selectedRoom.roomNumber} to ${widget.lead.guestName}?',
      confirmLabel: 'Approve',
    );
    if (confirmed != true) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(approvalsProvider.notifier)
          .approveLead(widget.lead.id, _selectedRoomId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lead approved and booking created'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reject Lead',
      message:
          'Are you sure you want to reject the lead for ${widget.lead.guestName}? This cannot be undone.',
      confirmLabel: 'Reject',
      isDangerous: true,
    );
    if (confirmed != true) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(approvalsProvider.notifier)
          .rejectLead(widget.lead.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lead rejected'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          lead.guestName.isNotEmpty
                              ? lead.guestName[0].toUpperCase()
                              : 'G',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lead.guestName,
                              style: AppTextStyles.cardTitle),
                          Text(
                            'Lead #${lead.id.length > 6 ? lead.id.substring(lead.id.length - 6) : lead.id}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StatusChip(status: lead.status),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Info grid
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                _InfoChip(
                    icon: Icons.phone_outlined, text: lead.phone),
                _InfoChip(
                    icon: Icons.email_outlined, text: lead.email),
                _InfoChip(
                  icon: Icons.home_outlined,
                  text: lead.preferredGuestHouse?.name ??
                      'Not specified',
                ),
                _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  text:
                      'Check-in: ${_dateFormat.format(lead.checkIn)}',
                ),
                _InfoChip(
                  icon: Icons.calendar_month_outlined,
                  text:
                      'Check-out: ${_dateFormat.format(lead.checkOut)}',
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Room selection + actions
            Row(
              children: [
                Expanded(
                  child: _loadingRooms
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Text('Loading available rooms...',
                                style: AppTextStyles.bodySmall),
                          ],
                        )
                      : _availableRooms.isEmpty
                          ? Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: AppColors.error,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(
                                    'No rooms available for these dates',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(
                                            color: AppColors.error)),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.border),
                                borderRadius:
                                    BorderRadius.circular(8),
                                color: AppColors.surfaceVariant,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRoomId,
                                  hint: Text(
                                      'Select a room to assign',
                                      style: AppTextStyles.bodySmall),
                                  style: AppTextStyles.bodyMedium,
                                  items: _availableRooms.map((r) {
                                    return DropdownMenuItem(
                                      value: r.id,
                                      child: Text(
                                        'Room ${r.roomNumber}${r.guestHouse != null ? ' — ${r.guestHouse!.name}' : ''}',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(
                                      () => _selectedRoomId = val),
                                ),
                              ),
                            ),
                ),
                const SizedBox(width: 16),
                if (_isProcessing)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary),
                  )
                else ...[
                  OutlinedButton.icon(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedRoomId == null ||
                            _availableRooms.isEmpty
                        ? null
                        : _approve,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve & Assign Room'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
