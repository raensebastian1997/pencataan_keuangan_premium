import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/utils/color_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/report_data.dart';

class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key, required this.items});

  final List<CategorySpending> items;

  @override
  Widget build(BuildContext context) {
    final data = _buildChartData(context);
    final total = data.fold<double>(0, (sum, item) => sum + item.total);

    if (data.isEmpty || total <= 0) {
      return const _EmptyChart(message: 'Belum ada pengeluaran bulan ini');
    }
    final slices = data
        .map(
          (item) => _ExpenseSlice(
            name: item.name,
            total: item.total,
            color: item.color,
            percent: item.total / total * 100,
          ),
        )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 56;
        final chartSize = width <= 0 ? 300.0 : min(width, 340.0).toDouble();
        final outerRadius = chartSize * 0.27;
        final centerRadius = chartSize * 0.16;
        final sectionGap = chartSize < 280 ? 0.7 : 1.2;
        final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: chartSize < 280 ? 11 : 13,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: 0,
        );

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: chartSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      centerSpaceRadius: centerRadius,
                      sectionsSpace: sectionGap,
                      borderData: FlBorderData(show: false),
                      sections: slices.map((item) {
                        return PieChartSectionData(
                          value: item.total,
                          title: '',
                          radius: outerRadius,
                          color: item.color,
                        );
                      }).toList(),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DonutLabelPainter(
                        slices: slices,
                        outerRadius: outerRadius,
                        textStyle: labelStyle ?? const TextStyle(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Column(
              children: slices.map((item) {
                return _ExpenseLegendRow(item: item);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  List<_ExpenseChartDatum> _buildChartData(BuildContext context) {
    final sorted = [...items]
      ..sort((a, b) => b.total.compareTo(a.total));
    final visibleItems = sorted.take(9).map((item) {
      return _ExpenseChartDatum(
        name: item.categoryName,
        total: item.total,
        color: ColorUtils.fromHex(item.categoryColorHex),
      );
    }).toList();

    if (sorted.length > 9) {
      final otherTotal = sorted
          .skip(9)
          .fold<double>(0, (sum, item) => sum + item.total);
      if (otherTotal > 0) {
        visibleItems.add(
          _ExpenseChartDatum(
            name: 'Lainnya',
            total: otherTotal,
            color: Theme.of(context).colorScheme.outline,
          ),
        );
      }
    }

    return visibleItems;
  }
}

class _ExpenseChartDatum {
  const _ExpenseChartDatum({
    required this.name,
    required this.total,
    required this.color,
  });

  final String name;
  final double total;
  final Color color;
}

class _ExpenseSlice {
  const _ExpenseSlice({
    required this.name,
    required this.total,
    required this.color,
    required this.percent,
  });

  final String name;
  final double total;
  final Color color;
  final double percent;
}

class _ExpenseLegendRow extends StatelessWidget {
  const _ExpenseLegendRow({required this.item});

  final _ExpenseSlice item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Text(
              _formatPercent(item.percent),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 112,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                CurrencyFormatter.format(item.total),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutLabelPainter extends CustomPainter {
  _DonutLabelPainter({
    required this.slices,
    required this.outerRadius,
    required this.textStyle,
  });

  final List<_ExpenseSlice> slices;
  final double outerRadius;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final anchors = _buildAnchors(center);
    final leftAnchors = anchors.where((item) => !item.isRight).toList();
    final rightAnchors = anchors.where((item) => item.isRight).toList();
    _spreadAnchors(leftAnchors, size);
    _spreadAnchors(rightAnchors, size);

    for (final anchor in [...leftAnchors, ...rightAnchors]) {
      final textPainter = TextPainter(
        text: TextSpan(text: _formatPercent(anchor.percent), style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final double textX = anchor.isRight
          ? min(size.width - textPainter.width - 2, center.dx + outerRadius + 38)
              .toDouble()
          : max(2, center.dx - outerRadius - 38 - textPainter.width).toDouble();
      final textOffset = Offset(textX, anchor.labelY - textPainter.height / 2);
      final elbowX = anchor.isRight
          ? textOffset.dx - 8
          : textOffset.dx + textPainter.width + 8;
      final elbow = Offset(elbowX, anchor.labelY);

      final paint = Paint()
        ..color = anchor.color.withValues(alpha: 0.82)
        ..strokeWidth = 1.35
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(anchor.start.dx, anchor.start.dy)
        ..quadraticBezierTo(
          anchor.mid.dx,
          anchor.mid.dy,
          elbow.dx,
          elbow.dy,
        );

      canvas.drawPath(path, paint);
      canvas.drawCircle(anchor.start, 2.0, paint..style = PaintingStyle.fill);
      textPainter.paint(canvas, textOffset);
      paint.style = PaintingStyle.stroke;
    }
  }

  List<_DonutLabelAnchor> _buildAnchors(Offset center) {
    var startAngle = -pi / 2;
    final anchors = <_DonutLabelAnchor>[];

    for (final slice in slices) {
      final sweep = 2 * pi * (slice.percent / 100);
      final midAngle = startAngle + sweep / 2;
      final start = Offset(
        center.dx + cos(midAngle) * (outerRadius + 2),
        center.dy + sin(midAngle) * (outerRadius + 2),
      );
      final mid = Offset(
        center.dx + cos(midAngle) * (outerRadius + 14),
        center.dy + sin(midAngle) * (outerRadius + 14),
      );
      final labelY = center.dy + sin(midAngle) * (outerRadius + 34);

      anchors.add(
        _DonutLabelAnchor(
          start: start,
          mid: mid,
          labelY: labelY,
          isRight: cos(midAngle) >= 0,
          color: slice.color,
          percent: slice.percent,
        ),
      );
      startAngle += sweep;
    }

    return anchors;
  }

  void _spreadAnchors(List<_DonutLabelAnchor> anchors, Size size) {
    if (anchors.isEmpty) {
      return;
    }

    anchors.sort((a, b) => a.labelY.compareTo(b.labelY));
    final minY = textStyle.fontSize ?? 12;
    final maxY = size.height - minY;
    final gap = (textStyle.fontSize ?? 12) + 7;

    anchors.first.labelY = anchors.first.labelY.clamp(minY, maxY).toDouble();
    for (var index = 1; index < anchors.length; index++) {
      final previous = anchors[index - 1];
      final current = anchors[index];
      current.labelY = max(current.labelY, previous.labelY + gap).toDouble();
    }

    final overflow = anchors.last.labelY - maxY;
    if (overflow > 0) {
      for (final anchor in anchors) {
        anchor.labelY = max(minY, anchor.labelY - overflow).toDouble();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DonutLabelPainter oldDelegate) {
    return oldDelegate.slices != slices ||
        oldDelegate.outerRadius != outerRadius ||
        oldDelegate.textStyle != textStyle;
  }
}

class _DonutLabelAnchor {
  _DonutLabelAnchor({
    required this.start,
    required this.mid,
    required this.labelY,
    required this.isRight,
    required this.color,
    required this.percent,
  });

  final Offset start;
  final Offset mid;
  double labelY;
  final bool isRight;
  final Color color;
  final double percent;
}

String _formatPercent(double percent) {
  return '${percent.toStringAsFixed(1)}%';
}

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({super.key, required this.items});

  final List<MonthlyComparison> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<double>(
      0,
      (current, item) => max(current, max(item.income, item.expense)),
    );
    if (items.isEmpty || maxValue == 0) {
      return const _EmptyChart(message: 'Belum ada data 6 bulan terakhir');
    }
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          maxY: maxValue * 1.2,
          barGroups: List.generate(items.length, (index) {
            final item = items[index];
            return BarChartGroupData(
              x: index,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: item.income,
                  width: 9,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.green,
                ),
                BarChartRodData(
                  toY: item.expense,
                  width: 9,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.red,
                ),
              ],
            );
          }),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _compactCurrency(value),
                    style: Theme.of(context).textTheme.labelSmall,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= items.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM', 'id_ID').format(items[index].month),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _compactCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
