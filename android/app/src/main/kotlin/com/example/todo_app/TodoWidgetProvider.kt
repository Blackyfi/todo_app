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
    
    companion object {
        private const val ACTION_SYNC_WIDGET = "ACTION_SYNC_WIDGET"
        private const val ACTION_TOGGLE_TASK = "ACTION_TOGGLE_TASK"
        private const val ACTION_ADD_TASK = "ACTION_ADD_TASK"
        private const val ACTION_WIDGET_SETTINGS = "ACTION_WIDGET_SETTINGS"
        
        private const val EXTRA_TASK_ID = "task_id"
        private const val EXTRA_WIDGET_ID = "widget_id"
    }

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
                updateTaskList(views, tasks, config, context, appWidgetId)
            } else {
                // Default state
                views.setTextViewText(R.id.widget_title, "Todo App")
                views.setTextViewText(R.id.task_count, "Loading...")
            }
        } catch (e: Exception) {
            views.setTextViewText(R.id.widget_title, "Todo App")
            views.setTextViewText(R.id.task_count, "Error loading tasks")
        }
        
        // Set up button click handlers
        setupButtonClickHandlers(context, views, appWidgetId)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        // Add Task button - opens the app 
        val addTaskIntent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_TASK"
            putExtra(EXTRA_WIDGET_ID, 1) // Always use widget ID 1 for now
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addTaskPendingIntent = PendingIntent.getActivity(
            context, 
            appWidgetId * 100 + 1,
            addTaskIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.add_task_button, addTaskPendingIntent)
        
        // Refresh button - uses broadcast to avoid opening app
        val refreshIntent = Intent(context, TodoWidgetProvider::class.java).apply {
            action = ACTION_SYNC_WIDGET
            putExtra(EXTRA_WIDGET_ID, 1) // Always use widget ID 1 for now
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, 
            appWidgetId * 100 + 2,
            refreshIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
        
        // Settings button - opens the app
        val settingsIntent = Intent(context, MainActivity::class.java).apply {
            action = "WIDGET_SETTINGS"
            putExtra(EXTRA_WIDGET_ID, 1) // Always use widget ID 1 for now
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val settingsPendingIntent = PendingIntent.getActivity(
            context, 
            appWidgetId * 100 + 3,
            settingsIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.settings_button, settingsPendingIntent)
    }
    
    private fun updateTaskList(views: RemoteViews, tasks: JSONArray, config: JSONObject, context: Context, appWidgetId: Int) {
        // Clear existing task views first
        views.removeAllViews(R.id.task_list)
        
        val maxTasks = minOf(tasks.length(), config.optInt("maxTasks", 5))
        
        for (i in 0 until maxTasks) {
            val task = tasks.getJSONObject(i)
            val taskId = task.getInt("id")
            val taskTitle = task.getString("title")
            val isCompleted = task.getBoolean("isCompleted")
            
            val taskView = RemoteViews(views.`package`, R.layout.widget_task_item)
            taskView.setTextViewText(R.id.task_title, taskTitle)
            
            // Set completion status
            if (isCompleted) {
                taskView.setTextViewText(R.id.task_checkbox, "✓")
                taskView.setTextColor(R.id.task_title, 0xFF999999.toInt())
            } else {
                taskView.setTextViewText(R.id.task_checkbox, "○")
                taskView.setTextColor(R.id.task_title, 0xFF000000.toInt())
            }
            
            // IMPORTANT: Set click listeners for specific parts
            // Click listener for checkbox ONLY - to toggle task
            val toggleIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                action = ACTION_TOGGLE_TASK
                putExtra(EXTRA_TASK_ID, taskId)
                putExtra(EXTRA_WIDGET_ID, 1) // Always use widget ID 1 for now
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                taskId * 1000 + appWidgetId, // Unique request code
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            // Only set click listener on the checkbox, NOT the entire container
            taskView.setOnClickPendingIntent(R.id.task_checkbox, togglePendingIntent)
            
            views.addView(R.id.task_list, taskView)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_SYNC_WIDGET -> {
                val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                
                // Force a sync by starting the app in background
                val syncIntent = Intent(context, MainActivity::class.java).apply {
                    action = "BACKGROUND_SYNC"
                    putExtra(EXTRA_WIDGET_ID, widgetId)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
                }
                
                try {
                    context.startActivity(syncIntent)
                } catch (e: Exception) {
                    // If can't start activity, just refresh widget with current data
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(context, TodoWidgetProvider::class.java)
                    )
                    onUpdate(context, appWidgetManager, appWidgetIds)
                }
            }
            
            ACTION_TOGGLE_TASK -> {
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                
                if (taskId != -1) {
                    // Start the app in background to toggle task
                    val toggleIntent = Intent(context, MainActivity::class.java).apply {
                        action = "BACKGROUND_TOGGLE_TASK"
                        putExtra(EXTRA_TASK_ID, taskId)
                        putExtra(EXTRA_WIDGET_ID, widgetId)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
                    }
                    
                    try {
                        context.startActivity(toggleIntent)
                    } catch (e: Exception) {
                        // Handle error silently
                    }
                }
            }
            
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS) 
                    ?: appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(context, TodoWidgetProvider::class.java)
                    )
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
        }
    }
}