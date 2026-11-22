package com.eckhardt.contador.widgets

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.text.format.DateFormat
import android.view.View
import android.widget.RemoteViews
import com.eckhardt.contador.R
import java.util.Date
import java.util.Locale

private const val EMPTY_COLOR = 0xFF455A64.toInt()

/** Clássico (2×2): emoji, número grande, unidade e nome. */
class ClassicWidgetProvider : BaseCountdownProvider() {
    override fun render(context: Context, event: CountdownEvent?, events: List<CountdownEvent>, now: Long) =
        RemoteViews(context.packageName, R.layout.widget_classic).apply {
            if (event == null) {
                applyBackground(this, EMPTY_COLOR)
                setTextViewText(R.id.emoji, "⏳")
                setTextViewText(R.id.value, "+")
                setTextViewText(R.id.unit, "")
                setTextViewText(R.id.title, context.getString(R.string.widget_empty))
                return@apply
            }
            val h = Countdown.headline(event.target - now)
            applyBackground(this, event.color)
            setTextViewText(R.id.emoji, event.emoji)
            setTextViewText(R.id.value, h.value)
            setTextViewText(R.id.unit, h.unit)
            setTextViewText(R.id.title, event.title)
        }
}

/** Minimalista (1×1): apenas o número. */
class MinimalWidgetProvider : BaseCountdownProvider() {
    override fun render(context: Context, event: CountdownEvent?, events: List<CountdownEvent>, now: Long) =
        RemoteViews(context.packageName, R.layout.widget_minimal).apply {
            if (event == null) {
                applyBackground(this, EMPTY_COLOR)
                setTextViewText(R.id.value, "+")
                setTextViewText(R.id.unit, "")
                return@apply
            }
            val h = Countdown.headline(event.target - now)
            applyBackground(this, event.color)
            setTextViewText(R.id.value, h.value)
            setTextViewText(R.id.unit, h.unit)
        }
}

/** Detalhado (4×2): dias + cronômetro regressivo ao vivo (hh:mm:ss). */
class DetailedWidgetProvider : BaseCountdownProvider() {
    override fun render(context: Context, event: CountdownEvent?, events: List<CountdownEvent>, now: Long) =
        RemoteViews(context.packageName, R.layout.widget_detailed).apply {
            if (event == null) {
                applyBackground(this, EMPTY_COLOR)
                setTextViewText(R.id.emoji, "⏳")
                setTextViewText(R.id.title, context.getString(R.string.widget_empty))
                showDone(this, "+")
                setTextViewText(R.id.date, "")
                return@apply
            }
            applyBackground(this, event.color)
            setTextViewText(R.id.emoji, event.emoji)
            setTextViewText(R.id.title, event.title)
            setTextViewText(R.id.date, formatDate(context, event.target))

            val remaining = event.target - now
            if (remaining <= 0) {
                showDone(this, "🎉 Chegou o dia!")
                return@apply
            }
            setViewVisibility(R.id.timer_group, View.VISIBLE)
            setViewVisibility(R.id.done_text, View.GONE)
            val days = remaining / Countdown.DAY
            setTextViewText(R.id.days, days.toString())
            setTextViewText(R.id.days_unit, if (days == 1L) "dia" else "dias")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // O Chronometer conta sozinho, sem acordar o app a cada segundo.
                val sub = remaining % Countdown.DAY
                setChronometer(R.id.chrono, SystemClock.elapsedRealtime() + sub, null, true)
                setChronometerCountDown(R.id.chrono, true)
                setViewVisibility(R.id.chrono, View.VISIBLE)
                setViewVisibility(R.id.hours_static, View.GONE)
            } else {
                val hours = (remaining % Countdown.DAY) / Countdown.HOUR
                val minutes = (remaining % Countdown.HOUR) / Countdown.MINUTE
                setTextViewText(R.id.hours_static, String.format(Locale.ROOT, "%02d:%02d", hours, minutes))
                setViewVisibility(R.id.chrono, View.GONE)
                setViewVisibility(R.id.hours_static, View.VISIBLE)
            }
        }

    private fun showDone(views: RemoteViews, text: String) {
        views.setViewVisibility(R.id.timer_group, View.GONE)
        views.setViewVisibility(R.id.done_text, View.VISIBLE)
        views.setTextViewText(R.id.done_text, text)
    }

    private fun formatDate(context: Context, millis: Long): String {
        val pattern = DateFormat.getBestDateTimePattern(Locale.getDefault(), "EEEdMMMyyyyHHmm")
        return DateFormat.format(pattern, Date(millis)).toString()
    }
}

/** Progresso (4×1): barra do caminho percorrido até a data. */
class ProgressWidgetProvider : BaseCountdownProvider() {
    override fun render(context: Context, event: CountdownEvent?, events: List<CountdownEvent>, now: Long) =
        RemoteViews(context.packageName, R.layout.widget_progress).apply {
            if (event == null) {
                applyBackground(this, EMPTY_COLOR)
                setTextViewText(R.id.emoji, "⏳")
                setTextViewText(R.id.title, context.getString(R.string.widget_empty))
                setTextViewText(R.id.label, "")
                setTextViewText(R.id.percent, "")
                setProgressBar(R.id.progress, 1000, 0, false)
                return@apply
            }
            val progress = Countdown.progress(event, now)
            applyBackground(this, event.color)
            setTextViewText(R.id.emoji, event.emoji)
            setTextViewText(R.id.title, event.title)
            setTextViewText(R.id.label, Countdown.shortLabel(event.target - now))
            setTextViewText(R.id.percent, "${progress / 10}% do caminho")
            setProgressBar(R.id.progress, 1000, progress, false)
        }
}

/** Lista (4×3): até 4 próximos eventos. Não precisa de configuração. */
class ListWidgetProvider : BaseCountdownProvider() {
    private val rows = listOf(
        Row(R.id.row0, R.id.row0_bg, R.id.row0_emoji, R.id.row0_title, R.id.row0_value),
        Row(R.id.row1, R.id.row1_bg, R.id.row1_emoji, R.id.row1_title, R.id.row1_value),
        Row(R.id.row2, R.id.row2_bg, R.id.row2_emoji, R.id.row2_title, R.id.row2_value),
        Row(R.id.row3, R.id.row3_bg, R.id.row3_emoji, R.id.row3_title, R.id.row3_value),
    )

    override fun render(context: Context, event: CountdownEvent?, events: List<CountdownEvent>, now: Long) =
        RemoteViews(context.packageName, R.layout.widget_list).apply {
            applyBackground(this, 0xFF263238.toInt())
            val upcoming = EventStore.upcoming(events, now).take(rows.size)
            setViewVisibility(R.id.empty, if (upcoming.isEmpty()) View.VISIBLE else View.GONE)
            rows.forEachIndexed { i, row ->
                val e = upcoming.getOrNull(i)
                if (e == null) {
                    setViewVisibility(row.container, View.GONE)
                } else {
                    setViewVisibility(row.container, View.VISIBLE)
                    setInt(row.bg, "setColorFilter", e.color)
                    setTextViewText(row.emoji, e.emoji)
                    setTextViewText(row.title, e.title)
                    setTextViewText(row.value, Countdown.shortLabel(e.target - now))
                }
            }
        }

    private data class Row(val container: Int, val bg: Int, val emoji: Int, val title: Int, val value: Int)
}
