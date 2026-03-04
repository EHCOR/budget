// widgets/trends/category_info_popup.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/statistics_service.dart';

class CategoryInfoPopup extends StatelessWidget {
  final CategoryStatistics statistics;
  final String currencySymbol;
  final Color categoryColor;
  final String transactionType;

  const CategoryInfoPopup({
    super.key,
    required this.statistics,
    required this.currencySymbol,
    required this.categoryColor,
    required this.transactionType,
  });

  static void show(
    BuildContext context,
    CategoryStatistics statistics,
    String currencySymbol,
    Color categoryColor,
    String transactionType,
    Offset position,
  ) {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    OverlayEntry? overlayEntry;

    // Calculate popup dimensions
    const popupWidth = 300.0;
    const popupHeight = 250.0;

    // Position popup so cursor is at top-left corner
    const padding = 10.0;
    double left = position.dx; // Cursor at left edge
    double top = position.dy; // Cursor at top edge

    // Check if popup fits to the right and below cursor
    if (left + popupWidth > screenSize.width - padding) {
      // Not enough space on right, place to the left of cursor
      left = position.dx - popupWidth;
    }

    // Ensure popup doesn't go off screen edges
    if (left < padding) {
      left = padding;
    }

    // Adjust vertical position if off-screen
    if (top + popupHeight > screenSize.height - padding) {
      // Not enough space below cursor, place above cursor
      top = position.dy - popupHeight;
    }

    // Final boundary checks
    if (left < padding) {
      left = padding;
    }
    if (top < padding) {
      top = padding;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Transparent background to detect taps outside
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  overlayEntry?.remove();
                  overlayEntry = null;
                },
                child: Container(color: Colors.transparent),
              ),
            ),
            // Popup with smart positioning
            Positioned(
              left: left,
              top: top,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 200),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: CategoryInfoPopup(
                          statistics: statistics,
                          currencySymbol: currencySymbol,
                          categoryColor: categoryColor,
                          transactionType: transactionType,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(overlayEntry!);

    // Auto-remove after 8 seconds (increased time)
    Future.delayed(const Duration(seconds: 8), () {
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statistics.categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                statistics.trendIcon,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${transactionType.toUpperCase()} • ${statistics.timeframePeriod}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Current Value
          _buildStatItem(
            'Current Period',
            NumberFormat.currency(symbol: currencySymbol).format(statistics.currentValue),
            Icons.calendar_today,
          ),

          // Average
          _buildStatItem(
            'Average',
            NumberFormat.currency(symbol: currencySymbol).format(statistics.average),
            Icons.trending_flat,
          ),

          // Projected (only show if sufficient data)
          if (statistics.hasSufficientData)
            _buildStatItem(
              'Projected Next',
              NumberFormat.currency(symbol: currencySymbol).format(statistics.projected),
              Icons.trending_up,
            ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // Trend Analysis or Insufficient Data Message
          if (statistics.hasSufficientData)
            Row(
              children: [
                Icon(
                  _getTrendIcon(statistics.trend),
                  size: 16,
                  color: _getTrendColor(statistics.trend),
                ),
                const SizedBox(width: 6),
                Text(
                  statistics.trendDescription,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getTrendColor(statistics.trend),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getChangeColor(statistics.percentageChange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${statistics.percentageChange >= 0 ? '+' : ''}${statistics.percentageChange.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getChangeColor(statistics.percentageChange),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Trend analysis unavailable - need more data points',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          // Data points
          Text(
            'Based on ${statistics.dataPoints} data points',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing:
        return Icons.trending_up;
      case TrendDirection.decreasing:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.increasing:
        // For expenses, increasing is bad (red). For income, increasing is good (green)
        return transactionType == 'expense' ? Colors.red : Colors.green;
      case TrendDirection.decreasing:
        // For expenses, decreasing is good (green). For income, decreasing is bad (red)
        return transactionType == 'expense' ? Colors.green : Colors.red;
      case TrendDirection.stable:
        return Colors.orange;
    }
  }

  Color _getChangeColor(double change) {
    // Use the overall trend color for consistency rather than just period-to-period change
    // This avoids confusion when short-term and long-term trends differ
    return _getTrendColor(statistics.trend);
  }
}