import 'package:flutter/material.dart' as mat;
import 'package:fl_chart/fl_chart.dart' as fl_chart;

class WeeklyCompletionChart extends mat.StatelessWidget {
  final Map<String, int> stats;

  const WeeklyCompletionChart({
    super.key,
    required this.stats,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final theme = mat.Theme.of(context);
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Completed Tasks by Day',
              style: theme.textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            mat.SizedBox(
              height: 200,
              child: fl_chart.BarChart(
                fl_chart.BarChartData(
                  alignment: fl_chart.BarChartAlignment.spaceAround,
                  maxY: stats.values.fold(0, (max, value) => value > max ? value : max).toDouble() + 1,
                  barTouchData: fl_chart.BarTouchData(
                    enabled: true,
                  ),
                  titlesData: _buildTitlesData(context, theme),
                  gridData: fl_chart.FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => fl_chart.FlLine(
                      color: theme.colorScheme.onSurface.withAlpha(25),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: fl_chart.FlBorderData(show: false),
                  barGroups: _buildBarGroups(theme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  fl_chart.FlTitlesData _buildTitlesData(mat.BuildContext context, mat.ThemeData theme) {
    return fl_chart.FlTitlesData(
      show: true,
      bottomTitles: fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final keys = stats.keys.toList();
            if (value.toInt() < 0 || value.toInt() >= keys.length) {
              return const mat.SizedBox.shrink();
            }
            
            return mat.Padding(
              padding: const mat.EdgeInsets.only(top: 8),
              child: mat.Text(
                keys[value.toInt()],
                style: mat.TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: mat.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            if (value == 0) {
              return const mat.SizedBox.shrink();
            }
            return mat.Padding(
              padding: const mat.EdgeInsets.only(right: 8),
              child: mat.Text(
                value.toInt().toString(),
                style: mat.TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            );
          },
          reservedSize: 30,
        ),
      ),
      rightTitles: const fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(showTitles: false),
      ),
      topTitles: const fl_chart.AxisTitles(
        sideTitles: fl_chart.SideTitles(showTitles: false),
      ),
    );
  }

  List<fl_chart.BarChartGroupData> _buildBarGroups(mat.ThemeData theme) {
    return List.generate(stats.length, (index) {
      final keys = stats.keys.toList();
      final key = keys[index];
      final value = stats[key] ?? 0;
      
      return fl_chart.BarChartGroupData(
        x: index,
        barRods: [
          fl_chart.BarChartRodData(
            toY: value.toDouble(),
            color: theme.colorScheme.primary,
            width: 20,
            borderRadius: const mat.BorderRadius.only(
              topLeft: mat.Radius.circular(6),
              topRight: mat.Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }
}