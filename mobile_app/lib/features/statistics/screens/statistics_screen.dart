import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/categories/models/category.dart' as category_model;
import 'package:todo_app/core/database/repository/task_repository.dart' as task_repository;
import 'package:todo_app/core/database/repository/category_repository.dart' as category_repository;
import 'package:todo_app/features/statistics/widgets/summary_card.dart' as summary_card;
import 'package:todo_app/features/statistics/widgets/chart_cards.dart' as chart_cards;
import 'package:todo_app/features/statistics/utils/statistics_helpers.dart' as statistics_helpers;
import 'package:todo_app/l10n/app_localizations.dart';

class StatisticsScreen extends mat.StatefulWidget {
  const StatisticsScreen({super.key});

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
          const mat.SnackBar(
            content: mat.Text(app_constants.AppConstants.databaseErrorMessage),
          ),
        );
      }
    }
  }
  
  @override
  mat.Widget build(mat.BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return mat.Scaffold(
      appBar: mat.AppBar(
        title: mat.Text(l10n.statistics),
      ),
      body: mat.SafeArea(
        top: false,
        child: _isLoading
          ? const mat.Center(child: mat.CircularProgressIndicator())
          : mat.RefreshIndicator(
              onRefresh: _loadData,
              child: mat.SingleChildScrollView(
                physics: const mat.AlwaysScrollableScrollPhysics(),
                padding: const mat.EdgeInsets.all(16),
                child: mat.Column(
                  crossAxisAlignment: mat.CrossAxisAlignment.start,
                  children: [
                    summary_card.SummaryCard(tasks: _tasks),
                    const mat.SizedBox(height: 16),
                    chart_cards.CompletionChart(
                      stats: statistics_helpers.getCompletionStats(_tasks),
                    ),
                    const mat.SizedBox(height: 16),
                    chart_cards.PriorityChart(
                      stats: statistics_helpers.getPriorityStats(_tasks),
                    ),
                    const mat.SizedBox(height: 16),
                    chart_cards.CategoryChart(
                      stats: statistics_helpers.getCategoryStats(_tasks, _categories),
                      categories: _categories,
                    ),
                    const mat.SizedBox(height: 16),
                    chart_cards.WeeklyTasksCard(
                      tasks: statistics_helpers.getTasksDueThisWeek(_tasks),
                      categories: _categories,
                    ),
                    const mat.SizedBox(height: 16),
                    chart_cards.WeeklyCompletionChart(
                      stats: statistics_helpers.getTasksCompletedByDay(_tasks),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}