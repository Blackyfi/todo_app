package com.example.todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import es.antonborri.home_widget.HomeWidgetPlugin

class WidgetBroadcastReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "WidgetBroadcastReceiver"
        const val ACTION_WIDGET_BACKGROUND_SYNC = "com.example.todo_app.WIDGET_BACKGROUND_SYNC"
        const val ACTION_WIDGET_TOGGLE_TASK = "com.example.todo_app.WIDGET_TOGGLE_TASK"
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
            Log.d(TAG, "Processing background sync")
            
            // Signal Flutter app to refresh widget data via SharedPreferences
            val prefs = context.getSharedPreferences("widget_commands", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("command", "refresh_widget")
                .putLong("timestamp", System.currentTimeMillis())
                .apply()
            
            // Also trigger HomeWidget update
            HomeWidgetPlugin.updateWidget(context)
            
            Log.d(TAG, "Background sync completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error in background sync", e)
        }
    }
    
    private fun handleTaskToggle(context: Context, intent: Intent) {
        try {
            val taskId = intent.getIntExtra("task_id", -1)
            val widgetId = intent.getIntExtra("widget_id", 1)
            
            Log.d(TAG, "Processing task toggle: TaskID=$taskId")
            
            if (taskId > 0) {
                // Signal Flutter app to toggle task via SharedPreferences
                val prefs = context.getSharedPreferences("widget_commands", Context.MODE_PRIVATE)
                prefs.edit()
                    .putString("command", "toggle_task")
                    .putInt("task_id", taskId)
                    .putInt("widget_id", widgetId)
                    .putLong("timestamp", System.currentTimeMillis())
                    .apply()
                
                // Also trigger HomeWidget update
                HomeWidget
                Log.d(TAG, "Task toggle command saved")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in task toggle", e)
        }
    }
}