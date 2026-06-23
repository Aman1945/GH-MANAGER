import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../providers/bookings_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/confirmation_dialog.dart';

class BMBookings extends ConsumerStatefulWidget {
  const BMBookings({super.key});

  @override
  ConsumerState<BMBookings> createState() => _BMBookingsState();
}

class _BMBookingsState extends ConsumerState<BMBookings> {
  String _searchQuery = '';
  String _statusFilter = 'ALL';
  final _dateFormat = DateFormat('dd MMM yyyy');

  List<BookingModel> _filtered(List<BookingModel> bookings) {
    return bookings.where((b) {
      final nameMatch = _searchQuery.isEmpty ||
          b.guestName.toLowerCase().contains(_searchQuery.toLowerCase());
      final statusMatch =
          _statusFilter == 'ALL' || b.bookingStatus == _statusFilter;
      return nameMatch && statusMatch;
    }).toList();
  }

  Future<void> _markPaid(BookingModel b) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Mark Payment',
      message: 'Mark booking for ${b.guestName} as paid? Room will be set to Occupied.',
      confirmLabel: 'Mark Paid',
    );
    if (confirmed != true) return;
    try {
      await ref.read(bookingsProvider.notifier).markPayment(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment marked — room is now Occupied'),
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

  Future<void> _checkout(BookingModel b) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Guest Checkout',
      message: 'Checkout ${b.guestName} from Room ${b.roomNumber ?? ''}? Room will be freed.',
      confirmLabel: 'Checkout',
    );
    if (confirmed != true) return;
    try {
      await ref.read(bookingsProvider.notifier).checkout(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Guest checked out successfully'),
          backgroundColor: AppColors.info,
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
    final bookingsAsync = ref.watch(bookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Search + filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                fillColor: AppColors.surfaceVariant,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['ALL', 'CONFIRMED', 'COMPLETED'].map((s) {
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
                    side: BorderSide(color: isActive ? AppColors.primary : AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: bookingsAsync.when(
              loading: () => Padding(padding: const EdgeInsets.all(16), child: LoadingShimmer.table(rows: 6)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    const Text('Failed to load bookings'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(bookingsProvider.notifier).fetchBookings(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (bookings) {
                final filtered = _filtered(bookings);
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.calendar_month_rounded,
                    title: 'No bookings found',
                    subtitle: 'Try adjusting your filters',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(bookingsProvider.notifier).fetchBookings(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _BookingCard(
                      booking: filtered[i],
                      dateFormat: _dateFormat,
                      onMarkPaid: () => _markPaid(filtered[i]),
                      onCheckout: () => _checkout(filtered[i]),
                    ),
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

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final DateFormat dateFormat;
  final VoidCallback onMarkPaid;
  final VoidCallback onCheckout;

  const _BookingCard({
    required this.booking,
    required this.dateFormat,
    required this.onMarkPaid,
    required this.onCheckout,
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(_initials(booking.guestName),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(booking.guestName,
                      style: AppTextStyles.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                if (booking.bookingStatus == 'CONFIRMED' && booking.paymentStatus == 'PENDING')
                  ElevatedButton(
                    onPressed: onMarkPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Mark Paid'),
                  )
                else if (booking.bookingStatus == 'CONFIRMED' && booking.paymentStatus == 'PAID')
                  OutlinedButton(
                    onPressed: onCheckout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Checkout'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                Row(children: [
                  const Icon(Icons.home_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${booking.guestHouseName ?? '-'} · Room ${booking.roomNumber ?? '-'}',
                    style: AppTextStyles.bodySmall,
                  )),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    '${dateFormat.format(booking.checkIn)} → ${dateFormat.format(booking.checkOut)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  StatusChip(status: booking.bookingStatus),
                  const SizedBox(width: 8),
                  StatusChip(status: booking.paymentStatus),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
