import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/lead_model.dart';
import '../../providers/leads_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';

class AdminLeads extends ConsumerStatefulWidget {
  const AdminLeads({super.key});

  @override
  ConsumerState<AdminLeads> createState() => _AdminLeadsState();
}

class _AdminLeadsState extends ConsumerState<AdminLeads> {
  String _searchQuery = '';
  final _dateFormat = DateFormat('dd MMM yy');

  List<LeadModel> _filtered(List<LeadModel> leads) {
    if (_searchQuery.isEmpty) return leads;
    final q = _searchQuery.toLowerCase();
    return leads
        .where((l) => l.guestName.toLowerCase().contains(q))
        .toList();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateLeadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(leadsProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      children: [
        AppHeader(
          title: 'Leads',
          subtitle: 'Manage all guest inquiries',
          actions: [
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Create Lead'),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: leadsAsync.when(
              loading: () => LoadingShimmer.table(rows: 8),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load leads',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(leadsProvider.notifier).fetchLeads(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (leads) {
                final filtered = _filtered(leads);
                return Column(
                  children: [
                    // Search + action bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  onChanged: (v) =>
                                      setState(() => _searchQuery = v),
                                  style: AppTextStyles.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: 'Search by guest name...',
                                    prefixIcon: const Icon(Icons.search,
                                        color: AppColors.textMuted, size: 20),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: AppColors.borderFocus,
                                          width: 2),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                    isDense: true,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${filtered.length} leads',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 280,
                                  child: TextField(
                                    onChanged: (v) =>
                                        setState(() => _searchQuery = v),
                                    style: AppTextStyles.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: 'Search by guest name...',
                                      prefixIcon: const Icon(Icons.search,
                                          color: AppColors.textMuted, size: 20),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.border),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                            color: AppColors.borderFocus,
                                            width: 2),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.surfaceVariant,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${filtered.length} leads',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                    ),

                    // Table
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: filtered.isEmpty
                            ? EmptyState(
                                icon: Icons.person_search_rounded,
                                title: 'No leads found',
                                subtitle: leads.isEmpty
                                    ? 'Create the first lead to get started'
                                    : 'No leads match your search',
                                actionLabel: leads.isEmpty ? 'Create Lead' : null,
                                onAction: leads.isEmpty ? _showCreateDialog : null,
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 1050,
                                    child: _LeadsTable(
                                      leads: filtered,
                                      dateFormat: _dateFormat,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LeadsTable extends StatelessWidget {
  final List<LeadModel> leads;
  final DateFormat dateFormat;

  const _LeadsTable({required this.leads, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(160), // Guest Name
        1: FixedColumnWidth(130), // Phone
        2: FixedColumnWidth(200), // Email
        3: FixedColumnWidth(160), // Preferred GH
        4: FixedColumnWidth(110), // Check-in
        5: FixedColumnWidth(110), // Check-out
        6: FixedColumnWidth(130), // Status
        7: FixedColumnWidth(110), // Created
      },
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          children: [
            'Guest Name',
            'Phone',
            'Email',
            'Preferred GH',
            'Check-in',
            'Check-out',
            'Status',
            'Created',
          ].map((h) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Text(h.toUpperCase(), style: AppTextStyles.tableHeader),
            );
          }).toList(),
        ),
        // Data rows
        ...leads.map((lead) {
          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            children: [
              _Cell(
                child: Text(lead.guestName,
                    style: AppTextStyles.tableText
                        .copyWith(fontWeight: FontWeight.w500)),
              ),
              _Cell(child: Text(lead.phone, style: AppTextStyles.tableText)),
              _Cell(child: Text(lead.email, style: AppTextStyles.tableText)),
              _Cell(
                child: Text(
                    lead.preferredGuestHouse?.name ?? '-',
                    style: AppTextStyles.tableText),
              ),
              _Cell(
                child: Text(dateFormat.format(lead.checkIn),
                    style: AppTextStyles.tableText),
              ),
              _Cell(
                child: Text(dateFormat.format(lead.checkOut),
                    style: AppTextStyles.tableText),
              ),
              _Cell(child: StatusChip(status: lead.status)),
              _Cell(
                child: Text(dateFormat.format(lead.createdAt),
                    style: AppTextStyles.caption),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final Widget child;

  const _Cell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 8 : 16, vertical: isMobile ? 8 : 14),
      child: child,
    );
  }
}

// ------ Create Lead Dialog ------

class _CreateLeadDialog extends ConsumerStatefulWidget {
  const _CreateLeadDialog();

  @override
  ConsumerState<_CreateLeadDialog> createState() => _CreateLeadDialogState();
}

class _CreateLeadDialogState extends ConsumerState<_CreateLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  DateTime? _checkIn;
  DateTime? _checkOut;
  String? _selectedGhId;
  bool _isSubmitting = false;
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final initial = isCheckIn
        ? (_checkIn ?? now)
        : (_checkOut ?? (_checkIn ?? now).add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && !_checkOut!.isAfter(picked)) {
            _checkOut = null;
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkIn == null) {
      _showSnack('Please select check-in date');
      return;
    }
    if (_checkOut == null) {
      _showSnack('Please select check-out date');
      return;
    }
    if (_selectedGhId == null) {
      _showSnack('Please select a guest house');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(leadsProvider.notifier).createLead({
        'guestName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'checkIn': _checkIn!.toIso8601String(),
        'checkOut': _checkOut!.toIso8601String(),
        'preferredGuestHouseId': _selectedGhId,
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lead created successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final guestHousesAsync = ref.watch(guestHousesProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Create New Lead',
                    style: isMobile
                        ? AppTextStyles.sectionTitle.copyWith(fontSize: 18)
                        : AppTextStyles.sectionTitle,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Fill in guest details to submit a new inquiry',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Name + Phone
                        isMobile
                            ? Column(
                                children: [
                                  TextFormField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Guest Name',
                                      prefixIcon: Icon(Icons.person_outline,
                                          size: 18, color: AppColors.textMuted),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      labelText: 'Phone',
                                      prefixIcon: Icon(Icons.phone_outlined,
                                          size: 18, color: AppColors.textMuted),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (!RegExp(r'^\d{10}$')
                                          .hasMatch(v.trim())) {
                                        return '10 digits required';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nameCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Guest Name',
                                        prefixIcon: Icon(Icons.person_outline,
                                            size: 18, color: AppColors.textMuted),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      decoration: const InputDecoration(
                                        labelText: 'Phone',
                                        prefixIcon: Icon(Icons.phone_outlined,
                                            size: 18, color: AppColors.textMuted),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (!RegExp(r'^\d{10}$')
                                            .hasMatch(v.trim())) {
                                          return '10 digits required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),

                        // Row 2: Email + Guest House
                        isMobile
                            ? Column(
                                children: [
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      prefixIcon: Icon(Icons.email_outlined,
                                          size: 18, color: AppColors.textMuted),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Invalid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  guestHousesAsync.when(
                                    loading: () => const LinearProgressIndicator(),
                                    error: (_, __) => const Text('Failed to load',
                                        style: TextStyle(
                                            color: AppColors.error, fontSize: 13)),
                                    data: (guestHouses) => DropdownButtonFormField<
                                        String>(
                                      initialValue: _selectedGhId,
                                      decoration: const InputDecoration(
                                        labelText: 'Preferred Guest House',
                                        prefixIcon: Icon(Icons.home_outlined,
                                            size: 18,
                                            color: AppColors.textMuted),
                                      ),
                                      items: guestHouses.map((gh) {
                                        return DropdownMenuItem(
                                          value: gh.id,
                                          child: Text(gh.name,
                                              style: AppTextStyles.bodyMedium),
                                        );
                                      }).toList(),
                                      onChanged: (val) =>
                                          setState(() => _selectedGhId = val),
                                      validator: (v) =>
                                          v == null ? 'Required' : null,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email_outlined,
                                            size: 18, color: AppColors.textMuted),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (!v.contains('@')) {
                                          return 'Invalid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: guestHousesAsync.when(
                                      loading: () => const LinearProgressIndicator(),
                                      error: (_, __) => const Text('Failed to load',
                                          style: TextStyle(
                                              color: AppColors.error, fontSize: 13)),
                                      data: (guestHouses) => DropdownButtonFormField<
                                          String>(
                                        initialValue: _selectedGhId,
                                        decoration: const InputDecoration(
                                          labelText: 'Preferred Guest House',
                                          prefixIcon: Icon(Icons.home_outlined,
                                              size: 18,
                                              color: AppColors.textMuted),
                                        ),
                                        items: guestHouses.map((gh) {
                                          return DropdownMenuItem(
                                            value: gh.id,
                                            child: Text(gh.name,
                                                style: AppTextStyles.bodyMedium),
                                          );
                                        }).toList(),
                                        onChanged: (val) =>
                                            setState(() => _selectedGhId = val),
                                        validator: (v) =>
                                            v == null ? 'Required' : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 16),

                        // Row 3: Check-in + Check-out
                        isMobile
                            ? Column(
                                children: [
                                  InkWell(
                                    onTap: () => _pickDate(true),
                                    borderRadius: BorderRadius.circular(10),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Check-in Date',
                                        prefixIcon: Icon(
                                            Icons.calendar_today_outlined,
                                            size: 18,
                                            color: AppColors.textMuted),
                                      ),
                                      child: Text(
                                        _checkIn != null
                                            ? _dateFormat.format(_checkIn!)
                                            : 'Select date',
                                        style: _checkIn != null
                                            ? AppTextStyles.bodyMedium
                                            : AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textMuted),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  InkWell(
                                    onTap: () => _pickDate(false),
                                    borderRadius: BorderRadius.circular(10),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Check-out Date',
                                        prefixIcon: Icon(
                                            Icons.calendar_month_outlined,
                                            size: 18,
                                            color: AppColors.textMuted),
                                      ),
                                      child: Text(
                                        _checkOut != null
                                            ? _dateFormat.format(_checkOut!)
                                            : 'Select date',
                                        style: _checkOut != null
                                            ? AppTextStyles.bodyMedium
                                            : AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textMuted),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _pickDate(true),
                                      borderRadius: BorderRadius.circular(10),
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Check-in Date',
                                          prefixIcon: Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18,
                                              color: AppColors.textMuted),
                                        ),
                                        child: Text(
                                          _checkIn != null
                                              ? _dateFormat.format(_checkIn!)
                                              : 'Select date',
                                          style: _checkIn != null
                                              ? AppTextStyles.bodyMedium
                                              : AppTextStyles.bodyMedium.copyWith(
                                                  color: AppColors.textMuted),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _pickDate(false),
                                      borderRadius: BorderRadius.circular(10),
                                      child: InputDecorator(
                                        decoration: const InputDecoration(
                                          labelText: 'Check-out Date',
                                          prefixIcon: Icon(
                                              Icons.calendar_month_outlined,
                                              size: 18,
                                              color: AppColors.textMuted),
                                        ),
                                        child: Text(
                                          _checkOut != null
                                              ? _dateFormat.format(_checkOut!)
                                              : 'Select date',
                                          style: _checkOut != null
                                              ? AppTextStyles.bodyMedium
                                              : AppTextStyles.bodyMedium.copyWith(
                                                  color: AppColors.textMuted),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 28),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Text('Submit Lead'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
