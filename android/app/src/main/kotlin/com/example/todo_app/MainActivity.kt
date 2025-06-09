package com.example.todo_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.todo_app/widget"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle widget intents
        handleWidgetIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleWidgetIntent(intent)
    }
    
    private fun handleWidgetIntent(intent: Intent?) {
        if (intent?.action != null) {
            when (intent.action) {
                "ADD_TASK" -> {
                    // Navigate to add task screen
                    val widgetId = intent.getIntExtra("widget_id", -1)
                    // You can pass this to Flutter via method channel if needed
                    sendToFlutter("add_task", widgetId)
                }
                "WIDGET_SETTINGS" -> {
                    // Navigate to widget settings
                    val widgetId = intent.getIntExtra("widget_id", -1)
                    sendToFlutter("widget_settings", widgetId)
                }
            }
        }
    }
    
    private fun sendToFlutter(action: String, widgetId: Int) {
        flutterEngine?.dartExecutor?.let { dartExecutor ->
            MethodChannel(dartExecutor.binaryMessenger, CHANNEL).invokeMethod(
                "handleWidgetAction", 
                mapOf("action" to action, "widgetId" to widgetId)
            )
        }
    }
}