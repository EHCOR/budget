// widgets/date_range_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';

class DateRangeSelector extends StatelessWidget {
  final bool showTrendsOptions;

  const DateRangeSelector({
    super.key,
    this.showTrendsOptions = false,
  });

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
                        'Last 3 Months',
                        () => _setLastThreeMonths(provider),
                      ),
                      if (showTrendsOptions) ...[
                        const SizedBox(width: 8),
                        _buildQuickOption(
                          context,
                          'Last 6 Months',
                          () => _setLastMonths(provider, 6),
                        ),
                        const SizedBox(width: 8),
                        _buildQuickOption(
                          context,
                          'Last 1 Year',
                          () => _setLastMonths(provider, 12),
                        ),
                      ],
                      const SizedBox(width: 8),
                      _buildQuickOption(
                        context,
                        'All Time',
                        () => _setAllTime(provider),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickOption(
                        context,
                        'Custom',
                        () => _selectCustomRange(context, provider),
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

  void _setLastThreeMonths(TransactionProvider provider) {
    final now = DateTime.now();
    // Start from 3 months ago (beginning of that month)
    final start = DateTime(now.year, now.month - 2, 1);
    // End at current date
    provider.setDateRange(start, now);
  }

  void _setLastMonths(TransactionProvider provider, int months) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - (months - 1), 1);
    provider.setDateRange(start, now);
  }

  void _setAllTime(TransactionProvider provider) {
    if (provider.transactions.isEmpty) return;

    final dates = provider.transactions.map((t) => t.date).toList();
    dates.sort();
    provider.setDateRange(dates.first, DateTime.now());
  }

  Future<void> _selectCustomRange(BuildContext context, TransactionProvider provider) async {
    final DateTimeRange? picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return CustomDateRangePickerDialog(
          initialDateRange: DateTimeRange(
            start: provider.startDate,
            end: provider.endDate,
          ),
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }
}

class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange initialDateRange;

  const CustomDateRangePickerDialog({super.key, required this.initialDateRange});

  @override
  State<CustomDateRangePickerDialog> createState() => _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState extends State<CustomDateRangePickerDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange.start;
    _endDate = widget.initialDateRange.end;
    _updateDateText();
  }

  void _updateDateText() {
    _startDateController.text = DateFormat.yMMMd().format(_startDate);
    _endDateController.text = DateFormat.yMMMd().format(_endDate);
  }

  Future<void> _showCalendar() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _updateDateText();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Date Range',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: _showCalendar,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _startDateController,
                    decoration: const InputDecoration(labelText: 'Start Date'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _endDateController,
                    decoration: const InputDecoration(labelText: 'End Date'),
                    readOnly: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, DateTimeRange(start: _startDate, end: _endDate));
                    },
                    child: const Text('OK'),
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