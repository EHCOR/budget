// widgets/date_range_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${DateFormat.MMMd().format(provider.startDate)} - ${DateFormat.MMMd().format(provider.endDate)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () => _selectCustomRange(context, provider),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickOption(
                        context,
                        'Last 7 Days',
                            () => _setLastDays(provider, 7),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOption(
                        context,
                        'Last 30 Days',
                            () => _setLastDays(provider, 30),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOption(
                        context,
                        'This Month',
                            () => _setThisMonth(provider),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOption(
                        context,
                        'Last Month',
                            () => _setLastMonth(provider),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOption(
                        context,
                        'All Time',
                            () => _setAllTime(provider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickOption(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _setLastDays(TransactionProvider provider, int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    provider.setDateRange(start, end);
  }

  void _setThisMonth(TransactionProvider provider) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    provider.setDateRange(start, now);
  }

  void _setLastMonth(TransactionProvider provider) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0);
    provider.setDateRange(start, end);
  }

  void _setAllTime(TransactionProvider provider) {
    if (provider.transactions.isEmpty) return;

    final dates = provider.transactions.map((t) => t.date).toList();
    dates.sort();
    provider.setDateRange(dates.first, DateTime.now());
  }

  Future<void> _selectCustomRange(BuildContext context, TransactionProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: provider.startDate,
        end: provider.endDate,
      ),
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }
}