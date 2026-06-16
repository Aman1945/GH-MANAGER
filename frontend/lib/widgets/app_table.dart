import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../config/theme.dart';
import 'empty_state.dart';
import 'loading_shimmer.dart';

class AppTable extends StatelessWidget {
  final List<DataColumn2> columns;
  final List<DataRow2> rows;
  final String searchHint;
  final String searchValue;
  final ValueChanged<String> onSearch;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget? headerAction;

  const AppTable({
    super.key,
    required this.columns,
    required this.rows,
    this.searchHint = 'Search...',
    this.searchValue = '',
    required this.onSearch,
    this.isLoading = false,
    this.emptyTitle = 'No data found',
    this.emptySubtitle = 'There are no records to display.',
    this.headerAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search + action header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    onChanged: onSearch,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.borderFocus, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      isDense: true,
                    ),
                  ),
                ),
                const Spacer(),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),

          // Table body
          Expanded(
            child: isLoading
                ? LoadingShimmer.table(rows: 5)
                : rows.isEmpty
                    ? EmptyState(
                        icon: Icons.inbox_rounded,
                        title: emptyTitle,
                        subtitle: emptySubtitle,
                      )
                    : DataTable2(
                        columns: columns,
                        rows: rows,
                        headingRowHeight: 44,
                        dataRowHeight: 52,
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.surfaceVariant,
                        ),
                        headingTextStyle: AppTextStyles.tableHeader,
                        dataTextStyle: AppTextStyles.tableText,
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        horizontalMargin: 16,
                        columnSpacing: 16,
                        dividerThickness: 0,
                      ),
          ),
        ],
      ),
    );
  }
}
