package com.example.todo_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import android.util.Log
import org.json.JSONObject
import org.json.JSONArray

/**
 * Enhanced Widget Provider with progress indicators, animations, and better visuals
 * P3: Advanced widget features implementation
 */
class EnhancedWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "EnhancedWidgetProvider"

        private const val ACTION_REFRESH_WIDGET = "com.example.todo_app.ACTION_REFRESH_WIDGET"
        private const val ACTION_ADD_TASK = "com.example.todo_app.ACTION_ADD_TASK"
        private const val ACTION_WIDGET_SETTINGS = "com.example.todo_app.ACTION_WIDGET_SETTINGS"
        private const val ACTION_TOGGLE_TASK = "com.example.todo_app.ACTION_TOGGLE_TASK"

        private const val EXTRA_TASK_ID = "task_id"
        private const val EXTRA_WIDGET_ID = "widget_id"

        private const val WIDGET_DATA_KEY = "widget_data"
        private const val WIDGET_CONFIG_KEY = "widget_config"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "=== Enhanced Widget onUpdate ===")

        for (appWidgetId in appWidgetIds) {
            try {
                updateEnhancedWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error updating enhanced widget $appWidgetId", e)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_REFRESH_WIDGET -> {
                handleRefreshWidget(context)
                return
            }
            ACTION_TOGGLE_TASK -> {
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, 1)
                handleToggleTask(context, taskId, widgetId)
                return
            }
        }
        super.onReceive(context, intent)
    }

    private fun updateEnhancedWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        Log.d(TAG, "--- Updating Enhanced Widget ID: $appWidgetId ---")

        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget_enhanced)

            // Get data from SharedPreferences
            val preferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            val configData = preferences.getString("${WIDGET_CONFIG_KEY}_${appWidgetId}", null)
                ?: preferences.getString(WIDGET_CONFIG_KEY, null)

            val tasksData = preferences.getString("${WIDGET_DATA_KEY}_${appWidgetId}", null)
                ?: preferences.getString(WIDGET_DATA_KEY, null)

            if (configData == null || tasksData == null) {
                showLoadingState(context, appWidgetManager, appWidgetId, views)
                return
            }

            // Parse data
            val config = JSONObject(configData)
            val data = JSONObject(tasksData)
            val tasks = data.optJSONArray("tasks") ?: JSONArray()

            // Update header
            val widgetName = config.optString("name", "Todo Tasks")
            views.setTextViewText(R.id.widget_title, widgetName)

            // Calculate and display progress
            val totalTasks = data.optInt("taskCount", 0)
            val completedTasks = data.optInt("completedCount", 0)
            val overdueTasks = data.optInt("overdueCount", 0)

            updateProgressSection(views, totalTasks, completedTasks, overdueTasks)

            // Update task list
            updateEnhancedTaskList(views, tasks, context, appWidgetId)

            // Set up button handlers
            setupButtonHandlers(context, views, appWidgetId)

            // Show/hide empty state
            if (tasks.length() == 0) {
                views.setViewVisibility(R.id.empty_state, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.task_list, android.view.View.GONE)
            } else {
                views.setViewVisibility(R.id.empty_state, android.view.View.GONE)
                views.setViewVisibility(R.id.task_list, android.view.View.VISIBLE)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Enhanced widget $appWidgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error in updateEnhancedWidget", e)
        }
    }

    private fun updateProgressSection(views: RemoteViews, total: Int, completed: Int, overdue: Int) {
        // Calculate progress percentage
        val progress = if (total > 0) (completed * 100) / total else 0

        // Update progress bar
        views.setProgressBar(R.id.task_progress_bar, 100, progress, false)

        // Update task count
        val taskCountText = "$total ${if (total == 1) "task" else "tasks"}"
        views.setTextViewText(R.id.task_count, taskCountText)

        // Update completion stats
        val completionText = "$progress% complete"
        views.setTextViewText(R.id.completion_stats, completionText)

        // Show overdue badge if needed
        if (overdue > 0) {
            views.setViewVisibility(R.id.overdue_badge, android.view.View.VISIBLE)
            views.setTextViewText(R.id.overdue_badge, "⚠️ $overdue overdue")
        } else {
            views.setViewVisibility(R.id.overdue_badge, android.view.View.GONE)
        }
    }

    private fun updateEnhancedTaskList(views: RemoteViews, tasks: JSONArray, context: Context, appWidgetId: Int) {
        views.removeAllViews(R.id.task_list)

        for (i in 0 until tasks.length()) {
            try {
                val task = tasks.getJSONObject(i)
                addEnhancedTaskItem(views, context, task, appWidgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Error adding task item $i", e)
            }
        }
    }

    private fun addEnhancedTaskItem(views: RemoteViews, context: Context, task: JSONObject, appWidgetId: Int) {
        val taskView = RemoteViews(context.packageName, R.layout.widget_task_item_enhanced)

        val taskId = task.optInt("id", -1)
        val title = task.optString("title", "No title")
        val description = task.optString("description", "")
        val isCompleted = task.optBoolean("isCompleted", false)
        val priority = task.optInt("priority", 1)
        val priorityLabel = task.optString("priorityLabel", "")
        val formattedDueDate = task.optString("formattedDueDate", "")

        // Set checkbox
        taskView.setTextViewText(R.id.task_checkbox, if (isCompleted) "✓" else "○")

        // Set title with strikethrough if completed
        taskView.setTextViewText(R.id.task_title, title)
        if (isCompleted) {
            taskView.setInt(R.id.task_title, "setPaintFlags",
                android.graphics.Paint.STRIKE_THRU_TEXT_FLAG or android.graphics.Paint.ANTI_ALIAS_FLAG)
        }

        // Set description
        if (description.isNotEmpty()) {
            taskView.setViewVisibility(R.id.task_description, android.view.View.VISIBLE)
            taskView.setTextViewText(R.id.task_description, description)
        } else {
            taskView.setViewVisibility(R.id.task_description, android.view.View.GONE)
        }

        // Set priority color bar
        val priorityColor = when (priority) {
            0 -> 0xFFFF5722.toInt() // High - Red
            1 -> 0xFFFF9800.toInt() // Medium - Orange
            else -> 0xFF4CAF50.toInt() // Low - Green
        }
        taskView.setInt(R.id.priority_color_bar, "setBackgroundColor", priorityColor)

        // Set priority badge
        if (priorityLabel.isNotEmpty() && priority == 0) { // Only show HIGH priority
            taskView.setViewVisibility(R.id.priority_badge, android.view.View.VISIBLE)
            taskView.setTextViewText(R.id.priority_badge, priorityLabel)
        } else {
            taskView.setViewVisibility(R.id.priority_badge, android.view.View.GONE)
        }

        // Set category badge
        val category = task.optJSONObject("category")
        if (category != null) {
            taskView.setViewVisibility(R.id.category_badge, android.view.View.VISIBLE)
            taskView.setTextViewText(R.id.category_badge, category.optString("name"))
            val categoryColor = category.optInt("color", 0xFF2196F3.toInt())
            taskView.setInt(R.id.category_badge, "setBackgroundColor", categoryColor)
        } else {
            taskView.setViewVisibility(R.id.category_badge, android.view.View.GONE)
        }

        // Set due date
        if (formattedDueDate.isNotEmpty()) {
            taskView.setViewVisibility(R.id.due_date, android.view.View.VISIBLE)
            taskView.setTextViewText(R.id.due_date, formattedDueDate)
        } else {
            taskView.setViewVisibility(R.id.due_date, android.view.View.GONE)
        }

        // Check if overdue
        val dueDate = task.optLong("dueDate", -1)
        if (dueDate > 0 && dueDate < System.currentTimeMillis() && !isCompleted) {
            taskView.setViewVisibility(R.id.status_indicator, android.view.View.VISIBLE)
            taskView.setTextViewText(R.id.status_indicator, "OVERDUE")
        } else {
            taskView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)
        }

        // Set click handler for task toggle
        if (taskId > 0) {
            val toggleIntent = Intent(context, EnhancedWidgetProvider::class.java).apply {
                action = ACTION_TOGGLE_TASK
                putExtra(EXTRA_TASK_ID, taskId)
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
            }
            val uniqueRequestCode = taskId + appWidgetId * 1000
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                uniqueRequestCode,
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            taskView.setOnClickPendingIntent(R.id.widget_task_item_container, togglePendingIntent)
        }

        views.addView(R.id.task_list, taskView)
    }

    private fun setupButtonHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        // Add Task button
        val addTaskIntent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_TASK"
            putExtra(EXTRA_WIDGET_ID, appWidgetId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addTaskPendingIntent = PendingIntent.getActivity(
            context, appWidgetId * 100 + 1, addTaskIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.add_task_button, addTaskPendingIntent)

        // Refresh button
        val refreshIntent = Intent(context, EnhancedWidgetProvider::class.java).apply {
            action = ACTION_REFRESH_WIDGET
            putExtra(EXTRA_WIDGET_ID, appWidgetId)
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, appWidgetId * 100 + 2, refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)

        // Settings button
        val settingsIntent = Intent(context, MainActivity::class.java).apply {
            action = "WIDGET_SETTINGS"
            putExtra(EXTRA_WIDGET_ID, appWidgetId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val settingsPendingIntent = PendingIntent.getActivity(
            context, appWidgetId * 100 + 3, settingsIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.settings_button, settingsPendingIntent)
    }

    private fun showLoadingState(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, views: RemoteViews) {
        views.setTextViewText(R.id.widget_title, "Todo Tasks")
        views.setTextViewText(R.id.task_count, "Loading...")
        views.setViewVisibility(R.id.progress_section, android.view.View.GONE)
        views.setViewVisibility(R.id.task_list, android.view.View.GONE)
        views.setViewVisibility(R.id.empty_state, android.view.View.GONE)
        setupButtonHandlers(context, views, appWidgetId)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun handleRefreshWidget(context: Context) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = android.content.ComponentName(context, EnhancedWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

        val updateIntent = Intent(context, EnhancedWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
        }
        context.sendBroadcast(updateIntent)
    }

    private fun handleToggleTask(context: Context, taskId: Int, widgetId: Int) {
        // Send command via EventChannel
        val commandIntent = Intent(WidgetEventChannel.ACTION_WIDGET_COMMAND).apply {
            putExtra("command", "toggle_task")
            putExtra("task_id", taskId)
            putExtra("widget_id", widgetId)
            putExtra("timestamp", System.currentTimeMillis())
        }
        context.sendBroadcast(commandIntent)

        // Wake up Flutter app
        try {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = "PROCESS_WIDGET_COMMAND"
                putExtra("task_id", taskId)
                putExtra("widget_id", widgetId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
                addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            }
            context.startActivity(launchIntent)
        } catch (e: Exception) {
            Log.w(TAG, "Could not wake Flutter app: $e")
        }

        // Refresh widget
        handleRefreshWidget(context)
    }
}
