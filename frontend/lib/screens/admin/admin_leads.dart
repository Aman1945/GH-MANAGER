import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/lead_model.dart';
import '../../providers/leads_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/status_chip.dart';

class AdminLeads extends ConsumerStatefulWidget {
  const AdminLeads({super.key});

  @override
  ConsumerState<AdminLeads> createState() => _AdminLeadsState();
}

class _AdminLeadsState extends ConsumerState<AdminLeads> {
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  final _dateFormat = DateFormat('dd MMM yy');

  List<LeadModel> _filtered(List<LeadModel> leads) {
    return leads.where((l) {
      final nameMatch = _searchQuery.isEmpty ||
          l.guestName.toLowerCase().contains(_searchQuery.toLowerCase());
      final statusMatch =
          _statusFilter == 'ALL' || l.status.toUpperCase() == _statusFilter;
      return nameMatch && statusMatch;
    }).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  void _showImportEmailSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Import from Email', style: AppTextStyles.cardTitle.copyWith(fontSize: 18)),
              const SizedBox(height: 6),
              Text('Paste the email body below to create a lead from it.', style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Paste email text here...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lead imported'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    ref.read(leadsProvider.notifier).fetchLeads();
                  },
                  child: const Text('Import Lead'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(leadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with pill buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Leads', style: AppTextStyles.pageTitle),
                ),
                // Import Email pill
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showImportEmailSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text('Import Email',
                                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // New Lead pill
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/admin/create-lead'),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('New Lead',
                                style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['ALL', 'PENDING', 'APPROVED', 'REJECTED'].map((s) {
                final isActive = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s == 'ALL' ? 'All' : s[0] + s.substring(1).toLowerCase()),
                    selected: isActive,
                    onSelected: (_) => setState(() => _statusFilter = s),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primarySurface,
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: leadsAsync.when(
              loading: () => Padding(
                padding: const EdgeInsets.all(16),
                child: LoadingShimmer.table(rows: 5),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    const Text('Failed to load leads'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(leadsProvider.notifier).fetchLeads(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (leads) {
                final filtered = _filtered(leads);
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No leads found',
                    subtitle: 'Try adjusting your search or filters.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(leadsProvider.notifier).fetchLeads(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final lead = filtered[i];
                      return _LeadCard(lead: lead, dateFormat: _dateFormat, timeAgo: _timeAgo);
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

class _LeadCard extends StatelessWidget {
  final LeadModel lead;
  final DateFormat dateFormat;
  final String Function(DateTime) timeAgo;

  const _LeadCard({
    required this.lead,
    required this.dateFormat,
    required this.timeAgo,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'G';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
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
                  child: Text(lead.guestName,
                      style: AppTextStyles.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                StatusChip(status: lead.status),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(lead.phone, style: AppTextStyles.bodySmall),
                    const Spacer(),
                    const Icon(Icons.home_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        lead.preferredGuestHouse?.name ?? 'No GH',
                        style: AppTextStyles.bodySmall,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      '${dateFormat.format(lead.checkIn)} → ${dateFormat.format(lead.checkOut)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    const Spacer(),
                    Text(timeAgo(lead.createdAt), style: AppTextStyles.caption),
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
