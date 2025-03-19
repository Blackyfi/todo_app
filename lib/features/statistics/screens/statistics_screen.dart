import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart' as fl_chart;

class StatisticsScreen extends mat.StatefulWidget {
  const StatisticsScreen({mat.Key? key}) : super(key: key);

  @override
  mat.State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends mat.State<StatisticsScreen> {
  final _taskRepository = task_repository.TaskRepository();
  final _categoryRepository = category_repository.CategoryRepository();
  
  List<task_model.Task> _tasks = [];
  List<category_model.Category> _categories = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final tasks = await _taskRepository.getAllTasks();
      final categories = await _categoryRepository.getAllCategories();
      
      setState(() {
        _tasks = tasks;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        mat.ScaffoldMessenger.of(context).showSnackBar(
          mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  Map<String, int> _getCompletionStats() {
    final stats = <String, int>{
      'Completed': 0,
      'Incomplete': 0,
    };
    
    for (final task in _tasks) {
      if (task.isCompleted) {
        stats['Completed'] = (stats['Completed'] ?? 0) + 1;
      } else {
        stats['Incomplete'] = (stats['Incomplete'] ?? 0) + 1;
      }
    }
    
    return stats;
  }
  
  Map<String, int> _getPriorityStats() {
    final stats = <String, int>{
      'High': 0,
      'Medium': 0,
      'Low': 0,
    };
    
    for (final task in _tasks) {
      switch (task.priority) {
        case task_model.Priority.high:
          stats['High'] = (stats['High'] ?? 0) + 1;
          break;
        case task_model.Priority.medium:
          stats['Medium'] = (stats['Medium'] ?? 0) + 1;
          break;
        case task_model.Priority.low:
          stats['Low'] = (stats['Low'] ?? 0) + 1;
          break;
      }
    }
    
    return stats;
  }
  
  Map<String, int> _getCategoryStats() {
    final stats = <String, int>{};
    
    for (final task in _tasks) {
      final category = _categories.firstWhere(
        (cat) => cat.id == task.categoryId,
        orElse: () => category_model.Category(
          id: 0,
          name: 'Unknown',
          color: mat.Colors.grey,
        ),
      );
      
      stats[category.name] = (stats[category.name] ?? 0) + 1;
    }
    
    return stats;
  }
  
  List<task_model.Task> _getTasksDueThisWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(startOfWeek) && 
             task.dueDate!.isBefore(endOfWeek) &&
             !task.isCompleted;
    }).toList();
  }
  
  Map<String, int> _getTasksCompletedByDay() {
    final stats = <String, int>{};
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    
    // Initialize days of the week
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      stats[intl.DateFormat('EEE').format(day)] = 0;
    }
    
    // Count completed tasks by day of the week
    for (final task in _tasks) {
      if (task.isCompleted && task.dueDate != null) {
        final dayOfWeek = intl.DateFormat('EEE').format(task.dueDate!);
        stats[dayOfWeek] = (stats[dayOfWeek] ?? 0) + 1;
      }
    }
    
    return stats;
  }
  
  double _getCompletionPercentage() {
    if (_tasks.isEmpty) return 0;
    
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    return (completedCount / _tasks.length) * 100;
  }
  
