import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';

class LoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  factory LoadingShimmer.card() => const _CardShimmer();

  factory LoadingShimmer.table({int rows = 5}) => _TableShimmer(rows: rows);

  factory LoadingShimmer.metric() => const _MetricShimmer();

  static const _base = Color(0xFFE2E8F0);
  static const _highlight = Color(0xFFF0F4F9);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _base,
      highlightColor: _highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class _CardShimmer extends LoadingShimmer {
  const _CardShimmer()
      : super(width: double.infinity, height: 120, borderRadius: 12);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF0F4F9),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    width: 24, height: 24, color: Colors.white),
                const SizedBox(width: 8),
                Container(width: 100, height: 12, color: Colors.white),
                const Spacer(),
                Container(width: 40, height: 20, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: 80, height: 28, color: Colors.white),
            const SizedBox(height: 6),
            Container(width: 120, height: 12, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _TableShimmer extends LoadingShimmer {
  final int rows;

  const _TableShimmer({required this.rows})
      : super(width: double.infinity, height: 52, borderRadius: 0);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF0F4F9),
      child: Column(
        children: List.generate(rows, (index) {
          return Container(
            height: 56,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0), shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(
                    flex: 3,
                    child: Container(height: 12, color: const Color(0xFFE2E8F0))),
                const SizedBox(width: 16),
                Expanded(
                    flex: 2,
                    child: Container(height: 12, color: const Color(0xFFE2E8F0))),
                const SizedBox(width: 16),
                Container(
                    width: 60,
                    height: 22,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20))),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _MetricShimmer extends LoadingShimmer {
  const _MetricShimmer()
      : super(width: double.infinity, height: 100, borderRadius: 12);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF0F4F9),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
