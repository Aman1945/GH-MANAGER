import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/leads_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../widgets/app_header.dart';

// Legacy screen — kept for backward compatibility with /admin/create-lead route.
// New users should use AdminLeads (/admin/leads) which includes a create dialog.
class AdminCreateLead extends ConsumerStatefulWidget {
  const AdminCreateLead({super.key});

  @override
  ConsumerState<AdminCreateLead> createState() => _AdminCreateLeadState();
}

class _AdminCreateLeadState extends ConsumerState<AdminCreateLead> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;
  String? _selectedGuestHouseId;
  bool _isSubmitting = false;

  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
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

    if (picked != null) {
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
    if (_selectedGuestHouseId == null) {
      _showSnack('Please select a guest house');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(leadsProvider.notifier).createLead({
        'guestName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'checkIn': _checkIn!.toIso8601String(),
        'checkOut': _checkOut!.toIso8601String(),
        'preferredGuestHouseId': _selectedGuestHouseId,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lead created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        setState(() {
          _checkIn = null;
          _checkOut = null;
          _selectedGuestHouseId = null;
        });
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

    return Column(
      children: [
        const AppHeader(
          title: 'Create Lead',
          subtitle: 'Submit a new guest inquiry',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Guest Name',
                          prefixIcon: Icon(Icons.person_outlined,
                              size: 18, color: AppColors.textMuted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Guest name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          prefixIcon: Icon(Icons.phone_outlined,
                              size: 18, color: AppColors.textMuted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone is required';
                          }
                          if (!RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined,
                              size: 18, color: AppColors.textMuted),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$')
                              .hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(context, true),
                              borderRadius: BorderRadius.circular(10),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Check-In Date',
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
                                      : AppTextStyles.bodyMedium
                                          .copyWith(
                                              color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(context, false),
                              borderRadius: BorderRadius.circular(10),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Check-Out Date',
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
                                      : AppTextStyles.bodyMedium
                                          .copyWith(
                                              color: AppColors.textMuted),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      guestHousesAsync.when(
                        loading: () =>
                            const LinearProgressIndicator(
                                color: AppColors.primary),
                        error: (e, _) => Text(
                          'Failed to load guest houses',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                        data: (guestHouses) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedGuestHouseId,
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
                                setState(() => _selectedGuestHouseId = val),
                            validator: (v) =>
                                v == null ? 'Please select a guest house' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Submit Lead'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
