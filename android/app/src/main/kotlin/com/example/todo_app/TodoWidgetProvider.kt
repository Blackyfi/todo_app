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

        // CRITICAL: Use fully qualified action names to ensure they're unique
        private const val ACTION_REFRESH_WIDGET = "com.example.todo_app.ACTION_REFRESH_WIDGET"
        private const val ACTION_ADD_TASK = "com.example.todo_app.ACTION_ADD_TASK"
        private const val ACTION_WIDGET_SETTINGS = "com.example.todo_app.ACTION_WIDGET_SETTINGS"
        private const val ACTION_TOGGLE_TASK = "com.example.todo_app.ACTION_TOGGLE_TASK"

        private const val EXTRA_TASK_ID = "task_id"
        private const val EXTRA_WIDGET_ID = "widget_id"

        // Data keys
        private const val WIDGET_DATA_KEY = "widget_data"
        private const val WIDGET_CONFIG_KEY = "widget_config"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "=== onUpdate called ===")
        Log.d(TAG, "Widget IDs: ${appWidgetIds.contentToString()}")
        
        for (appWidgetId in appWidgetIds) {
            Log.d(TAG, "--- Updating widget ID: $appWidgetId ---")
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
                Log.d(TAG, "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e(TAG, "ERROR updating widget $appWidgetId", e)
                showErrorState(context, appWidgetManager, appWidgetId, "Failed to load: ${e.message}")
            }
        }
        Log.d(TAG, "=== onUpdate completed ===")
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "========================================")
        Log.d(TAG, "onReceive called with action: ${intent.action}")
        Log.d(TAG, "Intent extras: ${intent.extras?.keySet()?.joinToString()}")
        Log.d(TAG, "========================================")

        // Handle our custom actions BEFORE calling super
        when (intent.action) {
            ACTION_REFRESH_WIDGET -> {
                Log.d(TAG, ">>> Handling refresh widget action")
                handleRefreshWidget(context)
                return  // Don't call super for custom actions
            }
            ACTION_TOGGLE_TASK -> {
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, 1)
                Log.d(TAG, ">>> Handling toggle task: TaskID=$taskId, WidgetID=$widgetId")
                handleToggleTask(context, taskId, widgetId)
                return  // Don't call super for custom actions
            }
        }

        // For standard widget actions (APPWIDGET_UPDATE, etc.), call super
        super.onReceive(context, intent)
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        Log.d(TAG, "--- updateAppWidget for ID: $appWidgetId ---")
        
        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            Log.d(TAG, "RemoteViews created for widget $appWidgetId")
            
            // Get data from SharedPreferences with multiple fallback attempts
            val preferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            Log.d(TAG, ">>> Checking SharedPreferences for widget data...")
            Log.d(TAG, ">>> HomeWidgetPreferences keys: ${preferences.all.keys}")
            Log.d(TAG, ">>> FlutterSharedPreferences keys: ${flutterPrefs.all.keys}")

            // Try multiple key combinations
            var configData = preferences.getString(WIDGET_CONFIG_KEY, null)
                ?: preferences.getString("flutter.$WIDGET_CONFIG_KEY", null)
                ?: flutterPrefs.getString("flutter.$WIDGET_CONFIG_KEY", null)

            var tasksData = preferences.getString(WIDGET_DATA_KEY, null)
                ?: preferences.getString("flutter.$WIDGET_DATA_KEY", null)
                ?: flutterPrefs.getString("flutter.$WIDGET_DATA_KEY", null)

            Log.d(TAG, ">>> Config found: ${configData != null}, Tasks found: ${tasksData != null}")
            if (tasksData != null) {
                Log.d(TAG, ">>> Tasks data preview (first 200 chars): ${tasksData.take(200)}")
            }
            
            if (configData == null || tasksData == null) {
                Log.w(TAG, "Missing data - showing loading state")
                showLoadingState(context, appWidgetManager, appWidgetId)
                return
            }
            
            // Parse JSON data
            val config = JSONObject(configData)
            val data = JSONObject(tasksData)
            val tasks = data.optJSONArray("tasks") ?: JSONArray()
            
            Log.d(TAG, "Parsed data - tasks count: ${tasks.length()}")
            
            // Apply widget configuration
            val widgetName = config.optString("name", "Todo Tasks")
            val maxTasks = config.optInt("maxTasks", 3)
            val showCompleted = config.optBoolean("showCompleted", false)
            
            // Set widget title
            views.setTextViewText(R.id.widget_title, widgetName)
            
            // Filter and display tasks
            updateTaskList(views, tasks, maxTasks, showCompleted, context, appWidgetId)
            
            // Set up button click handlers - CRITICAL FIX
            setupButtonClickHandlers(context, views, appWidgetId)
            
            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId update completed successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateAppWidget for ID: $appWidgetId", e)
            showErrorState(context, appWidgetManager, appWidgetId, "Error: ${e.message}")
        }
    }
    
    private fun showLoadingState(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            views.setTextViewText(R.id.widget_title, "Todo Tasks")
            views.setTextViewText(R.id.task_count, "Loading tasks...")
            views.removeAllViews(R.id.task_list)
            
            // Add loading message
            val loadingView = RemoteViews(context.packageName, R.layout.widget_task_item)
            loadingView.setTextViewText(R.id.task_title, "Loading...")
            loadingView.setTextViewText(R.id.task_checkbox, "○")
            loadingView.setViewVisibility(R.id.task_description, android.view.View.GONE)
            loadingView.setViewVisibility(R.id.priority_badge, android.view.View.GONE)
            loadingView.setViewVisibility(R.id.category_badge, android.view.View.GONE)
            loadingView.setViewVisibility(R.id.due_date, android.view.View.GONE)
            loadingView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)
            
            views.addView(R.id.task_list, loadingView)
            setupButtonClickHandlers(context, views, appWidgetId)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing loading state", e)
        }
    }
    
    private fun showErrorState(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, errorMessage: String) {
        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            views.setTextViewText(R.id.widget_title, "Todo Tasks")
            views.setTextViewText(R.id.task_count, "Error loading")
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
            setupButtonClickHandlers(context, views, appWidgetId)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing error state", e)
        }
    }
    
    // CRITICAL FIX: Proper action handling
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        try {
            // Add Task button - opens app (UI action)
            val addTaskIntent = Intent(context, MainActivity::class.java).apply {
                action = "ADD_TASK"
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val addTaskPendingIntent = PendingIntent.getActivity(
                context, 
                appWidgetId * 100 + 1,
                addTaskIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.add_task_button, addTaskPendingIntent)
            
            // CRITICAL: Refresh button uses broadcast (background action)
            val refreshIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                action = ACTION_REFRESH_WIDGET
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
            }
            val refreshPendingIntent = PendingIntent.getBroadcast(
                context, 
                appWidgetId * 100 + 2,
                refreshIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)
            
            // Widget Settings button - opens app (UI action)
            val settingsIntent = Intent(context, MainActivity::class.java).apply {
                action = "WIDGET_SETTINGS"
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val settingsPendingIntent = PendingIntent.getActivity(
                context, 
                appWidgetId * 100 + 3,
                settingsIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.settings_button, settingsPendingIntent)
            
            Log.d(TAG, "Button click handlers set up for widget $appWidgetId")
        } catch (e: Exception) {
            Log.e(TAG, "ERROR setting up button handlers", e)
        }
    }
    
    private fun updateTaskList(views: RemoteViews, tasks: JSONArray, maxTasks: Int, showCompleted: Boolean, context: Context, appWidgetId: Int) {
        try {
            Log.d(TAG, "--- updateTaskList: ${tasks.length()} tasks, maxTasks=$maxTasks, showCompleted=$showCompleted ---")
            
            views.removeAllViews(R.id.task_list)
            
            if (tasks.length() == 0) {
                addSimpleTaskItem(views, context, "No tasks yet", "○", "Tap + to add your first task", null, appWidgetId)
                views.setTextViewText(R.id.task_count, "0 tasks")
                return
            }
            
            var visibleTaskCount = 0
            var actualTasksAdded = 0
            
            // Process tasks according to widget settings
            for (i in 0 until tasks.length()) {
                if (actualTasksAdded >= maxTasks) break
                
                try {
                    val task = tasks.getJSONObject(i)
                    val taskId = task.optInt("id", -1)
                    val isCompleted = task.optBoolean("isCompleted", false)
                    
                    // Apply showCompleted filter
                    if (isCompleted && !showCompleted) {
                        Log.d(TAG, "Skipping completed task (showCompleted=false): ${task.optString("title")}")
                        continue
                    }
                    
                    visibleTaskCount++
                    
                    val taskTitle = task.optString("title", "No title")
                    val taskDescription = task.optString("description", "")
                    val checkbox = if (isCompleted) "✓" else "○"
                    
                    addSimpleTaskItem(views, context, taskTitle, checkbox, taskDescription, taskId, appWidgetId)
                    actualTasksAdded++
                    
                    Log.d(TAG, "Added task: $taskTitle (completed: $isCompleted)")
                    
                } catch (taskError: Exception) {
                    Log.e(TAG, "ERROR processing task $i", taskError)
                }
            }
            
            // Update task count display
            val taskCountText = "$visibleTaskCount ${if (visibleTaskCount == 1) "task" else "tasks"}"
            views.setTextViewText(R.id.task_count, taskCountText)
            
            Log.d(TAG, "Task list update completed - visible: $visibleTaskCount, added: $actualTasksAdded")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateTaskList", e)
        }
    }

    private fun addSimpleTaskItem(views: RemoteViews, context: Context, title: String, checkbox: String, description: String, taskId: Int?, appWidgetId: Int) {
        try {
            Log.d(TAG, ">>> Adding task item: title='$title', taskId=$taskId, appWidgetId=$appWidgetId")
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

            // Hide complex elements
            taskView.setViewVisibility(R.id.priority_badge, android.view.View.GONE)
            taskView.setViewVisibility(R.id.category_badge, android.view.View.GONE)
            taskView.setViewVisibility(R.id.due_date, android.view.View.GONE)
            taskView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)

            // CRITICAL FIX: Task toggle uses broadcast for background operation
            if (taskId != null && taskId > 0) {
                Log.d(TAG, ">>> Setting up click handler for task $taskId")
                val toggleIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TASK
                    putExtra(EXTRA_TASK_ID, taskId)
                    putExtra(EXTRA_WIDGET_ID, appWidgetId)
                }
                Log.d(TAG, ">>> Created intent with action: $ACTION_TOGGLE_TASK, taskId=$taskId, widgetId=$appWidgetId")

                val uniqueRequestCode = taskId + appWidgetId * 1000
                val togglePendingIntent = PendingIntent.getBroadcast(
                    context,
                    uniqueRequestCode,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                Log.d(TAG, ">>> Created PendingIntent with request code: $uniqueRequestCode")

                // CRITICAL: Set click listener on the entire task item container, not just checkbox
                taskView.setOnClickPendingIntent(R.id.widget_task_item_container, togglePendingIntent)
                Log.d(TAG, ">>> Toggle handler SET for task ID: $taskId on widget_task_item_container")
            } else {
                Log.w(TAG, ">>> Skipping click handler - invalid taskId: $taskId")
            }

            views.addView(R.id.task_list, taskView)
            Log.d(TAG, ">>> Task item added to widget successfully")

        } catch (e: Exception) {
            Log.e(TAG, ">>> ERROR adding task item: $title", e)
        }
    }
    
    private fun handleRefreshWidget(context: Context) {
        try {
            Log.d(TAG, "=== HANDLING REFRESH WIDGET ===")
            
            // Trigger widget update by sending update intent
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, TodoWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            Log.d(TAG, "Found ${appWidgetIds.size} widgets to refresh")
            
            // Force update all widgets
            val updateIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            context.sendBroadcast(updateIntent)
            
            Log.d(TAG, "=== REFRESH WIDGET COMPLETE ===")
        } catch (e: Exception) {
            Log.e(TAG, "Error handling refresh widget", e)
        }
    }
    
    private fun handleToggleTask(context: Context, taskId: Int, widgetId: Int) {
        try {
            Log.d(TAG, "=== HANDLING TOGGLE TASK: TaskID=$taskId, WidgetID=$widgetId ===")

            // CRITICAL FIX: Store the toggle request in SharedPreferences with correct key format
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("command", "toggle_task")
                .putInt("task_id", taskId)
                .putInt("widget_id", widgetId)
                .putLong("timestamp", System.currentTimeMillis())
                .apply()

            Log.d(TAG, "Toggle command stored in SharedPreferences with keys: command, task_id, widget_id, timestamp")

            // Also store in flutter-prefixed keys for maximum compatibility
            prefs.edit()
                .putString("flutter.command", "toggle_task")
                .putInt("flutter.task_id", taskId)
                .putInt("flutter.widget_id", widgetId)
                .putLong("flutter.timestamp", System.currentTimeMillis())
                .apply()

            // CRITICAL: Try to use HomeWidget background callback first (no UI)
            try {
                // Use HomeWidget's background execution
                es.antonborri.home_widget.HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    android.net.Uri.parse("todoapp://widget/toggle?taskId=$taskId&widgetId=$widgetId")
                )
                Log.d(TAG, "HomeWidget background callback triggered")
            } catch (e: Exception) {
                Log.w(TAG, "HomeWidget callback not available, using fallback: $e")

                // Fallback: Wake up the Flutter app silently
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
                    Log.d(TAG, "Flutter app wakeup intent sent (silent mode)")
                } catch (e2: Exception) {
                    Log.w(TAG, "Could not wake Flutter app: $e2")
                }
            }

            // Trigger immediate widget refresh to show optimistic update
            handleRefreshWidget(context)

            Log.d(TAG, "=== TOGGLE TASK COMPLETE ===")
        } catch (e: Exception) {
            Log.e(TAG, "Error handling toggle task", e)
        }
    }
}