import 'package:flutter/material.dart';
import '../config/theme.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  ({Color bg, Color text}) _colors() {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
      case 'CONFIRMED':
      case 'PAID':
      case 'COMPLETED':
        return (bg: AppColors.statusAvailableBg, text: AppColors.statusAvailableText);
      case 'PENDING':
        return (bg: AppColors.statusPendingBg, text: AppColors.statusPendingText);
      case 'BLOCKED':
        return (bg: AppColors.statusBlockedBg, text: AppColors.statusBlockedText);
      case 'OCCUPIED':
      case 'REJECTED':
        return (bg: AppColors.statusOccupiedBg, text: AppColors.statusOccupiedText);
      case 'MAINTENANCE':
        return (bg: AppColors.statusMaintenanceBg, text: AppColors.statusMaintenanceText);
      case 'OPEN':
        return (bg: AppColors.statusPendingBg, text: AppColors.statusPendingText);
      case 'RESOLVED':
        return (bg: AppColors.statusAvailableBg, text: AppColors.statusAvailableText);
      default:
        return (bg: AppColors.statusCancelledBg, text: AppColors.statusCancelledText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: colors.text,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
