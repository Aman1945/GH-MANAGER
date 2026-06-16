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

  factory LoadingShimmer.card() {
    return const _CardShimmer();
  }

  factory LoadingShimmer.table({int rows = 5}) {
    return _TableShimmer(rows: rows);
  }

  factory LoadingShimmer.metric() {
    return const _MetricShimmer();
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class _CardShimmer extends LoadingShimmer {
  const _CardShimmer()
      : super(width: double.infinity, height: 100, borderRadius: 12);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: Colors.white,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 28,
                    width: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: 120,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
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
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: Colors.white,
      child: Column(
        children: List.generate(rows, (index) {
          return Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(height: 14, color: const Color(0xFFE5E7EB)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(height: 14, color: const Color(0xFFE5E7EB)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(height: 14, color: const Color(0xFFE5E7EB)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: Container(height: 20, color: const Color(0xFFE5E7EB)),
                ),
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
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: Colors.white,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
      ),
    );
  }
}
