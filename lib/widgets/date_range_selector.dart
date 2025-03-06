// widgets/date_range_selector.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';

enum DateRangeOption {
  sevenDays('Last 7 Days', 7),
  thirtyDays('Last 30 Days', 30),
  thisMonth('This Month', 0),
  lastMonth('Last Month', 0),
  threeMonths('Last 3 Months', 90),
  sixMonths('Last 6 Months', 180),
  ytd('Year to Date', 0),
  oneYear('Last 12 Months', 365),
  custom('Custom Range', 0);

  final String label;
  final int days;

  const DateRangeOption(this.label, this.days);
}

class DateRangeSelector extends StatefulWidget {
  final bool showTitle;
  final bool compact;

  const DateRangeSelector({
    super.key,
    this.showTitle = true,
    this.compact = false,
  });

  @override
  _DateRangeSelectorState createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  DateRangeOption _selectedOption = DateRangeOption.thirtyDays;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionData>(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle)
              Text(
                'Date Range:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            if (widget.showTitle) SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormat('MMM d, yyyy').format(provider.startDate)} to ${DateFormat('MMM d, yyyy').format(provider.endDate)}',
                    style: TextStyle(fontSize: widget.compact ? 14 : 16),
                  ),
                ),
                PopupMenuButton<DateRangeOption>(
                  tooltip: 'Select date range',
                  child: Chip(
                    label: Text(_selectedOption.label),
                    avatar: Icon(Icons.date_range, size: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                  initialValue: _selectedOption,
                  onSelected: (option) {
                    setState(() {
                      _selectedOption = option;
                    });

                    if (option == DateRangeOption.custom) {
                      _showCustomDatePicker(context, provider);
                    } else {
                      _applyDateRange(option, provider);
                    }
                  },
                  itemBuilder: (context) {
                    return DateRangeOption.values.map((option) {
                      return PopupMenuItem<DateRangeOption>(
                        value: option,
                        child: Text(option.label),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            if (!widget.compact) SizedBox(height: 8),
            if (!widget.compact)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _quickDateButton(
                      context,
                      '7 Days',
                      DateRangeOption.sevenDays,
                    ),
                    SizedBox(width: 8),
                    _quickDateButton(
                      context,
                      '30 Days',
                      DateRangeOption.thirtyDays,
                    ),
                    SizedBox(width: 8),
                    _quickDateButton(
                      context,
                      'This Month',
                      DateRangeOption.thisMonth,
                    ),
                    SizedBox(width: 8),
                    _quickDateButton(
                      context,
                      '3 Months',
                      DateRangeOption.threeMonths,
                    ),
                    SizedBox(width: 8),
                    _quickDateButton(context, 'YTD', DateRangeOption.ytd),
                    SizedBox(width: 8),
                    _quickDateButton(
                      context,
                      '1 Year',
                      DateRangeOption.oneYear,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickDateButton(
    BuildContext context,
    String label,
    DateRangeOption option,
  ) {
    final provider = Provider.of<TransactionData>(context, listen: false);
    final isSelected = _selectedOption == option;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedOption = option;
        });
        _applyDateRange(option, provider);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
        foregroundColor:
            isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface,
      ),
      child: Text(label),
    );
  }

  void _applyDateRange(DateRangeOption option, TransactionData provider) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = now;

    switch (option) {
      case DateRangeOption.sevenDays:
      case DateRangeOption.thirtyDays:
      case DateRangeOption.threeMonths:
      case DateRangeOption.sixMonths:
      case DateRangeOption.oneYear:
        start = now.subtract(Duration(days: option.days));
        break;

      case DateRangeOption.thisMonth:
        start = DateTime(now.year, now.month, 1);
        break;

      case DateRangeOption.lastMonth:
        // Last day of previous month
        final lastMonth = DateTime(now.year, now.month - 1);
        start = DateTime(lastMonth.year, lastMonth.month, 1);
        end = DateTime(now.year, now.month, 0); // Last day of previous month
        break;

      case DateRangeOption.ytd:
        start = DateTime(now.year, 1, 1); // January 1st of current year
        break;

      case DateRangeOption.custom:
        // Don't change dates for custom - will be handled by date picker
        return;
    }

    provider.setDateRange(start, end);
  }

  Future<void> _showCustomDatePicker(
    BuildContext context,
    TransactionData provider,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: provider.startDate,
        end: provider.endDate,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    } else {
      // If canceled, revert to previous selection
      final previousOption = DateRangeOption.values.firstWhere(
        (o) => o != DateRangeOption.custom,
        orElse: () => DateRangeOption.thirtyDays,
      );
      setState(() {
        _selectedOption = previousOption;
      });
    }
  }
}
