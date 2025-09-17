// screens/trends_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/trends/monthly_category_chart.dart';
import '../widgets/date_range_selector.dart';

class TrendsPage extends StatefulWidget {
  const TrendsPage({super.key});

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  Offset _cursorPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: MouseRegion(
        onHover: (event) {
          setState(() {
            _cursorPosition = event.localPosition;
          });
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.transactions.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await provider.initialize();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date Range Selector
                        const DateRangeSelector(),
                        const SizedBox(height: 24),

                        // Monthly Category Spending Chart
                        const MonthlyCategoryChart(),
                        const SizedBox(height: 24),

                        // Placeholder for future charts
                        _buildFutureChartsPlaceholder(),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: _cursorPosition.dx - 12,
              top: _cursorPosition.dy - 12,
              child: IgnorePointer(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No data for trends analysis',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some transactions to see spending trends',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureChartsPlaceholder() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.construction,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'More Charts Coming Soon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Additional trend analysis charts will be added here:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ...['Spending vs Income Over Time', 'Category Growth Trends', 'Budget vs Actual Analysis']
                .map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
                          const SizedBox(width: 8),
                          Text(item, style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    )),
          ],
        ),
      ),
    );
  }
}