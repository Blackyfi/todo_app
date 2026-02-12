package com.example.todo_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * EventChannel implementation for real-time widget command communication.
 * Replaces polling-based command detection with event-driven architecture.
 */
class WidgetEventChannel : EventChannel.StreamHandler {
    companion object {
        private const val TAG = "WidgetEventChannel"
        const val CHANNEL_NAME = "com.example.todo_app/widget_events"

        // Custom action for widget commands
        const val ACTION_WIDGET_COMMAND = "com.example.todo_app.WIDGET_COMMAND"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private var commandReceiver: BroadcastReceiver? = null

    fun initialize(context: Context) {
        this.context = context
        Log.d(TAG, "WidgetEventChannel initialized")
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "EventChannel listener attached")
        eventSink = events

        context?.let { ctx ->
            // Create broadcast receiver for widget commands
            commandReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    Log.d(TAG, "Received widget command broadcast")

                    intent?.let {
                        val command = it.getStringExtra("command")
                        val taskId = it.getIntExtra("task_id", -1)
                        val widgetId = it.getIntExtra("widget_id", -1)
                        val timestamp = it.getLongExtra("timestamp", System.currentTimeMillis())

                        Log.d(TAG, "Broadcasting command to Flutter: command=$command, taskId=$taskId, widgetId=$widgetId")

                        // Send event to Flutter
                        eventSink?.success(mapOf(
                            "command" to command,
                            "taskId" to taskId,
                            "widgetId" to widgetId,
                            "timestamp" to timestamp
                        ))
                    }
                }
            }

            // Register receiver
            val filter = IntentFilter(ACTION_WIDGET_COMMAND)
            ctx.registerReceiver(commandReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            Log.d(TAG, "Broadcast receiver registered for widget commands")
        }
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "EventChannel listener cancelled")

        context?.let { ctx ->
            try {
                commandReceiver?.let {
                    ctx.unregisterReceiver(it)
                    Log.d(TAG, "Broadcast receiver unregistered")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error unregistering receiver: $e")
            }
        }

        commandReceiver = null
        eventSink = null
    }

    /**
     * Send a widget command event to Flutter.
     * Called from Android widget provider to notify Flutter of widget actions.
     */
    fun sendCommand(command: String, taskId: Int = -1, widgetId: Int = -1) {
        Log.d(TAG, "Sending command to Flutter: command=$command, taskId=$taskId, widgetId=$widgetId")

        context?.let { ctx ->
            val intent = Intent(ACTION_WIDGET_COMMAND).apply {
                putExtra("command", command)
                putExtra("task_id", taskId)
                putExtra("widget_id", widgetId)
                putExtra("timestamp", System.currentTimeMillis())
            }
            ctx.sendBroadcast(intent)
            Log.d(TAG, "Command broadcast sent")
        }
    }
}
