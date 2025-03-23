import 'package:flutter/material.dart' as mat;
import 'package:fl_chart/fl_chart.dart' as fl_chart;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:intl/intl.dart' as intl;

class CompletionChart extends mat.StatelessWidget {
  final Map<String, int> stats;

  const CompletionChart({
    super.key,
    required this.stats,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final completedCount = stats['Completed'] ?? 0;
    final incompleteCount = stats['Incomplete'] ?? 0;
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Task Completion',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 8),
            mat.SizedBox(
              height: 200,
              child: completedCount == 0 && incompleteCount == 0
                  ? const mat.Center(child: mat.Text('No data available'))
                  : fl_chart.PieChart(
                      fl_chart.PieChartData(
                        sections: [
                          fl_chart.PieChartSectionData(
                            value: completedCount.toDouble(),
                            title: 'Completed\n$completedCount',
                            color: mat.Colors.green,
                            radius: 80,
                            titleStyle: const mat.TextStyle(
                              color: mat.Colors.white,
                              fontWeight: mat.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          fl_chart.PieChartSectionData(
                            value: incompleteCount.toDouble(),
                            title: 'Incomplete\n$incompleteCount',
                            color: mat.Colors.orange,
                            radius: 80,
                            titleStyle: const mat.TextStyle(
                              color: mat.Colors.white,
                              fontWeight: mat.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class PriorityChart extends mat.StatelessWidget {
  final Map<String, int> stats;

  const PriorityChart({
    super.key,
    required this.stats,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    final highCount = stats['High'] ?? 0;
    final mediumCount = stats['Medium'] ?? 0;
    final lowCount = stats['Low'] ?? 0;
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Tasks by Priority',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            mat.SizedBox(
              height: 200,
              child: highCount == 0 && mediumCount == 0 && lowCount == 0
                  ? const mat.Center(child: mat.Text('No data available'))
                  : fl_chart.BarChart(
                      fl_chart.BarChartData(
                        alignment: fl_chart.BarChartAlignment.spaceAround,
                        maxY: [highCount, mediumCount, lowCount].reduce(
                          (a, b) => a > b ? a : b
                        ).toDouble() + 2,
                        barTouchData: fl_chart.BarTouchData(
                          enabled: true,
                          touchTooltipData: fl_chart.BarTouchTooltipData(
                            tooltipBgColor: mat.Colors.blueGrey.withAlpha((0.8 * 255).toInt()),
                          ),
                        ),
                        titlesData: fl_chart.FlTitlesData(
                          show: true,
                          bottomTitles: fl_chart.AxisTitles(
                            sideTitles: fl_chart.SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                String text;
                                switch (value.toInt()) {
                                  case 0:
                                    text = 'High';
                                    break;
                                  case 1:
                                    text = 'Medium';
                                    break;
                                  case 2:
                                    text = 'Low';
                                    break;
                                  default:
                                    text = '';
                                }
                                return mat.Padding(
                                  padding: const mat.EdgeInsets.only(top: 8),
                                  child: mat.Text(
                                    text,
                                    style: mat.TextStyle(
                                      color: mat.Theme.of(context).colorScheme.onSurface,
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
                                      color: mat.Theme.of(context).colorScheme.onSurface,
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
                        ),
                        gridData: fl_chart.FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => fl_chart.FlLine(
                            color: mat.Theme.of(context).colorScheme.onSurface.withAlpha(25),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: fl_chart.FlBorderData(show: false),
                        barGroups: [
                          fl_chart.BarChartGroupData(
                            x: 0,
                            barRods: [
                              fl_chart.BarChartRodData(
                                toY: highCount.toDouble(),
                                color: mat.Colors.red,
                                width: 22,
                                borderRadius: const mat.BorderRadius.only(
                                  topLeft: mat.Radius.circular(6),
                                  topRight: mat.Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                          fl_chart.BarChartGroupData(
                            x: 1,
                            barRods: [
                              fl_chart.BarChartRodData(
                                toY: mediumCount.toDouble(),
                                color: mat.Colors.orange,
                                width: 22,
                                borderRadius: const mat.BorderRadius.only(
                                  topLeft: mat.Radius.circular(6),
                                  topRight: mat.Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                          fl_chart.BarChartGroupData(
                            x: 2,
                            barRods: [
                              fl_chart.BarChartRodData(
                                toY: lowCount.toDouble(),
                                color: mat.Colors.green,
                                width: 22,
                                borderRadius: const mat.BorderRadius.only(
                                  topLeft: mat.Radius.circular(6),
                                  topRight: mat.Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChart extends mat.StatelessWidget {
  final Map<String, int> stats;
  final List<category_model.Category> categories;

  const CategoryChart({
    super.key,
    required this.stats,
    required this.categories,
  });

  @override
  mat.Widget build(mat.BuildContext context) {
    if (stats.isEmpty) {
      return mat.Card(
        child: mat.Padding(
          padding: const mat.EdgeInsets.all(16),
          child: mat.Column(
            crossAxisAlignment: mat.CrossAxisAlignment.start,
            children: [
              mat.Text(
                'Tasks by Category',
                style: mat.Theme.of(context).textTheme.titleLarge,
              ),
              const mat.SizedBox(height: 16),
              const mat.Center(
                heightFactor: 5,
                child: mat.Text('No data available'),
              ),
            ],
          ),
        ),
      );
    }
    
    final Map<String, mat.Color> categoryColors = {};
    for (final category in categories) {
      categoryColors[category.name] = category.color;
    }
    
    final List<fl_chart.PieChartSectionData> sections = [];
    
    stats.forEach((category, count) {
      sections.add(
        fl_chart.PieChartSectionData(
          value: count.toDouble(),
          title: '$category\n$count',
          color: categoryColors[category] ?? mat.Colors.grey,
          radius: 80,
          titleStyle: const mat.TextStyle(
            color: mat.Colors.white,
            fontWeight: mat.FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    });
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Tasks by Category',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            mat.SizedBox(
              height: 250,
              child: fl_chart.PieChart(
                fl_chart.PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyTasksCard extends mat.StatelessWidget {
  final List<task_model.Task> tasks;
  final List<category_model.Category> categories;

  const WeeklyTasksCard({
    super.key,
    required this.tasks,
    required this.categories,
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
              'Tasks Due This Week',
              style: theme.textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 8),
            if (tasks.isEmpty) ...[
              const mat.SizedBox(height: 40),
              const mat.Center(
                child: mat.Text('No tasks due this week'),
              ),
              const mat.SizedBox(height: 40),
            ] else ...[
              ...List.generate(tasks.length, (index) {
                final task = tasks[index];
                final category = categories.firstWhere(
                  (cat) => cat.id == task.categoryId,
                  orElse: () => category_model.Category(
                    id: 0,
                    name: 'Unknown',
                    color: mat.Colors.grey,
                  ),
                );
                
                return mat.Padding(
                  padding: const mat.EdgeInsets.only(bottom: 8),
                  child: mat.ListTile(
                    contentPadding: const mat.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                    leading: mat.Container(
                      width: 40,
                      height: 40,
                      decoration: mat.BoxDecoration(
                        color: category.color.withAlpha((0.2 * 255).toInt()),
                        borderRadius: mat.BorderRadius.circular(8),
                      ),
                      child: mat.Center(
                        child: mat.Icon(
                          mat.Icons.calendar_today,
                          color: category.color,
                          size: 20,
                        ),
                      ),
                    ),
                    title: mat.Text(
                      task.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: mat.TextOverflow.ellipsis,
                    ),
                    subtitle: task.dueDate != null
                        ? mat.Text(
                            intl.DateFormat('E, MMM d').format(task.dueDate!),
                            style: mat.TextStyle(
                                color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).toInt()),
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: mat.Container(
                      padding: const mat.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: mat.BoxDecoration(
                        color: task.priority.color.withAlpha((0.2 * 255).toInt()),
                        borderRadius: mat.BorderRadius.circular(4),
                      ),
                      child: mat.Text(
                        task.priority.label,
                        style: mat.TextStyle(
                          color: task.priority.color,
                          fontSize: 12,
                          fontWeight: mat.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

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
                    touchTooltipData: fl_chart.BarTouchTooltipData(
                      tooltipBgColor: mat.Colors.blueGrey.withAlpha((0.8 * 255).toInt()),
                    ),
                  ),
                  titlesData: fl_chart.FlTitlesData(
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
                  ),
                  gridData: fl_chart.FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => fl_chart.FlLine(
                        color: theme.colorScheme.onSurface.withAlpha(25),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: fl_chart.FlBorderData(show: false),
                  barGroups: List.generate(stats.length, (index) {
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
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}