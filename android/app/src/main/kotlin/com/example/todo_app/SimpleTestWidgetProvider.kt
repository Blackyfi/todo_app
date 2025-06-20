package com.example.todo_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.util.Log

class SimpleTestWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val TAG = "SimpleTestWidget"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        Log.d(TAG, "=== SimpleTestWidget onUpdate called ===")
        Log.d(TAG, "Widget IDs: ${appWidgetIds.contentToString()}")
        
        for (appWidgetId in appWidgetIds) {
            Log.d(TAG, "Updating simple test widget: $appWidgetId")
            
            val views = RemoteViews(context.packageName, R.layout.todo_widget)
            views.setTextViewText(R.id.widget_title, "Simple Test Widget")
            views.setTextViewText(R.id.task_count, "Widget is working!")
            views.removeAllViews(R.id.task_list)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Simple test widget $appWidgetId updated successfully")
        }
    }

    override fun onEnabled(context: Context) {
        Log.d(TAG, "SimpleTestWidget enabled")
    }

    override fun onDisabled(context: Context) {
        Log.d(TAG, "SimpleTestWidget disabled")
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        Log.d(TAG, "SimpleTestWidget deleted: ${appWidgetIds.contentToString()}")
    }
}