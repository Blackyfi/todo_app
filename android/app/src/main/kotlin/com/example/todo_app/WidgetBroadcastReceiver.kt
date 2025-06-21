package com.example.todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import org.json.JSONObject
import org.json.JSONArray

class WidgetBroadcastReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "WidgetBroadcastReceiver"
        const val ACTION_WIDGET_BACKGROUND_SYNC = "com.example.todo_app.WIDGET_BACKGROUND_SYNC"
        const val ACTION_WIDGET_TOGGLE_TASK = "com.example.todo_app.WIDGET_TOGGLE_TASK"
        
        // CRITICAL: Use consistent data keys
        private const val WIDGET_DATA_KEY = "widget_data"
        private const val WIDGET_CONFIG_KEY = "widget_config"
        
        // CRITICAL: Keys for widget-only state
        private const val WIDGET_PENDING_TOGGLES_KEY = "widget_pending_toggles"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Received broadcast: ${intent.action}")
        
        when (intent.action) {
            ACTION_WIDGET_BACKGROUND_SYNC -> {
                Log.d(TAG, "Handling background sync via broadcast")
                handleBackgroundSync(context, intent)
            }
            
            ACTION_WIDGET_TOGGLE_TASK -> {
                Log.d(TAG, "Handling task toggle via broadcast")
                handleTaskToggle(context, intent)
            }
        }
    }
    
    private fun handleBackgroundSync(context: Context, intent: Intent) {
        try {
            Log.d(TAG, "Processing background sync - triggering widget refresh")
            
            // Clear any pending toggles since we're refreshing from source
            clearPendingToggles(context)
            
            // Trigger widget update
            triggerWidgetUpdate(context)
            
            Log.d(TAG, "Background sync completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error in background sync", e)
        }
    }
    
    private fun handleTaskToggle(context: Context, intent: Intent) {
        try {
            val taskId = intent.getIntExtra("task_id", -1)
            val widgetId = intent.getIntExtra("widget_id", 1)
            
            Log.d(TAG, "Processing task toggle: TaskID=$taskId, WidgetID=$widgetId")
            
            if (taskId > 0) {
                // CRITICAL: Store the toggle in widget-specific SharedPreferences
                storePendingToggle(context, taskId)
                
                // Immediately trigger widget update to show the change
                triggerWidgetUpdate(context)
                
                Log.d(TAG, "Task toggle stored and widget updated")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in task toggle", e)
        }
    }
    
    private fun storePendingToggle(context: Context, taskId: Int) {
        try {
            // Store pending toggles in a separate SharedPreferences file
            val togglePrefs = context.getSharedPreferences("widget_toggles", Context.MODE_PRIVATE)
            val currentToggles = togglePrefs.getStringSet(WIDGET_PENDING_TOGGLES_KEY, mutableSetOf()) ?: mutableSetOf()
            
            // If task is already in pending toggles, remove it (toggle back)
            // If not, add it (toggle to completed)
            val newToggles = currentToggles.toMutableSet()
            if (newToggles.contains(taskId.toString())) {
                newToggles.remove(taskId.toString())
                Log.d(TAG, "Task $taskId removed from pending toggles (toggle back)")
            } else {
                newToggles.add(taskId.toString())
                Log.d(TAG, "Task $taskId added to pending toggles (toggle to completed)")
            }
            
            togglePrefs.edit()
                .putStringSet(WIDGET_PENDING_TOGGLES_KEY, newToggles)
                .apply()
                
            Log.d(TAG, "Pending toggles updated: $newToggles")
        } catch (e: Exception) {
            Log.e(TAG, "Error storing pending toggle", e)
        }
    }
    
    private fun clearPendingToggles(context: Context) {
        try {
            val togglePrefs = context.getSharedPreferences("widget_toggles", Context.MODE_PRIVATE)
            togglePrefs.edit().remove(WIDGET_PENDING_TOGGLES_KEY).apply()
            Log.d(TAG, "Pending toggles cleared")
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing pending toggles", e)
        }
    }
    
    private fun triggerWidgetUpdate(context: Context) {
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TodoWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            
            // Trigger widget update
            val updateIntent = Intent(context, TodoWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            }
            context.sendBroadcast(updateIntent)
            
            Log.d(TAG, "Widget update triggered for ${appWidgetIds.size} widgets")
        } catch (e: Exception) {
            Log.e(TAG, "Error triggering widget update", e)
        }
    }
}