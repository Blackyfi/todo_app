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
            
            // Set up button click handlers
            setupButtonClickHandlers(context, views, appWidgetId)
            
            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId update completed successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateAppWidget for ID: $appWidgetId", e)
            showErrorState(context, appWidgetManager, appWidgetId, "Failed to load widget data: ${e.message}")
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
    
    // CRITICAL FIX: Use broadcasts for background actions, activities only for UI actions
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        try {
            // Add Task button - opens the app normally
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
            
            // CRITICAL FIX: Refresh button - uses broadcast, no activity
            val refreshIntent = Intent(WidgetBroadcastReceiver.ACTION_WIDGET_BACKGROUND_SYNC).apply {
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
                setClass(context, WidgetBroadcastReceiver::class.java)
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context, 
                appWidgetId * 100 + 2,
                refreshIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
            
            // Settings button - opens the app normally
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
            
            // CRITICAL: Get pending toggles to apply them to display
            val pendingToggles = getPendingToggles(context)
            Log.d(TAG, "Pending toggles: $pendingToggles")
            
            Log.d(TAG, "Display settings - maxTasks: $maxTasks, showCompleted: $showCompleted")
            
            if (tasks.length() == 0) {
                // Show empty state with simple text
                addSimpleTaskItem(views, context, "No tasks yet", "○", "Tap + to add your first task", null, appWidgetId, false)
                Log.d(TAG, "Added empty state message")
                return
            }
            
            var actualTasksAdded = 0
            
            for (i in 0 until minOf(tasks.length(), maxTasks)) {
                try {
                    if (actualTasksAdded >= maxTasks) break
                    
                    val task = tasks.getJSONObject(i)
                    val taskId = task.optInt("id", -1)
                    val originalCompleted = task.optBoolean("isCompleted", false)
                    
                    // CRITICAL: Apply pending toggle to determine display state
                    val isPendingToggle = pendingToggles.contains(taskId.toString())
                    val displayCompleted = if (isPendingToggle) !originalCompleted else originalCompleted
                    
                    // Skip completed tasks if not configured to show them (after applying pending toggles)
                    if (displayCompleted && !showCompleted) {
                        Log.d(TAG, "Skipping completed task: ${task.optString("title")} (after pending toggle)")
                        continue
                    }
                    
                    val taskTitle = task.optString("title", "No title")
                    val taskDescription = task.optString("description", "")
                    val checkbox = if (displayCompleted) "✓" else "○"
                    
                    // Create task item with the display state
                    addSimpleTaskItem(views, context, taskTitle, checkbox, taskDescription, taskId, appWidgetId, displayCompleted)
                    
                    actualTasksAdded++
                    Log.d(TAG, "Added task: $taskTitle (completed: $displayCompleted, pending: $isPendingToggle, total: $actualTasksAdded)")
                    
                } catch (taskError: Exception) {
                    Log.e(TAG, "ERROR processing task $i", taskError)
                }
            }
            
            Log.d(TAG, "Task list update completed - added $actualTasksAdded tasks")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateTaskList", e)
        }
    }

    private fun getPendingToggles(context: Context): Set<String> {
        return try {
            val togglePrefs = context.getSharedPreferences("widget_toggles", Context.MODE_PRIVATE)
            togglePrefs.getStringSet("widget_pending_toggles", emptySet()) ?: emptySet()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting pending toggles", e)
            emptySet()
        }
    }

    // Update the addSimpleTaskItem method signature to include completion state
    private fun addSimpleTaskItem(views: RemoteViews, context: Context, title: String, checkbox: String, description: String, taskId: Int?, appWidgetId: Int, isCompleted: Boolean) {
        try {
            val taskView = RemoteViews(context.packageName, R.layout.widget_task_item)
            
            // Set basic task information
            taskView.setTextViewText(R.id.task_title, title)
            taskView.setTextViewText(R.id.task_checkbox, checkbox)
            
            // CRITICAL: Apply completion styling
            if (isCompleted) {
                // You can add styling for completed tasks here if needed
                // For example, strike-through text or different colors
            }
            
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
            
            // CRITICAL FIX: Task toggle uses broadcast
            if (taskId != null && taskId > 0) {
                val toggleIntent = Intent(WidgetBroadcastReceiver.ACTION_WIDGET_TOGGLE_TASK).apply {
                    putExtra(EXTRA_TASK_ID, taskId)
                    putExtra(EXTRA_WIDGET_ID, appWidgetId)
                    setClass(context, WidgetBroadcastReceiver::class.java)
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
}