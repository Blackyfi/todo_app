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
import java.text.SimpleDateFormat
import java.util.*

class TodoWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val ACTION_SYNC_WIDGET = "ACTION_SYNC_WIDGET"
        private const val ACTION_TOGGLE_TASK = "ACTION_TOGGLE_TASK"
        private const val ACTION_ADD_TASK = "ACTION_ADD_TASK"
        private const val ACTION_WIDGET_SETTINGS = "ACTION_WIDGET_SETTINGS"
        private const val ACTION_REFRESH_WIDGET = "ACTION_REFRESH_WIDGET"
        
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
                
                // Update task list with full feature set
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
        
        // Refresh button - uses broadcast to refresh widget without opening app
        val refreshIntent = Intent(context, TodoWidgetProvider::class.java).apply {
            action = ACTION_REFRESH_WIDGET
            putExtra(EXTRA_WIDGET_ID, 1)
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
    }
    
    private fun updateTaskList(views: RemoteViews, tasks: JSONArray, config: JSONObject, context: Context, appWidgetId: Int) {
        // Clear existing task views first
        views.removeAllViews(R.id.task_list)
        
        val maxTasks = minOf(tasks.length(), config.optInt("maxTasks", 5))
        val showCategories = config.optBoolean("showCategories", true)
        val showPriority = config.optBoolean("showPriority", true)
        val showCompleted = config.optBoolean("showCompleted", false)
        
        for (i in 0 until maxTasks) {
            val task = tasks.getJSONObject(i)
            val taskId = task.getInt("id")
            val taskTitle = task.getString("title")
            val taskDescription = task.optString("description", "")
            val isCompleted = task.getBoolean("isCompleted")
            val priority = task.optInt("priority", 1)
            val priorityLabel = task.optString("priorityLabel", "Medium")
            val priorityColor = task.optInt("priorityColor", 0xFFFF9800.toInt())
            val dueDate = task.optLong("dueDate", 0)
            val categoryData = task.optJSONObject("category")
            
            // Skip completed tasks if not configured to show them
            if (isCompleted && !showCompleted) continue
            
            val taskView = RemoteViews(views.`package`, R.layout.widget_task_item)
            
            // Set task title
            taskView.setTextViewText(R.id.task_title, taskTitle)
            
            // Set completion status and styling
            if (isCompleted) {
                taskView.setTextViewText(R.id.task_checkbox, "✓")
                taskView.setTextColor(R.id.task_title, 0xFF999999.toInt())
                taskView.setTextColor(R.id.task_description, 0xFF999999.toInt())
            } else {
                taskView.setTextViewText(R.id.task_checkbox, "○")
                taskView.setTextColor(R.id.task_title, 0xFF000000.toInt())
                taskView.setTextColor(R.id.task_description, 0xFF666666.toInt())
            }
            
            // Set task description
            if (taskDescription.isNotEmpty()) {
                taskView.setViewVisibility(R.id.task_description, android.view.View.VISIBLE)
                taskView.setTextViewText(R.id.task_description, taskDescription)
            } else {
                taskView.setViewVisibility(R.id.task_description, android.view.View.GONE)
            }
            
            // Set priority badge
            if (showPriority) {
                taskView.setViewVisibility(R.id.priority_badge, android.view.View.VISIBLE)
                taskView.setTextViewText(R.id.priority_badge, priorityLabel.uppercase())
                
                // Set priority colors
                val backgroundColor = when (priority) {
                    0 -> 0xFFFF0000.toInt() // High - Red
                    1 -> 0xFFFF9800.toInt() // Medium - Orange  
                    2 -> 0xFF4CAF50.toInt() // Low - Green
                    else -> 0xFFFF9800.toInt()
                }
                taskView.setInt(R.id.priority_badge, "setBackgroundColor", backgroundColor)
            } else {
                taskView.setViewVisibility(R.id.priority_badge, android.view.View.GONE)
            }
            
            // Set category badge
            if (showCategories && categoryData != null) {
                taskView.setViewVisibility(R.id.category_badge, android.view.View.VISIBLE)
                val categoryName = categoryData.getString("name")
                val categoryColor = categoryData.getInt("color")
                
                taskView.setTextViewText(R.id.category_badge, categoryName)
                taskView.setTextColor(R.id.category_badge, categoryColor)
                
                // Set category background with transparency
                val backgroundColor = (categoryColor and 0x00FFFFFF) or 0x33000000
                taskView.setInt(R.id.category_badge, "setBackgroundColor", backgroundColor)
            } else {
                taskView.setViewVisibility(R.id.category_badge, android.view.View.GONE)
            }
            
            // Set due date
            if (dueDate > 0) {
                taskView.setViewVisibility(R.id.due_date, android.view.View.VISIBLE)
                val dueDateText = formatDueDate(dueDate)
                taskView.setTextViewText(R.id.due_date, dueDateText)
                
                // Set due date color based on urgency
                val dueDateColor = getDueDateColor(dueDate, isCompleted)
                taskView.setTextColor(R.id.due_date, dueDateColor)
            } else {
                taskView.setViewVisibility(R.id.due_date, android.view.View.GONE)
            }
            
            // Set status indicator for overdue/urgent tasks
            if (!isCompleted && dueDate > 0) {
                val statusText = getStatusIndicator(dueDate)
                if (statusText.isNotEmpty()) {
                    taskView.setViewVisibility(R.id.status_indicator, android.view.View.VISIBLE)
                    taskView.setTextViewText(R.id.status_indicator, statusText)
                    
                    val statusColor = when {
                        statusText.contains("OVERDUE") -> 0xFFFF0000.toInt()
                        statusText.contains("TODAY") -> 0xFFFF9800.toInt()
                        statusText.contains("DAYS LEFT") -> 0xFF4CAF50.toInt()
                        else -> 0xFF666666.toInt()
                    }
                    taskView.setTextColor(R.id.status_indicator, statusColor)
                } else {
                    taskView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)
                }
            } else {
                taskView.setViewVisibility(R.id.status_indicator, android.view.View.GONE)
            }
            
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
            
            views.addView(R.id.task_list, taskView)
        }
    }
    
    private fun formatDueDate(dueDate: Long): String {
        val date = Date(dueDate)
        val dateFormat = SimpleDateFormat("MMM d", Locale.getDefault())
        val timeFormat = SimpleDateFormat("h:mm a", Locale.getDefault())
        return "${dateFormat.format(date)} · ${timeFormat.format(date)}"
    }
    
    private fun getDueDateColor(dueDate: Long, isCompleted: Boolean): Int {
        if (isCompleted) return 0xFF999999.toInt()
        
        val now = System.currentTimeMillis()
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        
        val tomorrow = today + 24 * 60 * 60 * 1000
        val threeDaysLater = today + 3 * 24 * 60 * 60 * 1000
        
        return when {
            dueDate < now -> 0xFFFF0000.toInt() // Overdue - Red
            dueDate < tomorrow -> 0xFFFF9800.toInt() // Today - Orange
            dueDate < threeDaysLater -> 0xFF2196F3.toInt() // Within 3 days - Blue
            else -> 0xFF666666.toInt() // Future - Gray
        }
    }
    
    private fun getStatusIndicator(dueDate: Long): String {
        val now = System.currentTimeMillis()
        val today = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        
        return when {
            dueDate < now -> "OVERDUE"
            dueDate < today + 24 * 60 * 60 * 1000 -> "TODAY" 
            else -> {
                val daysLeft = ((dueDate - today) / (24 * 60 * 60 * 1000)).toInt()
                if (daysLeft <= 5) "$daysLeft DAYS LEFT" else ""
            }
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_REFRESH_WIDGET -> {
                // Handle refresh without opening the app
                val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
                
                // Simply trigger a widget update with current data
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, TodoWidgetProvider::class.java)
                )
                onUpdate(context, appWidgetManager, appWidgetIds)
            }
            
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