package com.eckhardt.contador.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.eckhardt.contador.R

/**
 * Base de todos os widgets: carrega os eventos, desenha cada instância e
 * agenda a próxima atualização para quando o número exibido mudar
 * (virada do dia/hora/minuto). Além disso, o sistema atualiza a cada 30 min
 * (`updatePeriodMillis`) e o app força uma atualização sempre que salva.
 */
abstract class BaseCountdownProvider : AppWidgetProvider() {

    abstract fun render(
        context: Context,
        event: CountdownEvent?,
        events: List<CountdownEvent>,
        now: Long,
    ): RemoteViews

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val store = EventStore(context)
        val events = store.loadEvents()
        val now = System.currentTimeMillis()
        for (id in ids) {
            val views = render(context, store.eventForWidget(id, events, now), events, now)
            views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
            manager.updateAppWidget(id, views)
        }
        scheduleNextRefresh(context, events, now)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, javaClass))
            if (ids.isNotEmpty()) onUpdate(context, manager, ids)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        EventStore(context).removeWidgets(appWidgetIds)
    }

    override fun onDisabled(context: Context) {
        alarmManager(context).cancel(refreshIntent(context))
    }

    private fun scheduleNextRefresh(context: Context, events: List<CountdownEvent>, now: Long) {
        val next = events.mapNotNull { Countdown.nextChange(it.target - now) }.minOrNull() ?: return
        // Alarme inexato (economiza bateria, não exige permissão especial).
        val delay = (next + Countdown.SECOND).coerceIn(Countdown.MINUTE, 6 * Countdown.HOUR)
        alarmManager(context).set(AlarmManager.RTC, now + delay, refreshIntent(context))
    }

    private fun refreshIntent(context: Context): PendingIntent {
        val intent = Intent(context, javaClass).setAction(ACTION_REFRESH)
        return PendingIntent.getBroadcast(
            context,
            javaClass.name.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun alarmManager(context: Context) =
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    companion object {
        const val ACTION_REFRESH = "com.eckhardt.contador.widgets.REFRESH"

        fun openAppIntent(context: Context): PendingIntent {
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent()
            return PendingIntent.getActivity(
                context,
                0,
                launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /** Fundo arredondado tingido com a cor do evento. */
        fun applyBackground(views: RemoteViews, color: Int) {
            views.setInt(R.id.widget_bg, "setColorFilter", color)
        }
    }
}
