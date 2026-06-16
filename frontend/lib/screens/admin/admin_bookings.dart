import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/booking_model.dart';
import '../../providers/bookings_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/confirmation_dialog.dart';

class AdminBookings extends ConsumerStatefulWidget {
  const AdminBookings({super.key});

  @override
  ConsumerState<AdminBookings> createState() => _AdminBookingsState();
}

class _AdminBookingsState extends ConsumerState<AdminBookings> {
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
      message:
          'Mark booking for ${b.guestName} as paid? This action cannot be undone.',
      confirmLabel: 'Mark Paid',
    );
    if (confirmed != true) return;
    try {
      await ref.read(bookingsProvider.notifier).markPayment(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment marked successfully'),
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
    }
  }

  Future<void> _checkout(BookingModel b) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Guest Checkout',
      message:
          'Checkout ${b.guestName} from Room ${b.roomNumber ?? ''}? This will mark the booking as completed.',
      confirmLabel: 'Checkout',
    );
    if (confirmed != true) return;
    try {
      await ref.read(bookingsProvider.notifier).checkout(b.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Guest checked out successfully'),
            backgroundColor: AppColors.info,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsProvider);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      children: [
        AppHeader(
          title: 'Bookings',
          subtitle: 'All guest house bookings',
          actions: [
            OutlinedButton.icon(
              onPressed: () =>
                  ref.read(bookingsProvider.notifier).fetchBookings(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: bookingsAsync.when(
              loading: () => LoadingShimmer.table(rows: 8),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Failed to load bookings',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(bookingsProvider.notifier).fetchBookings(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (bookings) {
                final filtered = _filtered(bookings);
                return Column(
                  children: [
                    // Filter bar
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
                                        color: AppColors.textMuted,
                                        size: 20),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    DropdownButton<String>(
                                      value: _statusFilter,
                                      underline: const SizedBox.shrink(),
                                      style: AppTextStyles.bodyMedium,
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'ALL', child: Text('All Status')),
                                        DropdownMenuItem(
                                            value: 'CONFIRMED',
                                            child: Text('Confirmed')),
                                        DropdownMenuItem(
                                            value: 'COMPLETED',
                                            child: Text('Completed')),
                                        DropdownMenuItem(
                                            value: 'CANCELLED',
                                            child: Text('Cancelled')),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _statusFilter = v ?? 'ALL'),
                                    ),
                                    Text('${filtered.length} bookings',
                                        style: AppTextStyles.caption),
                                  ],
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
                                          color: AppColors.textMuted,
                                          size: 20),
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
                                const SizedBox(width: 12),
                                DropdownButton<String>(
                                  value: _statusFilter,
                                  underline: const SizedBox.shrink(),
                                  style: AppTextStyles.bodyMedium,
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'ALL', child: Text('All Status')),
                                    DropdownMenuItem(
                                        value: 'CONFIRMED',
                                        child: Text('Confirmed')),
                                    DropdownMenuItem(
                                        value: 'COMPLETED',
                                        child: Text('Completed')),
                                    DropdownMenuItem(
                                        value: 'CANCELLED',
                                        child: Text('Cancelled')),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => _statusFilter = v ?? 'ALL'),
                                ),
                                const Spacer(),
                                Text('${filtered.length} bookings',
                                    style: AppTextStyles.caption),
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
                                icon: Icons.calendar_month_rounded,
                                title: 'No bookings found',
                                subtitle: 'Try adjusting your filters',
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: 1020,
                                    child: _BookingsTable(
                                      bookings: filtered,
                                      dateFormat: _dateFormat,
                                      onMarkPaid: _markPaid,
                                      onCheckout: _checkout,
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

class _BookingsTable extends StatelessWidget {
  final List<BookingModel> bookings;
  final DateFormat dateFormat;
  final Future<void> Function(BookingModel) onMarkPaid;
  final Future<void> Function(BookingModel) onCheckout;

  const _BookingsTable({
    required this.bookings,
    required this.dateFormat,
    required this.onMarkPaid,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(160), // Guest Name
        1: FixedColumnWidth(160), // Guest House
        2: FixedColumnWidth(80),  // Room
        3: FixedColumnWidth(110), // Check-in
        4: FixedColumnWidth(110), // Check-out
        5: FixedColumnWidth(130), // Booking
        6: FixedColumnWidth(130), // Payment
        7: FixedColumnWidth(140), // Actions
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          children: [
            'Guest Name',
            'Guest House',
            'Room',
            'Check-in',
            'Check-out',
            'Booking',
            'Payment',
            'Actions',
          ].map((h) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Text(h.toUpperCase(),
                  style: AppTextStyles.tableHeader),
            );
          }).toList(),
        ),
        ...bookings.map((b) {
          return TableRow(
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppColors.border)),
            ),
            children: [
              _TCell(
                child: Text(b.guestName,
                    style: AppTextStyles.tableText
                        .copyWith(fontWeight: FontWeight.w500)),
              ),
              _TCell(
                child: Text(b.guestHouseName ?? '-',
                    style: AppTextStyles.tableText),
              ),
              _TCell(
                child: Text(b.roomNumber ?? '-',
                    style: AppTextStyles.tableText),
              ),
              _TCell(
                child: Text(dateFormat.format(b.checkIn),
                    style: AppTextStyles.tableText),
              ),
              _TCell(
                child: Text(dateFormat.format(b.checkOut),
                    style: AppTextStyles.tableText),
              ),
              _TCell(
                  child: StatusChip(status: b.bookingStatus)),
              _TCell(
                  child: StatusChip(status: b.paymentStatus)),
              _TCell(
                child: _ActionCell(
                  booking: b,
                  onMarkPaid: () => onMarkPaid(b),
                  onCheckout: () => onCheckout(b),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _TCell extends StatelessWidget {
  final Widget child;

  const _TCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}

class _ActionCell extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onMarkPaid;
  final VoidCallback onCheckout;

  const _ActionCell({
    required this.booking,
    required this.onMarkPaid,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    if (booking.bookingStatus == 'CONFIRMED' &&
        booking.paymentStatus == 'PENDING') {
      return ElevatedButton(
        onPressed: onMarkPaid,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: AppTextStyles.caption
              .copyWith(fontWeight: FontWeight.w600),
        ),
        child: const Text('Mark Paid'),
      );
    }
    if (booking.bookingStatus == 'CONFIRMED' &&
        booking.paymentStatus == 'PAID') {
      return OutlinedButton(
        onPressed: onCheckout,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.info,
          side: const BorderSide(color: AppColors.info),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: AppTextStyles.caption
              .copyWith(fontWeight: FontWeight.w600),
        ),
        child: const Text('Checkout'),
      );
    }
    return const SizedBox.shrink();
  }
}
