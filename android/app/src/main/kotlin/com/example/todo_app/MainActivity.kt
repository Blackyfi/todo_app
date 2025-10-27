package com.example.todo_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.todo_app/widget"

    override fun onCreate(savedInstanceState: Bundle?) {
        android.util.Log.d("MainActivity", "========================================")
        android.util.Log.d("MainActivity", "onCreate called with action: ${intent?.action}")
        android.util.Log.d("MainActivity", "========================================")

        // Check if this is a background command - if so, use transparent theme
        if (intent?.action == "PROCESS_WIDGET_COMMAND") {
            setTheme(R.style.TransparentTheme)
            android.util.Log.d("MainActivity", "Using transparent theme for background command")
        }
        super.onCreate(savedInstanceState)
        handleWidgetIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        android.util.Log.d("MainActivity", "========================================")
        android.util.Log.d("MainActivity", "onNewIntent called with action: ${intent.action}")
        android.util.Log.d("MainActivity", "========================================")
        super.onNewIntent(intent)
        setIntent(intent)
        handleWidgetIntent(intent)
    }
    
    private fun handleWidgetIntent(intent: Intent?) {
        android.util.Log.d("MainActivity", "handleWidgetIntent: action=${intent?.action}")
        if (intent?.action != null) {
            when (intent.action) {
                "ADD_TASK" -> {
                    android.util.Log.d("MainActivity", "Handling ADD_TASK")
                    val widgetId = intent.getIntExtra("widget_id", 1)
                    sendToFlutter("add_task", mapOf("widgetId" to widgetId))
                    // Keep app open for add task
                }
                "WIDGET_SETTINGS" -> {
                    android.util.Log.d("MainActivity", "Handling WIDGET_SETTINGS")
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
                "PROCESS_WIDGET_COMMAND" -> {
                    android.util.Log.d("MainActivity", ">>> Handling PROCESS_WIDGET_COMMAND")
                    // CRITICAL: This action wakes up Flutter to process commands silently
                    val taskId = intent.getIntExtra("task_id", -1)
                    val widgetId = intent.getIntExtra("widget_id", 1)
                    android.util.Log.d("MainActivity", ">>> TaskID=$taskId, WidgetID=$widgetId")

                    // Finish immediately - don't show UI
                    moveTaskToBack(true)
                    android.util.Log.d("MainActivity", ">>> Moved task to back")

                    // Wait for Flutter engine to be ready, then send command directly
                    android.os.Handler(mainLooper).postDelayed({
                        try {
                            android.util.Log.d("MainActivity", ">>> Sending silent toggle command to Flutter...")
                            sendToFlutter("silent_background_toggle_task", mapOf("taskId" to taskId, "widgetId" to widgetId))
                            android.util.Log.d("MainActivity", ">>> Successfully sent silent toggle command to Flutter: taskId=$taskId")
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", ">>> Failed to send toggle command", e)
                        }

                        // Close quickly after sending command
                        android.os.Handler(mainLooper).postDelayed({
                            android.util.Log.d("MainActivity", ">>> Finishing activity")
                            if (!isFinishing && !isDestroyed) {
                                finish()
                            }
                        }, 200)
                    }, 200) // Wait 200ms for Flutter engine to initialize
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