  @override
  mat.Widget build(mat.BuildContext context) {
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: const mat.Text('Statistics'),
      ),
      body: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : mat.RefreshIndicator(
              onRefresh: _loadData,
              child: mat.SingleChildScrollView(
                physics: const mat.AlwaysScrollableScrollPhysics(),
                padding: const mat.EdgeInsets.all(16),
                child: mat.Column(
                  crossAxisAlignment: mat.CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const mat.SizedBox(height: 16),
                    _buildCompletionChart(),
                    const mat.SizedBox(height: 16),
                    _buildPriorityChart(),
                    const mat.SizedBox(height: 16),
                    _buildCategoryChart(),
                    const mat.SizedBox(height: 16),
                    _buildWeeklyTasksCard(),
                    const mat.SizedBox(height: 16),
                    _buildWeeklyCompletionChart(),
                  ],
                ),
              ),
            ),
    );
  }
  
  mat.Widget _buildSummaryCard() {
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    final incompleteCount = _tasks.length - completedCount;
    final overdueTasks = _tasks.where((task) => 
      !task.isCompleted && task.dueDate != null && task.dueDate!.isBefore(DateTime.now())
    ).length;
    
    final completionPercentage = _getCompletionPercentage();
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Task Summary',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 16),
            mat.Row(
              children: [
                _buildInfoItem(
                  icon: mat.Icons.task_alt,
                  label: 'Total',
                  value: _tasks.length.toString(),
                  color: mat.Theme.of(context).colorScheme.primary,
                ),
                _buildInfoItem(
                  icon: mat.Icons.check_circle,
                  label: 'Completed',
                  value: completedCount.toString(),
                  color: mat.Colors.green,
                ),
                _buildInfoItem(
                  icon: mat.Icons.pending_actions,
                  label: 'Pending',
                  value: incompleteCount.toString(),
                  color: mat.Colors.orange,
                ),
                _buildInfoItem(
                  icon: mat.Icons.watch_later,
                  label: 'Overdue',
                  value: overdueTasks.toString(),
                  color: mat.Colors.red,
                ),
              ],
            ),
            const mat.SizedBox(height: 16),
            mat.Text(
              'Completion Rate: ${completionPercentage.toStringAsFixed(1)}%',
              style: mat.Theme.of(context).textTheme.titleMedium,
            ),
            const mat.SizedBox(height: 8),
            mat.LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: mat.Theme.of(context).colorScheme.surfaceVariant,
              color: mat.Theme.of(context).colorScheme.primary,
              borderRadius: mat.BorderRadius.circular(8),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }
  
  mat.Widget _buildInfoItem({
    required mat.IconData icon,
    required String label,
    required String value,
    required mat.Color color,
  }) {
    return mat.Expanded(
      child: mat.Column(
        children: [
          mat.Icon(icon, color: color, size: 28),
          const mat.SizedBox(height: 4),
          mat.Text(
            value,
            style: mat.TextStyle(
              fontSize: 18,
              fontWeight: mat.FontWeight.bold,
              color: color,
            ),
          ),
          mat.Text(
            label,
            style: mat.TextStyle(
              fontSize: 12,
              color: mat.Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  mat.Widget _buildCompletionChart() {
    final stats = _getCompletionStats();
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
  
  mat.Widget _buildPriorityChart() {
    final stats = _getPriorityStats();
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
                            tooltipBgColor: mat.Colors.blueGrey.withOpacity(0.8),
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
                          rightTitles: fl_chart.AxisTitles(
                            sideTitles: fl_chart.SideTitles(showTitles: false),
                          ),
                          topTitles: fl_chart.AxisTitles(
                            sideTitles: fl_chart.SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: fl_chart.FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => fl_chart.FlLine(
                            color: mat.Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
  
  mat.Widget _buildCategoryChart() {
    final stats = _getCategoryStats();
    
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
    for (final category in _categories) {
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
  
  mat.Widget _buildWeeklyTasksCard() {
    final tasksDueThisWeek = _getTasksDueThisWeek();
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Tasks Due This Week',
              style: mat.Theme.of(context).textTheme.titleLarge,
            ),
            const mat.SizedBox(height: 8),
            if (tasksDueThisWeek.isEmpty) ...[
              const mat.SizedBox(height: 40),
              const mat.Center(
                child: mat.Text('No tasks due this week'),
              ),
              const mat.SizedBox(height: 40),
            ] else ...[
              ...tasksDueThisWeek.map((task) {
                final category = _categories.firstWhere(
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
                        color: category.color.withOpacity(0.2),
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
                      style: mat.Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: mat.TextOverflow.ellipsis,
                    ),
                    subtitle: task.dueDate != null
                        ? mat.Text(
                            intl.DateFormat('E, MMM d').format(task.dueDate!),
                            style: mat.TextStyle(
                              color: mat.Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        color: task.priority.color.withOpacity(0.2),
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
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
  
  mat.Widget _buildWeeklyCompletionChart() {
    final stats = _getTasksCompletedByDay();
    
    return mat.Card(
      child: mat.Padding(
        padding: const mat.EdgeInsets.all(16),
        child: mat.Column(
          crossAxisAlignment: mat.CrossAxisAlignment.start,
          children: [
            mat.Text(
              'Completed Tasks by Day',
              style: mat.Theme.of(context).textTheme.titleLarge,
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
                      tooltipBgColor: mat.Colors.blueGrey.withOpacity(0.8),
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
                    rightTitles: fl_chart.AxisTitles(
                      sideTitles: fl_chart.SideTitles(showTitles: false),
                    ),
                    topTitles: fl_chart.AxisTitles(
                      sideTitles: fl_chart.SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: fl_chart.FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => fl_chart.FlLine(
                      color: mat.Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
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
                          color: mat.Theme.of(context).colorScheme.primary,
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