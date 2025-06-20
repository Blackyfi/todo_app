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
            
            // CRITICAL FIX: Use the exact same keys as Flutter
            val preferences = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            Log.d(TAG, "SharedPreferences retrieved")
            
            // Log all available keys for debugging
            val allKeys = preferences.all.keys
            Log.d(TAG, "Available SharedPreferences keys: $allKeys")
            for (key in allKeys) {
                val value = preferences.getString(key, null)
                Log.d(TAG, "Key: $key, Value: ${value?.take(100)}...")
            }
            
            val configData = preferences.getString("widget_config", null)
            val tasksData = preferences.getString("widget_data", null)
            
            Log.d(TAG, "Config data available: ${configData != null}")
            Log.d(TAG, "Tasks data available: ${tasksData != null}")
            
            if (configData == null || tasksData == null) {
                Log.w(TAG, "Missing data - showing loading state")
                showLoadingState(context, appWidgetManager, appWidgetId)
                return
            }
            
            // Parse JSON data safely
            val config = JSONObject(configData)
            val data = JSONObject(tasksData)
            val tasks = data.getJSONArray("tasks")
            
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
            showErrorState(context, appWidgetManager, appWidgetId, "Failed to load widget data")
        }
    }
    
    private fun showLoadingState(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            views.setTextViewText(R.id.widget_title, "Todo App")
            views.setTextViewText(R.id.task_count, "Loading...")
            views.removeAllViews(R.id.task_list)
            
            // Set up basic button handlers even in loading state
            setupButtonClickHandlers(context, views, appWidgetId)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Loading state displayed for widget $appWidgetId")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing loading state", e)
        }
    }
    
    private fun showErrorState(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, errorMessage: String) {
        try {
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            views.setTextViewText(R.id.widget_title, "Todo App")
            views.setTextViewText(R.id.task_count, "Error: $errorMessage")
            views.removeAllViews(R.id.task_list)
            
            // Set up basic button handlers even in error state
            setupButtonClickHandlers(context, views, appWidgetId)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Error state displayed for widget $appWidgetId: $errorMessage")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing error state", e)
        }
    }
    
    private fun setupButtonClickHandlers(context: Context, views: RemoteViews, appWidgetId: Int) {
        try {
            // Add Task button
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
            
            // Refresh button
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
            
            // Settings button
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
            
            val maxTasks = minOf(tasks.length(), config.optInt("maxTasks", 5))
            val showCompleted = config.optBoolean("showCompleted", false)
            
            Log.d(TAG, "Display settings - maxTasks: $maxTasks, showCompleted: $showCompleted")
            
            var actualTasksAdded = 0
            
            for (i in 0 until maxTasks) {
                try {
                    val task = tasks.getJSONObject(i)
                    val isCompleted = task.optBoolean("isCompleted", false)
                    
                    // Skip completed tasks if not configured to show them
                    if (isCompleted && !showCompleted) {
                        Log.d(TAG, "Skipping completed task: ${task.optString("title")}")
                        continue
                    }
                    
                    val taskView = RemoteViews(context.packageName, R.layout.widget_task_item)
                    
                    // Set task title
                    val taskTitle = task.optString("title", "No title")
                    taskView.setTextViewText(R.id.task_title, taskTitle)
                    Log.d(TAG, "Set task title: $taskTitle")
                    
                    // Set completion status and styling
                    if (isCompleted) {
                        taskView.setTextViewText(R.id.task_checkbox, "✓")
                        taskView.setTextColor(R.id.task_title, 0xFF999999.toInt())
                    } else {
                        taskView.setTextViewText(R.id.task_checkbox, "○")
                        taskView.setTextColor(R.id.task_title, 0xFF000000.toInt())
                    }
                    
                    // Set task description
                    val taskDescription = task.optString("description", "")
                    if (taskDescription.isNotEmpty()) {
                        taskView.setViewVisibility(R.id.task_description, android.view.View.VISIBLE)
                        taskView.setTextViewText(R.id.task_description, taskDescription)
                    } else {
                        taskView.setViewVisibility(R.id.task_description, android.view.View.GONE)
                    }
                    
                    // Set click listener for checkbox
                    val taskId = task.optInt("id", -1)
                    if (taskId != -1) {
                        val toggleIntent = Intent(context, MainActivity::class.java).apply {
                            action = "BACKGROUND_TOGGLE_TASK"
                            putExtra(EXTRA_TASK_ID, taskId)
                            putExtra(EXTRA_WIDGET_ID, 1)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION
                        }
                        val togglePendingIntent = PendingIntent.getActivity(
                            context,
                            taskId * 1000 + appWidgetId,
                            toggleIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        taskView.setOnClickPendingIntent(R.id.task_checkbox, togglePendingIntent)
                    }
                    
                    views.addView(R.id.task_list, taskView)
                    actualTasksAdded++
                    Log.d(TAG, "Added task view to list (total: $actualTasksAdded)")
                    
                } catch (taskError: Exception) {
                    Log.e(TAG, "ERROR processing task $i", taskError)
                }
            }
            
            Log.d(TAG, "Task list update completed - added $actualTasksAdded tasks")
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in updateTaskList", e)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "=== onReceive called ===")
        Log.d(TAG, "Intent action: ${intent.action}")
        
        try {
            super.onReceive(context, intent)
            
            when (intent.action) {
                ACTION_REFRESH_WIDGET -> {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                    val appWidgetIds = appWidgetManager.getAppWidgetIds(
                        android.content.ComponentName(context, TodoWidgetProvider::class.java)
                    )
                    onUpdate(context, appWidgetManager, appWidgetIds)
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
            
        } catch (e: Exception) {
            Log.e(TAG, "CRITICAL ERROR in onReceive", e)
        }
        
        Log.d(TAG, "=== onReceive completed ===")
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