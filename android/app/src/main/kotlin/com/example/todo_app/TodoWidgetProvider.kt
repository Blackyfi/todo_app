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
        
        // Set up button click handlers - USE CORRECT WIDGET ID
        setupButtonClickHandlers(context, views, appWidgetId)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        // Add Task button - opens the app to add task screen
        val addTaskIntent = Intent(context, MainActivity::class.java).apply {
            action = "ADD_TASK"
            putExtra("widget_id", 1)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val addTaskPendingIntent = PendingIntent.getActivity(
            context, 
            appWidgetId * 100 + 1,
            addTaskIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.add_task_button, addTaskPendingIntent)
        
        // Refresh button - syncs data WITHOUT opening app - USE BROADCAST RECEIVER
        val refreshIntent = Intent(context, TodoWidgetProvider::class.java).apply {
            action = "SYNC_WIDGET_DATA"
            putExtra("widget_id", 1)
            // NO ACTIVITY FLAGS - This stays as broadcast
        }
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context, 
            appWidgetId * 100 + 2,
            refreshIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
        
        // Settings button
        val settingsIntent = Intent(context, MainActivity::class.java).apply {
            action = "WIDGET_SETTINGS"
            putExtra("widget_id", 1)
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
            
            // Set up task toggle click handler - this should NOT open the app
            val toggleIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                action = "TOGGLE_TASK_COMPLETION"
                putExtra("task_id", taskId)
                putExtra("widget_id", 1) // FORCE WIDGET ID TO 1 FOR NOW
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                taskId * 1000 + appWidgetId,
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            taskView.setOnClickPendingIntent(R.id.task_item_container, togglePendingIntent)
            
            views.addView(R.id.task_list, taskView)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "SYNC_WIDGET_DATA" -> {
                val widgetId = intent.getIntExtra("widget_id", 1)
                
                // TRY DIRECT WIDGET UPDATE FIRST
                try {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(context, TodoWidgetProvider::class.java)
                    )
                    
                    // Force widget update directly
                    onUpdate(context, appWidgetManager, appWidgetIds)
                    
                    // ALSO trigger background sync to update data
                    val syncIntent = Intent(context, MainActivity::class.java).apply {
                        action = "BACKGROUND_SYNC"
                        putExtra("widget_id", widgetId)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
                    }
                    context.startActivity(syncIntent)
                } catch (e: Exception) {
                    // Fallback to just updating widget with current data
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(context, TodoWidgetProvider::class.java)
                    )
                    onUpdate(context, appWidgetManager, appWidgetIds)
                }
            }
            "TOGGLE_TASK_COMPLETION" -> {
                val taskId = intent.getIntExtra("task_id", -1)
                val widgetId = intent.getIntExtra("widget_id", 1) // DEFAULT TO 1
                if (taskId != -1) {
                    // Start the app in background to toggle task
                    val toggleIntent = Intent(context, MainActivity::class.java).apply {
                        action = "BACKGROUND_TOGGLE_TASK"
                        putExtra("task_id", taskId)
                        putExtra("widget_id", widgetId)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION
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