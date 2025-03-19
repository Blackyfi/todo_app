import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/tasks/screens/home_screen.dart' as home_screen;
import 'package:todo_app/features/tasks/screens/task_details_screen.dart' as task_details_screen;
import 'package:todo_app/features/tasks/screens/add_edit_task_screen.dart' as add_edit_task_screen;
import 'package:todo_app/features/categories/screens/categories_screen.dart' as categories_screen;
import 'package:todo_app/features/statistics/screens/statistics_screen.dart' as statistics_screen;

class AppRouter {
  static mat.Route<dynamic> generateRoute(mat.RouteSettings settings) {
    switch (settings.name) {
      case app_constants.AppConstants.homeRoute:
        return mat.MaterialPageRoute(builder: (_) => const home_screen.HomeScreen());
        
      case app_constants.AppConstants.taskDetailsRoute:
        final task = settings.arguments as task_model.Task;
        return mat.MaterialPageRoute(
          builder: (_) => task_details_screen.TaskDetailsScreen(task: task),
        );
        
      case app_constants.AppConstants.addTaskRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const add_edit_task_screen.AddEditTaskScreen(),
        );
        
      case app_constants.AppConstants.editTaskRoute:
        final task = settings.arguments as task_model.Task;
        return mat.MaterialPageRoute(
          builder: (_) => add_edit_task_screen.AddEditTaskScreen(task: task),
        );
        
      case app_constants.AppConstants.categoriesRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const categories_screen.CategoriesScreen(),
        );
        
      case app_constants.AppConstants.statisticsRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const statistics_screen.StatisticsScreen(),
        );
        
      default:
        return mat.MaterialPageRoute(
          builder: (_) => mat.Scaffold(
            body: mat.Center(
              child: mat.Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
