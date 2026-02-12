import 'package:flutter/material.dart' as mat;
import 'package:todo_app/common/constants/app_constants.dart' as app_constants;
import 'package:todo_app/features/tasks/models/task.dart' as task_model;
import 'package:todo_app/features/tasks/screens/home_screen.dart' as home_screen;
import 'package:todo_app/features/tasks/screens/task_details_screen.dart' as task_details_screen;
import 'package:todo_app/features/tasks/screens/add_edit_task_screen.dart' as add_edit_task_screen;
import 'package:todo_app/features/categories/screens/categories_screen.dart' as categories_screen;
import 'package:todo_app/features/statistics/screens/statistics_screen.dart' as statistics_screen;
import 'package:todo_app/features/settings/screens/settings_screen.dart';
import 'package:todo_app/features/settings/screens/log_viewer_screen.dart';
import 'package:todo_app/features/widgets/screens/widget_creation_screen.dart';
import 'package:todo_app/core/widgets/models/widget_config.dart';
import 'package:todo_app/features/shopping/screens/shopping_lists_screen.dart' as shopping_lists_screen;
import 'package:todo_app/features/shopping/screens/create_edit_shopping_list_screen.dart' as create_edit_shopping_list_screen;
import 'package:todo_app/features/shopping/screens/shopping_mode_screen.dart' as shopping_mode_screen;
import 'package:todo_app/features/shopping/models/shopping_list.dart' as shopping_list_model;
import 'package:todo_app/features/sync/screens/sync_settings_screen.dart' as sync_settings_screen;

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
        
      case app_constants.AppConstants.settingsRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );
        
      case app_constants.AppConstants.logViewerRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const LogViewerScreen(),
        );

      case '/widget-settings':
        final widgetConfig = settings.arguments as WidgetConfig?;
        return mat.MaterialPageRoute(
          builder: (_) => WidgetCreationScreen(existingConfig: widgetConfig),
        );

      case app_constants.AppConstants.shoppingListsRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const shopping_lists_screen.ShoppingListsScreen(),
        );

      case app_constants.AppConstants.createShoppingListRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const create_edit_shopping_list_screen.CreateEditShoppingListScreen(),
        );

      case app_constants.AppConstants.editShoppingListRoute:
        final shoppingList = settings.arguments as shopping_list_model.ShoppingList;
        return mat.MaterialPageRoute(
          builder: (_) => create_edit_shopping_list_screen.CreateEditShoppingListScreen(shoppingList: shoppingList),
        );

      case app_constants.AppConstants.shoppingModeRoute:
        final shoppingList = settings.arguments as shopping_list_model.ShoppingList;
        return mat.MaterialPageRoute(
          builder: (_) => shopping_mode_screen.ShoppingModeScreen(shoppingList: shoppingList),
        );

      case app_constants.AppConstants.syncSettingsRoute:
        return mat.MaterialPageRoute(
          builder: (_) => const sync_settings_screen.SyncSettingsScreen(),
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