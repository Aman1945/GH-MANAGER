import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/leads_provider.dart';
import '../../providers/rooms_provider.dart';

class AdminCreateLead extends ConsumerStatefulWidget {
  const AdminCreateLead({super.key});

  @override
  ConsumerState<AdminCreateLead> createState() => _AdminCreateLeadState();
}

class _AdminCreateLeadState extends ConsumerState<AdminCreateLead> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
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
    _notesCtrl.dispose();
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
          if (_checkOut != null && !_checkOut!.isAfter(picked)) _checkOut = null;
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_checkIn == null) { _showSnack('Please select check-in date'); return; }
    if (_checkOut == null) { _showSnack('Please select check-out date'); return; }
    if (_selectedGhId == null) { _showSnack('Please select a guest house'); return; }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(leadsProvider.notifier).createLead({
        'guestName': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'checkIn': _checkIn!.toIso8601String(),
        'checkOut': _checkOut!.toIso8601String(),
        'preferredGuestHouseId': _selectedGhId,
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lead created successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        context.go('/admin/leads');
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final guestHousesAsync = ref.watch(guestHousesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Back header
          Container(
            color: AppColors.surface,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/admin/leads'),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Guest Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline, size: 18, color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    _gap(),
                    _field('Phone *'),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '10-digit phone',
                        prefixIcon: Icon(Icons.phone_outlined, size: 18, color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) return '10 digits required';
                        return null;
                      },
                    ),
                    _gap(),
                    _field('Email *'),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'guest@example.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 18, color: AppColors.textMuted),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    _gap(),
                    _field('Guest House *'),
                    guestHousesAsync.when(
                      loading: () => const LinearProgressIndicator(color: AppColors.primary),
                      error: (_, __) => Text('Failed to load', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                      data: (ghs) => DropdownButtonFormField<String>(
                        value: _selectedGhId,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.home_outlined, size: 18, color: AppColors.textMuted),
                        ),
                        hint: Text('Select guest house', style: AppTextStyles.bodySmall),
                        items: ghs.map((gh) => DropdownMenuItem(value: gh.id, child: Text(gh.name))).toList(),
                        onChanged: (val) => setState(() => _selectedGhId = val),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                    _gap(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _field('Check-in *'),
                              _DateTile(
                                label: _checkIn != null ? _dateFormat.format(_checkIn!) : 'Select date',
                                icon: Icons.calendar_today_outlined,
                                onTap: () => _pickDate(true),
                                hasValue: _checkIn != null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _field('Check-out *'),
                              _DateTile(
                                label: _checkOut != null ? _dateFormat.format(_checkOut!) : 'Select date',
                                icon: Icons.calendar_month_outlined,
                                onTap: () => _pickDate(false),
                                hasValue: _checkOut != null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    _gap(),
                    _field('Notes (optional)'),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Any additional info...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create Lead', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: AppTextStyles.label));

  Widget _gap() => const SizedBox(height: 16);
}

class _DateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasValue;

  const _DateTile({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.hasValue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
