package com.example.todo_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.todo_app/widget"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleWidgetIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }
    
    private fun handleWidgetIntent(intent: Intent?) {
        if (intent?.action != null) {
            when (intent.action) {
                "ADD_TASK" -> {
                    val widgetId = intent.getIntExtra("widget_id", 1)
                    sendToFlutter("add_task", mapOf("widgetId" to widgetId))
                    // Keep app open for add task
                }
                "WIDGET_SETTINGS" -> {
                    val widgetId = intent.getIntExtra("widget_id", 1)
                    sendToFlutter("widget_settings", mapOf("widgetId" to widgetId))
                    // Keep app open for settings
                }
                "BACKGROUND_SYNC" -> {
                    val widgetId = intent.getIntExtra("widget_id", 1)
                    sendToFlutter("background_sync", mapOf("widgetId" to widgetId))
                    
                    // For background sync, finish quickly after sending command
                    android.os.Handler(mainLooper).postDelayed({
                        if (!isFinishing && !isDestroyed) {
                            finish()
                        }
                    }, 500)
                }
                "BACKGROUND_TOGGLE_TASK" -> {
                    val taskId = intent.getIntExtra("task_id", -1)
                    val widgetId = intent.getIntExtra("widget_id", 1)
                    sendToFlutter("background_toggle_task", mapOf("taskId" to taskId, "widgetId" to widgetId))
                    
                    // For background toggle, finish quickly after sending command
                    android.os.Handler(mainLooper).postDelayed({
                        if (!isFinishing && !isDestroyed) {
                            finish()
                        }
                    }, 500)
                }
            }
        }
    }
    
    private fun sendToFlutter(action: String, data: Map<String, Any>) {
        flutterEngine?.dartExecutor?.let { dartExecutor ->
            MethodChannel(dartExecutor.binaryMessenger, CHANNEL).invokeMethod(
                "handleWidgetAction", 
                mapOf("action" to action, "data" to data)
            )
        }
    }
}