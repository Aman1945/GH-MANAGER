import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/rooms_provider.dart';
import '../models/maintenance_model.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/confirmation_dialog.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      if (user != null && user.role == 'GH_MANAGER') {
        ref.read(roomsProvider.notifier).fetchRooms(guestHouseId: user.guestHouseId);
      }
    });
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReportIssueSheet(),
    );
  }

  Future<void> _resolveRequest(MaintenanceModel request) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Resolve Issue',
      message: 'Mark maintenance issue for Room ${request.room?.roomNumber ?? ''} as resolved?',
      confirmLabel: 'Resolve',
    );
    if (confirmed != true) return;
    try {
      await ref.read(maintenanceProvider.notifier).resolveRequest(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Issue marked as resolved. Room is now AVAILABLE.'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(maintenanceProvider);
    final user = ref.watch(authProvider).user;
    final isGHManager = user?.role == 'GH_MANAGER';
    final canResolve = user?.role == 'ADMIN' || user?.role == 'BOOKING_MANAGER';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: listAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(4, (_) => Padding(
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
              Text('Failed to load maintenance requests', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(maintenanceProvider.notifier).fetchRequests(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'No issues reported',
              subtitle: isGHManager
                  ? 'Tap the button below to report a new issue.'
                  : 'All guest house rooms are in perfect condition.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(maintenanceProvider.notifier).fetchRequests(),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16, 8, 16, isGHManager ? 96 : 24),
              itemCount: requests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                final isClosed = request.status == 'RESOLVED';

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
                      // Card header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.warningLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.build_outlined, color: AppColors.warning, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Room ${request.room?.roomNumber ?? 'Unknown'}',
                                      style: AppTextStyles.cardTitle),
                                  if (request.guestHouse != null)
                                    Text(request.guestHouse!.name, style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            StatusChip(status: request.status),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),

                      // Description
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(request.description, style: AppTextStyles.bodyMedium),
                        ),
                      ),

                      if (request.guestName != null && request.guestName!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Row(children: [
                            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text('Guest: ${request.guestName}', style: AppTextStyles.caption),
                          ]),
                        ),
                      ],

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('By: ${request.reportedBy ?? 'Staff'}', style: AppTextStyles.caption),
                                  Text(_dateFormat.format(request.createdAt),
                                      style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            if (canResolve && !isClosed)
                              TextButton.icon(
                                onPressed: () => _resolveRequest(request),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: const Text('Mark Resolved', style: TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isGHManager
          ? FloatingActionButton.extended(
              onPressed: _showReportSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report Issue', style: TextStyle(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}

class _ReportIssueSheet extends ConsumerStatefulWidget {
  const _ReportIssueSheet();

  @override
  ConsumerState<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends ConsumerState<_ReportIssueSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String? _selectedRoomId;
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedRoomId == null) {
      if (_selectedRoomId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a room'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(maintenanceProvider.notifier).createRequest({
        'roomId': _selectedRoomId,
        'description': _descCtrl.text.trim(),
      });
      // ignore: unused_result
      ref.refresh(roomsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maintenance issue reported successfully'),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomsProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Report Room Issue', style: AppTextStyles.pageTitle.copyWith(fontSize: 20)),
            const SizedBox(height: 4),
            Text('Select a room and describe the maintenance required.', style: AppTextStyles.bodySmall),
            const SizedBox(height: 20),

            Text('Room', style: AppTextStyles.label),
            const SizedBox(height: 6),
            roomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => Text('Failed to load rooms', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              data: (rooms) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.surfaceVariant,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedRoomId,
                    hint: Text('Select a room', style: AppTextStyles.bodySmall),
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    items: rooms.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text('Room ${r.roomNumber} (${r.status})'),
                    )).toList(),
                    onChanged: _submitting ? null : (val) => setState(() => _selectedRoomId = val),
                    validator: (v) => v == null ? 'Room is required' : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Issue Description', style: AppTextStyles.label),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              enabled: !_submitting,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. AC remote not working, leak in washroom',
                alignLabelWithHint: true,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please describe the issue' : null,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
