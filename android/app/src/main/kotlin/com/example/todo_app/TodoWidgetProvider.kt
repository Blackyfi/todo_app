package com.example.todo_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import org.json.JSONArray

class TodoWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val widgetData = HomeWidgetPlugin.getData(context)
        val views = RemoteViews(context.packageName, R.layout.todo_widget)
        
        try {
            val configData = widgetData.getString("widget_config", null)
            val tasksData = widgetData.getString("widget_data", null)
            
            if (configData != null && tasksData != null) {
                val config = JSONObject(configData)
                val data = JSONObject(tasksData)
                val tasks = data.getJSONArray("tasks")
                
                // Set widget title
                views.setTextViewText(R.id.widget_title, config.getString("name"))
                
                // Set task count
                val taskCount = tasks.length()
                views.setTextViewText(R.id.task_count, "$taskCount ${if (taskCount == 1) "task" else "tasks"}")
                
                // Update task list
                updateTaskList(views, tasks, config)
            } else {
                // Default state
                views.setTextViewText(R.id.widget_title, "Todo App")
                views.setTextViewText(R.id.task_count, "Loading...")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.widget_title, "Todo App")
            views.setTextViewText(R.id.task_count, "Error loading tasks")
        }
        
        // Set up button click handlers (but don't set default click handlers)
        setupButtonClickHandlers(context, views, appWidgetId)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        // Add Task button - opens the app to add task screen
        val addTaskIntent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_TASK"
            putExtra("widget_id", appWidgetId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addTaskPendingIntent = PendingIntent.getActivity(
            context, 
            appWidgetId * 100 + 1, // Unique request code
            addTaskIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.add_task_button, addTaskPendingIntent)
        
        // Refresh button - triggers widget update
        val refreshIntent = Intent(context, TodoWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, 
            appWidgetId * 100 + 2, // Unique request code
            refreshIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
        
        // Settings button - opens the app to widget settings
        val settingsIntent = Intent(context, MainActivity::class.java).apply {
            action = "WIDGET_SETTINGS"
            putExtra("widget_id", appWidgetId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val settingsPendingIntent = PendingIntent.getActivity(
            context, 
            appWidgetId * 100 + 3, // Unique request code
            settingsIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.settings_button, settingsPendingIntent)
        
        // IMPORTANT: Don't set a default click handler for the entire widget
        // This prevents automatic app launching when the widget is added
    }
    
    private fun updateTaskList(views: RemoteViews, tasks: JSONArray, config: JSONObject) {
        // Clear existing task views first
        views.removeAllViews(R.id.task_list)
        
        val maxTasks = minOf(tasks.length(), config.optInt("maxTasks", 5))
        
        for (i in 0 until maxTasks) {
            val task = tasks.getJSONObject(i)
            val taskTitle = task.getString("title")
            val isCompleted = task.getBoolean("isCompleted")
            
            val taskView = RemoteViews(views.`package`, R.layout.widget_task_item)
            taskView.setTextViewText(R.id.task_title, taskTitle)
            
            // Set completion status
            if (isCompleted) {
                taskView.setTextViewText(R.id.task_checkbox, "✓")
                taskView.setTextColor(R.id.task_title, 0xFF999999.toInt()) // Gray out completed tasks
            } else {
                taskView.setTextViewText(R.id.task_checkbox, "○")
                taskView.setTextColor(R.id.task_title, 0xFF000000.toInt()) // Black for active tasks
            }
            
            views.addView(R.id.task_list, taskView)
        }
    }
}