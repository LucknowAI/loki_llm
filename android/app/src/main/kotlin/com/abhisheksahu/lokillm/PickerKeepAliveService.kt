package com.abhisheksahu.lokillm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Foreground service that runs only while a system file picker is in front.
 *
 * A loaded model holds gigabytes of native memory. Once the picker covers the
 * app, Android sees a large background process and its low-memory killer
 * kills it first: the model, the open chat, and the picked file are all lost.
 * A foreground service raises the process priority so it survives the pick.
 *
 * Android 14+ runs it as a `shortService` (about 3 minutes, no extra
 * permission or Play declaration). Older versions treat it as a plain
 * foreground service with no timeout.
 */
class PickerKeepAliveService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = buildNotification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        return START_NOT_STICKY
    }

    // shortService time limit reached (picker left open too long). Stop, or
    // Android raises an ANR. The app is then an ordinary background app again.
    override fun onTimeout(startId: Int) {
        stopSelf()
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "File picker",
                    NotificationManager.IMPORTANCE_LOW,
                ),
            )
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(android.R.drawable.ic_menu_gallery)
            .setContentTitle("Keeping your model loaded")
            .setContentText("Loki is waiting for the file you pick.")
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "picker_keep_alive"
        private const val NOTIFICATION_ID = 4101
    }
}
