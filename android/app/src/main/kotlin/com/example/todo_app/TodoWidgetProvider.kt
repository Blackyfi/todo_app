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
        
        // CRITICAL: Different action types
        private const val ACTION_ADD_TASK = "ACTION_ADD_TASK"
        private const val ACTION_WIDGET_SETTINGS = "ACTION_WIDGET_SETTINGS"
        private const val ACTION_REFRESH_WIDGET = "ACTION_REFRESH_WIDGET"
        private const val ACTION_BACKGROUND_SYNC = "ACTION_BACKGROUND_SYNC"
        private const val ACTION_TOGGLE_TASK = "ACTION_TOGGLE_TASK"
        
        private const val EXTRA_TASK_ID = "task_id"
        private const val EXTRA_WIDGET_ID = "widget_id"
        
        // CRITICAL: Use consistent data keys
        private const val WIDGET_DATA_KEY = "widget_data"
        private const val WIDGET_CONFIG_KEY = "widget_config"
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
                // Show error state instead of crashing
                showErrorState(context, appWidgetManager, appWidgetId, e.message ?: "Unknown error")
            }
        }
        Log.d(TAG, "=== onUpdate completed ===")
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        Log.d(TAG, "--- updateAppWidget for ID: $appWidgetId ---")
        
        try {
            // Create RemoteViews with error handling
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            Log.d(TAG, "RemoteViews created for widget $appWidgetId")
            
            // CRITICAL FIX: Try multiple SharedPreferences sources
            val preferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            Log.d(TAG, "SharedPreferences retrieved")
            
            // Log all available keys for debugging from both sources - FIXED VERSION
            logAllPreferencesKeysSafely(preferences, "HomeWidgetPreferences")
            logAllPreferencesKeysSafely(flutterPrefs, "FlutterSharedPreferences")
            
            // Try to get data from multiple possible key patterns
            var configData = preferences.getString(WIDGET_CONFIG_KEY, null)
            var tasksData = preferences.getString(WIDGET_DATA_KEY, null)
            
            // If not found, try alternative keys
            if (configData == null) {
                configData = preferences.getString("flutter.$WIDGET_CONFIG_KEY", null)
                if (configData == null) {
                    configData = flutterPrefs.getString("flutter.$WIDGET_CONFIG_KEY", null)
                }
            }
            
            if (tasksData == null) {
                tasksData = preferences.getString("flutter.$WIDGET_DATA_KEY", null)
                if (tasksData == null) {
                    tasksData = flutterPrefs.getString("flutter.$WIDGET_DATA_KEY", null)
                }
            }
            
            Log.d(TAG, "Config data found: ${configData != null}, length: ${configData?.length ?: 0}")
            Log.d(TAG, "Tasks data found: ${tasksData != null}, length: ${tasksData?.length ?: 0}")
            
            if (configData != null) {
                Log.d(TAG, "Config data preview: ${configData.take(200)}...")
            }
            if (tasksData != null) {
                Log.d(TAG, "Tasks data preview: ${tasksData.take(200)}...")
            }
            
            if (configData == null || tasksData == null) {
                Log.w(TAG, "Missing data - showing default state with retry")
                showDefaultState(context, appWidgetManager, appWidgetId)
                return
            }
            
            // Parse JSON data safely
            val config = JSONObject(configData)
            val data = JSONObject(tasksData)
            val tasks = data.optJSONArray("tasks") ?: JSONArray()
            
            Log.d(TAG, "Successfully parsed data - tasks count: ${tasks.length()}")
            
            // Set widget title
            val widgetName = config.optString("name", "Todo App")
            views.setTextViewText(R.id.widget_title, widgetName)
            Log.d(TAG, "Widget title set: $widgetName")
            
            // Set task count
            val taskCount = tasks.length()
            val taskCountText = "$taskCount ${if (taskCount == 1) "task" else "tasks"}"
            views.setTextViewText(R.id.task_count, taskCountText)
            Log.d(TAG, "Task count set: $taskCountText")
            
            // Update task list
            updateTaskList(views, tasks, config, context, appWidgetId)
            
            // CRITICAL FIX: Set up different button click handlers based on action type
            setupButtonClickHandlers(context, views, appWidgetId)
            
            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId update completed successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateAppWidget for ID: $appWidgetId", e)
            showErrorState(context, appWidgetManager, appWidgetId, "Failed to load widget data: ${e.message}")
        }
    }
    
    // FIXED: Safe preferences logging that handles different data types
    private fun logAllPreferencesKeysSafely(preferences: android.content.SharedPreferences, source: String) {
        try {
            val allEntries = preferences.all
            Log.d(TAG, "=== $source Keys (${allEntries.size}) ===")
            
            for ((key, value) in allEntries) {
                when (value) {
                    is String -> {
                        Log.d(TAG, "$source - Key: $key, Type: String, Length: ${value.length}")
                        if (value.length < 200) {
                            Log.d(TAG, "$source - Key: $key, Value: $value")
                        } else {
                            Log.d(TAG, "$source - Key: $key, Value preview: ${value.take(100)}...")
                        }
                    }
                    is Boolean -> {
                        Log.d(TAG, "$source - Key: $key, Type: Boolean, Value: $value")
                    }
                    is Int -> {
                        Log.d(TAG, "$source - Key: $key, Type: Int, Value: $value")
                    }
                    is Long -> {
                        Log.d(TAG, "$source - Key: $key, Type: Long, Value: $value")
                    }
                    is Float -> {
                        Log.d(TAG, "$source - Key: $key, Type: Float, Value: $value")
                    }
                    is Set<*> -> {
                        Log.d(TAG, "$source - Key: $key, Type: Set, Size: ${value.size}")
                    }
                    else -> {
                        Log.d(TAG, "$source - Key: $key, Type: ${value?.javaClass?.simpleName ?: "null"}, Value: $value")
                    }
                }
            }
            Log.d(TAG, "=== End $source Keys ===")
        } catch (e: Exception) {
            Log.e(TAG, "Error logging preferences for $source", e)
        }
    }
    
    private fun showDefaultState(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            views.setTextViewText(R.id.widget_title, "Todo App")
            views.setTextViewText(R.id.task_count, "Loading tasks...")
            views.removeAllViews(R.id.task_list)
            
            // Add a simple message
            val messageView = RemoteViews(context.packageName, R.layout.widget_task_item)
            messageView.setTextViewText(R.id.task_title, "Tap + to add your first task")
            messageView.setTextViewText(R.id.task_checkbox, "○")
            messageView.setViewVisibility(R.id.task_description, android.view.View.GONE)
            messageView.setViewVisibility(R.id.priority_badge, android.view.View.GONE)
            messageView.setViewVisibility(R.id.category_badge, android.view.View.GONE)
            messageView.setViewVisibility(R.id.due_date, android.view.View.GONE)
            messageView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)
            
            views.addView(R.id.task_list, messageView)
            
            // Set up basic button handlers
            setupButtonClickHandlers(context, views, appWidgetId)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Default state displayed for widget $appWidgetId")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing default state", e)
            showErrorState(context, appWidgetManager, appWidgetId, "Setup error")
        }
    }
    
    private fun showErrorState(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, errorMessage: String) {
        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            views.setTextViewText(R.id.widget_title, "Todo App")
            views.setTextViewText(R.id.task_count, "Can't load widget")
            views.removeAllViews(R.id.task_list)
            
            // Add error message
            val errorView = RemoteViews(context.packageName, R.layout.widget_task_item)
            errorView.setTextViewText(R.id.task_title, "Tap refresh or open app")
            errorView.setTextViewText(R.id.task_checkbox, "!")
            errorView.setTextViewText(R.id.task_description, errorMessage)
            errorView.setViewVisibility(R.id.task_description, android.view.View.VISIBLE)
            errorView.setViewVisibility(R.id.priority_badge, android.view.View.GONE)
            errorView.setViewVisibility(R.id.category_badge, android.view.View.GONE)
            errorView.setViewVisibility(R.id.due_date, android.view.View.GONE)
            errorView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)
            
            views.addView(R.id.task_list, errorView)
            
            // Set up basic button handlers
            setupButtonClickHandlers(context, views, appWidgetId)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Error state displayed for widget $appWidgetId: $errorMessage")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing error state", e)
        }
    }
    
    // CRITICAL FIX: Different PendingIntent types for different actions
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        try {
            // Add Task button - opens app
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
            
            // CRITICAL FIX: Refresh button - background action, doesn't open app
            val refreshIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                action = ACTION_BACKGROUND_SYNC
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context, 
                appWidgetId * 100 + 2,
                refreshIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
            
            // Settings button - opens app
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
            
            Log.d(TAG, "Button click handlers set up successfully for widget $appWidgetId")
        } catch (e: Exception) {
            Log.e(TAG, "ERROR setting up button click handlers for widget $appWidgetId", e)
        }
    }
    
    private fun updateTaskList(views: RemoteViews, tasks: JSONArray, config: JSONObject, context: Context, appWidgetId: Int) {
        try {
            Log.d(TAG, "--- updateTaskList called ---")
            Log.d(TAG, "Tasks count: ${tasks.length()}")
            
            views.removeAllViews(R.id.task_list)
            
            val maxTasks = minOf(tasks.length(), config.optInt("maxTasks", 3))
            val showCompleted = config.optBoolean("showCompleted", false)
            
            Log.d(TAG, "Display settings - maxTasks: $maxTasks, showCompleted: $showCompleted")
            
            if (tasks.length() == 0) {
                // Show empty state with simple text
                addSimpleTaskItem(views, context, "No tasks yet", "○", "Tap + to add your first task", null, appWidgetId)
                Log.d(TAG, "Added empty state message")
                return
            }
            
            var actualTasksAdded = 0
            
            for (i in 0 until minOf(tasks.length(), maxTasks)) {
                try {
                    if (actualTasksAdded >= maxTasks) break
                    
                    val task = tasks.getJSONObject(i)
                    val isCompleted = task.optBoolean("isCompleted", false)
                    
                    // Skip completed tasks if not configured to show them
                    if (isCompleted && !showCompleted) {
                        Log.d(TAG, "Skipping completed task: ${task.optString("title")}")
                        continue
                    }
                    
                    val taskTitle = task.optString("title", "No title")
                    val taskDescription = task.optString("description", "")
                    val checkbox = if (isCompleted) "✓" else "○"
                    val taskId = task.optInt("id", -1)
                    
                    // Create simplified task item with toggle functionality
                    addSimpleTaskItem(views, context, taskTitle, checkbox, taskDescription, taskId, appWidgetId)
                    
                    actualTasksAdded++
                    Log.d(TAG, "Added task: $taskTitle (total: $actualTasksAdded)")
                    
                } catch (taskError: Exception) {
                    Log.e(TAG, "ERROR processing task $i", taskError)
                }
            }
            
            Log.d(TAG, "Task list update completed - added $actualTasksAdded tasks")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateTaskList", e)
        }
    }

    // CRITICAL FIX: Add task toggle functionality
    private fun addSimpleTaskItem(views: RemoteViews, context: Context, title: String, checkbox: String, description: String, taskId: Int?, appWidgetId: Int) {
        try {
            val taskView = RemoteViews(context.packageName, R.layout.widget_task_item)
            
            // Set basic task information
            taskView.setTextViewText(R.id.task_title, title)
            taskView.setTextViewText(R.id.task_checkbox, checkbox)
            
            // Set description if not empty
            if (description.isNotEmpty()) {
                taskView.setViewVisibility(R.id.task_description, android.view.View.VISIBLE)
                taskView.setTextViewText(R.id.task_description, description)
            } else {
                taskView.setViewVisibility(R.id.task_description, android.view.View.GONE)
            }
            
            // Hide complex elements to avoid issues
            taskView.setViewVisibility(R.id.priority_badge, android.view.View.GONE)
            taskView.setViewVisibility(R.id.category_badge, android.view.View.GONE)
            taskView.setViewVisibility(R.id.due_date, android.view.View.GONE)
            taskView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)
            
            // CRITICAL FIX: Add toggle functionality for tasks with valid IDs
            if (taskId != null && taskId > 0) {
                val toggleIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TASK
                    putExtra(EXTRA_TASK_ID, taskId)
                    putExtra(EXTRA_WIDGET_ID, appWidgetId)
                }
                val togglePendingIntent = PendingIntent.getBroadcast(
                    context,
                    taskId + appWidgetId * 1000, // Unique ID
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                taskView.setOnClickPendingIntent(R.id.task_checkbox, togglePendingIntent)
            }
            
            views.addView(R.id.task_list, taskView)
            
        } catch (e: Exception) {
            Log.e(TAG, "ERROR adding simple task item: $title", e)
        }
    }
    
    // CRITICAL FIX: Handle different widget actions
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "=== onReceive called ===")
        Log.d(TAG, "Intent action: ${intent.action}")
        
        try {
            when (intent.action) {
                ACTION_BACKGROUND_SYNC -> {
                    Log.d(TAG, "Handling background sync action")
                    handleBackgroundSync(context, intent)
                }
                
                ACTION_TOGGLE_TASK -> {
                    Log.d(TAG, "Handling task toggle action")
                    handleTaskToggle(context, intent)
                }
                
                ACTION_REFRESH_WIDGET -> {
                    Log.d(TAG, "Handling widget refresh action")
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(context, TodoWidgetProvider::class.java)
                    )
                    onUpdate(context, appWidgetManager, appWidgetIds)
                }
                
                AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                    super.onReceive(context, intent)
                }
                
                else -> {
                    super.onReceive(context, intent)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in onReceive", e)
        }
        
        Log.d(TAG, "=== onReceive completed ===")
    }

    // CRITICAL FIX: Background sync without opening app
    private fun handleBackgroundSync(context: Context, intent: Intent) {
        try {
            Log.d(TAG, "Performing background sync")
            
            // Send background sync message to Flutter app
            val syncIntent = Intent(context, MainActivity::class.java).apply {
                action = "BACKGROUND_SYNC"
                putExtra(EXTRA_WIDGET_ID, intent.getIntExtra(EXTRA_WIDGET_ID, 1))
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
            }
            
            // Start activity in background without bringing to foreground
            context.startActivity(syncIntent)
            
            // Also trigger widget update
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, TodoWidgetProvider::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
            
            Log.d(TAG, "Background sync completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error in background sync", e)
        }
    }

    // CRITICAL FIX: Task toggle without opening app
    private fun handleTaskToggle(context: Context, intent: Intent) {
        try {
            val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
            val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, 1)
            
            Log.d(TAG, "Toggling task: TaskID=$taskId, WidgetID=$widgetId")
            
            if (taskId > 0) {
                // Send background toggle message to Flutter app
                val toggleIntent = Intent(context, MainActivity::class.java).apply {
                    action = "BACKGROUND_TOGGLE_TASK"
                    putExtra(EXTRA_TASK_ID, taskId)
                    putExtra(EXTRA_WIDGET_ID, widgetId)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
                }
                
                // Start activity in background without bringing to foreground
                context.startActivity(toggleIntent)
                
                Log.d(TAG, "Task toggle message sent")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in task toggle", e)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "Widget enabled")
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "Widget disabled")
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        Log.d(TAG, "Widget deleted: ${appWidgetIds.contentToString()}")
    }
}