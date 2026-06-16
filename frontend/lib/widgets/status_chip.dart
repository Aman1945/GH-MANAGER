import 'package:flutter/material.dart';
import '../config/theme.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  ({Color bg, Color text}) _colors() {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return (
          bg: AppColors.statusAvailableBg,
          text: AppColors.statusAvailableText
        );
      case 'BLOCKED':
        return (
          bg: AppColors.statusBlockedBg,
          text: AppColors.statusBlockedText
        );
      case 'OCCUPIED':
        return (
          bg: AppColors.statusOccupiedBg,
          text: AppColors.statusOccupiedText
        );
      case 'PENDING':
        return (
          bg: AppColors.statusPendingBg,
          text: AppColors.statusPendingText
        );
      case 'CONFIRMED':
        return (
          bg: AppColors.statusConfirmedBg,
          text: AppColors.statusConfirmedText
        );
      case 'REJECTED':
        return (
          bg: AppColors.statusRejectedBg,
          text: AppColors.statusRejectedText
        );
      case 'COMPLETED':
        return (
          bg: AppColors.statusCompletedBg,
          text: AppColors.statusCompletedText
        );
      case 'PAID':
        return (bg: AppColors.statusPaidBg, text: AppColors.statusPaidText);
      case 'CANCELLED':
        return (
          bg: AppColors.statusCancelledBg,
          text: AppColors.statusCancelledText
        );
      default:
        return (bg: AppColors.statusCancelledBg, text: AppColors.textMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    final isSmall = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 6 : 10, vertical: isSmall ? 2 : 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 3 : 4,
            height: isSmall ? 3 : 4,
            decoration: BoxDecoration(
              color: colors.text,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isSmall ? 4 : 6),
          Text(
            status,
            style: TextStyle(
              color: colors.text,
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
