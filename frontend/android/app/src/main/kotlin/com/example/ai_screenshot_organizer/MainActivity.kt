package com.example.ai_screenshot_organizer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val MEDIA_OBSERVER_CHANNEL = "contextvault/media_observer"
    private val NOTIFICATIONS_CHANNEL = "contextvault/notifications"
    private val NOTIFICATION_CHANNEL_ID = "contextvault_screenshots"

    private var contentObserver: ContentObserver? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        createNotificationChannel()

        // 1. MediaStore ContentObserver Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_OBSERVER_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerMediaStoreObserver()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterMediaStoreObserver()
                    eventSink = null
                }
            })

        // 2. Local Notifications Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showNotification" -> {
                        val title = call.argument<String>("title") ?: "ContextVault"
                        val body = call.argument<String>("body") ?: "Screenshot organized"
                        val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % 100000).toInt()
                        showLocalNotification(title, body, id)
                        result.success(true)
                    }
                    "isSupported" -> {
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun registerMediaStoreObserver() {
        if (contentObserver != null) return

        val handler = Handler(Looper.getMainLooper())
        contentObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                eventSink?.let { sink ->
                    val data = HashMap<String, Any>()
                    data["uri"] = uri?.toString() ?: ""
                    data["timestamp"] = System.currentTimeMillis()
                    sink.success(data)
                }
            }
        }

        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            true,
            contentObserver!!
        )
    }

    private fun unregisterMediaStoreObserver() {
        contentObserver?.let {
            contentResolver.unregisterContentObserver(it)
            contentObserver = null
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "ContextVault Screenshots"
            val descriptionText = "Notifications when screenshots are organized into folders"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(NOTIFICATION_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showLocalNotification(title: String, body: String, notificationId: Int) {
        try {
            val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(applicationInfo.icon)
                .setContentTitle(title)
                .setContentText(body)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)

            val notificationManager = NotificationManagerCompat.from(this)
            notificationManager.notify(notificationId, builder.build())
        } catch (e: SecurityException) {
            // Permission not granted on Android 13+
        } catch (e: Exception) {
            // General safety catch
        }
    }

    override fun onDestroy() {
        unregisterMediaStoreObserver()
        super.onDestroy()
    }
}
