package com.lifeloop.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class HabitWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val todayDone = prefs.getLong("flutter.widget_today_done", 0L).toInt()
        val todayTotal = prefs.getLong("flutter.widget_today_total", 0L).toInt()
        val topStreakTitle = prefs.getString("flutter.widget_top_streak_title", "No habits yet") ?: "No habits yet"
        val topStreakValue = prefs.getLong("flutter.widget_top_streak_value", 0L).toInt()

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_widget_layout)
            views.setTextViewText(R.id.widget_progress_value, "$todayDone/$todayTotal")
            views.setTextViewText(R.id.widget_streak_title, topStreakTitle)
            views.setTextViewText(R.id.widget_streak_value, "${topStreakValue}d")

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
