package com.example.todo_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*

class TodoWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val TAG = "TodoWidgetProvider"
        private const val ACTION_SYNC_WIDGET = "ACTION_SYNC_WIDGET"
        private const val ACTION_TOGGLE_TASK = "ACTION_TOGGLE_TASK"
        private const val ACTION_ADD_TASK = "ACTION_ADD_TASK"
        private const val ACTION_WIDGET_SETTINGS = "ACTION_WIDGET_SETTINGS"
        private const val ACTION_REFRESH_WIDGET = "ACTION_REFRESH_WIDGET"
        
        private const val EXTRA_TASK_ID = "task_id"
        private const val EXTRA_WIDGET_ID = "widget_id"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "=== onUpdate called ===")
        Log.d(TAG, "Widget IDs: ${appWidgetIds.contentToString()}")
        Log.d(TAG, "Number of widgets: ${appWidgetIds.size}")
        
        for (appWidgetId in appWidgetIds) {
            Log.d(TAG, "--- Updating widget ID: $appWidgetId ---")
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
                Log.d(TAG, "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e(TAG, "ERROR updating widget $appWidgetId", e)
                Log.e(TAG, "Error details: ${e.message}")
                Log.e(TAG, "Error stack trace: ${e.stackTrace.contentToString()}")
            }
        }
        Log.d(TAG, "=== onUpdate completed ===")
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        Log.d(TAG, "--- updateAppWidget for ID: $appWidgetId ---")
        
        val views = RemoteViews(context.packageName, R.layout.todo_widget)
        Log.d(TAG, "RemoteViews created for widget $appWidgetId")
        
        try {
            Log.d(TAG, "Getting widget data from HomeWidget plugin...")
            val widgetData = HomeWidgetPlugin.getData(context)
            Log.d(TAG, "Widget data retrieved: ${widgetData != null}")
            
            if (widgetData != null) {
                Log.d(TAG, "Widget data keys: ${widgetData.all.keys}")
                for (key in widgetData.all.keys) {
                    val value = widgetData.getString(key, null)
                    Log.d(TAG, "Data key '$key': ${if (value != null) "${value.length} chars" else "null"}")
                }
            } else {
                Log.e(TAG, "Widget data is null - this is the problem!")
            }
            
            val configData = widgetData?.getString("widget_config", null)
            val tasksData = widgetData?.getString("widget_data", null)
            
            Log.d(TAG, "Config data: ${if (configData != null) "${configData.length} chars" else "null"}")
            Log.d(TAG, "Tasks data: ${if (tasksData != null) "${tasksData.length} chars" else "null"}")
            
            if (configData != null && tasksData != null) {
                Log.d(TAG, "Parsing widget config...")
                val config = JSONObject(configData)
                Log.d(TAG, "Config parsed - widget name: ${config.optString("name", "Unknown")}")
                
                Log.d(TAG, "Parsing tasks data...")
                val data = JSONObject(tasksData)
                val tasks = data.getJSONArray("tasks")
                Log.d(TAG, "Tasks parsed - count: ${tasks.length()}")
                
                // Set widget title
                views.setTextViewText(R.id.widget_title, config.getString("name"))
                Log.d(TAG, "Widget title set: ${config.getString("name")}")
                
                // Set task count
                val taskCount = tasks.length()
                val taskCountText = "$taskCount ${if (taskCount == 1) "task" else "tasks"}"
                views.setTextViewText(R.id.task_count, taskCountText)
                Log.d(TAG, "Task count set: $taskCountText")
                
                // Update task list with full feature set
                Log.d(TAG, "Updating task list...")
                updateTaskList(views, tasks, config, context, appWidgetId)
                Log.d(TAG, "Task list updated successfully")
                
            } else {
                Log.w(TAG, "Missing data - showing loading/error state")
                if (configData == null && tasksData == null) {
                    Log.w(TAG, "No data available at all - showing loading state")
                    views.setTextViewText(R.id.widget_title, "Todo App")
                    views.setTextViewText(R.id.task_count, "Loading...")
                } else if (configData == null) {
                    Log.e(TAG, "Config data is missing!")
                    views.setTextViewText(R.id.widget_title, "Todo App")
                    views.setTextViewText(R.id.task_count, "Config error")
                } else if (tasksData == null) {
                    Log.e(TAG, "Tasks data is missing!")
                    views.setTextViewText(R.id.widget_title, "Todo App")
                    views.setTextViewText(R.id.task_count, "Tasks error")
                } else {
                    Log.e(TAG, "Unknown data state")
                    views.setTextViewText(R.id.widget_title, "Todo App")
                    views.setTextViewText(R.id.task_count, "Unknown error")
                }
                
                // Clear task list when no data
                views.removeAllViews(R.id.task_list)
                Log.d(TAG, "Task list cleared due to missing data")
            }
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateAppWidget", e)
            Log.e(TAG, "Error message: ${e.message}")
            Log.e(TAG, "Error type: ${e.javaClass.simpleName}")
            e.printStackTrace()
            
            // Show error state in widget
            views.setTextViewText(R.id.widget_title, "Todo App")
            views.setTextViewText(R.id.task_count, "Error: ${e.message}")
            views.removeAllViews(R.id.task_list)
        }
        
        try {
            // Set up button click handlers
            Log.d(TAG, "Setting up button click handlers...")
            setupButtonClickHandlers(context, views, appWidgetId)
            Log.d(TAG, "Button click handlers set up successfully")
            
            // Update the widget
            Log.d(TAG, "Calling appWidgetManager.updateAppWidget...")
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId update completed successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "ERROR setting up widget final steps", e)
            Log.e(TAG, "Final setup error: ${e.message}")
            e.printStackTrace()
        }
        
        Log.d(TAG, "--- updateAppWidget completed for ID: $appWidgetId ---")
    }
    
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        Log.d(TAG, "Setting up button click handlers for widget $appWidgetId")
        
        try {
            // Add Task button - opens the app 
            val addTaskIntent = Intent(context, MainActivity::class.java).apply {
                action = "ADD_TASK"
                putExtra(EXTRA_WIDGET_ID, 1)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val addTaskPendingIntent = PendingIntent.getActivity(
                context, 
                appWidgetId * 100 + 1,
                addTaskIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.add_task_button, addTaskPendingIntent)
            Log.d(TAG, "Add task button configured")
            
            // Refresh button - force sync
            val refreshIntent = Intent(context, MainActivity::class.java).apply {
                action = "BACKGROUND_SYNC"
                putExtra(EXTRA_WIDGET_ID, 1)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
            }
            val refreshPendingIntent = PendingIntent.getActivity(
                context, 
                appWidgetId * 100 + 2,
                refreshIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
            Log.d(TAG, "Refresh button configured")
            
            // Settings button - opens the app
            val settingsIntent = Intent(context, MainActivity::class.java).apply {
                action = "WIDGET_SETTINGS"
                putExtra(EXTRA_WIDGET_ID, 1)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val settingsPendingIntent = PendingIntent.getActivity(
                context, 
                appWidgetId * 100 + 3,
                settingsIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.settings_button, settingsPendingIntent)
            Log.d(TAG, "Settings button configured")
            
        } catch (e: Exception) {
            Log.e(TAG, "ERROR setting up button click handlers", e)
            Log.e(TAG, "Button setup error: ${e.message}")
            e.printStackTrace()
        }
    }
    
    private fun updateTaskList(views: RemoteViews, tasks: JSONArray, config: JSONObject, context: Context, appWidgetId: Int) {
        Log.d(TAG, "--- updateTaskList called ---")
        Log.d(TAG, "Tasks count: ${tasks.length()}")
        Log.d(TAG, "Config: ${config}")
        
        try {
            // Clear existing task views first
            views.removeAllViews(R.id.task_list)
            Log.d(TAG, "Existing task views cleared")
            
            val maxTasks = minOf(tasks.length(), config.optInt("maxTasks", 5))
            val showCategories = config.optBoolean("showCategories", true)
            val showPriority = config.optBoolean("showPriority", true)
            val showCompleted = config.optBoolean("showCompleted", false)
            
            Log.d(TAG, "Display settings - maxTasks: $maxTasks, showCategories: $showCategories, showPriority: $showPriority, showCompleted: $showCompleted")
            
            var actualTasksAdded = 0
            
            for (i in 0 until maxTasks) {
                try {
                    val task = tasks.getJSONObject(i)
                    Log.d(TAG, "Processing task $i: ${task.optString("title", "No title")}")
                    
                    val isCompleted = task.getBoolean("isCompleted")
                    
                    // Skip completed tasks if not configured to show them
                    if (isCompleted && !showCompleted) {
                        Log.d(TAG, "Skipping completed task: ${task.optString("title")}")
                        continue
                    }
                    
                    val taskView = RemoteViews(context.packageName, R.layout.widget_task_item)
                    Log.d(TAG, "Created RemoteViews for task item")
                    
                    // Set task title
                    val taskTitle = task.getString("title")
                    taskView.setTextViewText(R.id.task_title, taskTitle)
                    Log.d(TAG, "Set task title: $taskTitle")
                    
                    // Set completion status and styling
                    if (isCompleted) {
                        taskView.setTextViewText(R.id.task_checkbox, "✓")
                        taskView.setTextColor(R.id.task_title, 0xFF999999.toInt())
                        taskView.setTextColor(R.id.task_description, 0xFF999999.toInt())
                        Log.d(TAG, "Task marked as completed with styling")
                    } else {
                        taskView.setTextViewText(R.id.task_checkbox, "○")
                        taskView.setTextColor(R.id.task_title, 0xFF000000.toInt())
                        taskView.setTextColor(R.id.task_description, 0xFF666666.toInt())
                        Log.d(TAG, "Task marked as incomplete with styling")
                    }
                    
                    // Set task description
                    val taskDescription = task.optString("description", "")
                    if (taskDescription.isNotEmpty()) {
                        taskView.setViewVisibility(R.id.task_description, android.view.View.VISIBLE)
                        taskView.setTextViewText(R.id.task_description, taskDescription)
                        Log.d(TAG, "Set task description: $taskDescription")
                    } else {
                        taskView.setViewVisibility(R.id.task_description, android.view.View.GONE)
                        Log.d(TAG, "No description - hiding description view")
                    }
                    
                    // Add more detailed task processing...
                    val taskId = task.getInt("id")
                    
                    // Set click listener for checkbox ONLY - to toggle task
                    val toggleIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                        action = ACTION_TOGGLE_TASK
                        putExtra(EXTRA_TASK_ID, taskId)
                        putExtra(EXTRA_WIDGET_ID, 1)
                    }
                    val togglePendingIntent = PendingIntent.getBroadcast(
                        context,
                        taskId * 1000 + appWidgetId,
                        toggleIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    taskView.setOnClickPendingIntent(R.id.task_checkbox, togglePendingIntent)
                    Log.d(TAG, "Set click listener for task checkbox")
                    
                    views.addView(R.id.task_list, taskView)
                    actualTasksAdded++
                    Log.d(TAG, "Added task view to list (total: $actualTasksAdded)")
                    
                } catch (taskError: Exception) {
                    Log.e(TAG, "ERROR processing task $i", taskError)
                    Log.e(TAG, "Task error: ${taskError.message}")
                }
            }
            
            Log.d(TAG, "Task list update completed - added $actualTasksAdded tasks")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateTaskList", e)
            Log.e(TAG, "TaskList error: ${e.message}")
            e.printStackTrace()
        }
        
        Log.d(TAG, "--- updateTaskList completed ---")
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "=== onReceive called ===")
        Log.d(TAG, "Intent action: ${intent.action}")
        Log.d(TAG, "Intent extras: ${intent.extras}")
        
        try {
            super.onReceive(context, intent)
            Log.d(TAG, "Super.onReceive completed")
            
            when (intent.action) {
                ACTION_REFRESH_WIDGET -> {
                    Log.d(TAG, "Processing REFRESH_WIDGET action")
                    val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                    
                    // Simply trigger a widget update with current data
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(context, TodoWidgetProvider::class.java)
                    )
                    Log.d(TAG, "Triggering widget update for ${appWidgetIds.size} widgets")
                    onUpdate(context, appWidgetManager, appWidgetIds)
                }
                
                ACTION_SYNC_WIDGET -> {
                    Log.d(TAG, "Processing SYNC_WIDGET action")
                    val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                    
                    // Force a sync by starting the app in background
                    val syncIntent = Intent(context, MainActivity::class.java).apply {
                        action = "BACKGROUND_SYNC"
                        putExtra(EXTRA_WIDGET_ID, widgetId)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
                    }
                    
                    try {
                        context.startActivity(syncIntent)
                        Log.d(TAG, "Sync activity started successfully")
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to start sync activity", e)
                        // If can't start activity, just refresh widget with current data
                        val appWidgetManager = AppWidgetManager.getInstance(context)
                        val appWidgetIds = appWidgetManager.getAppWidgetIds(
                            android.content.ComponentName(context, TodoWidgetProvider::class.java)
                        )
                        onUpdate(context, appWidgetManager, appWidgetIds)
                    }
                }
                
                ACTION_TOGGLE_TASK -> {
                    Log.d(TAG, "Processing TOGGLE_TASK action")
                    val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                    val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                    Log.d(TAG, "Toggle task ID: $taskId, Widget ID: $widgetId")
                    
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
                            Log.d(TAG, "Toggle task activity started successfully")
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to start toggle activity", e)
                        }
                    } else {
                        Log.e(TAG, "Invalid task ID for toggle: $taskId")
                    }
                }
                
                AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                    Log.d(TAG, "Processing APPWIDGET_UPDATE action")
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val appWidgetIds = intent.getIntArrayExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS) 
                        ?: appWidgetManager.getAppWidgetIds(
                            android.content.ComponentName(context, TodoWidgetProvider::class.java)
                        )
                    Log.d(TAG, "Update request for widgets: ${appWidgetIds.contentToString()}")
                    onUpdate(context, appWidgetManager, appWidgetIds)
                }
                
                else -> {
                    Log.d(TAG, "Unknown action received: ${intent.action}")
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in onReceive", e)
            Log.e(TAG, "onReceive error: ${e.message}")
            e.printStackTrace()
        }
        
        Log.d(TAG, "=== onReceive completed ===")
    }
}