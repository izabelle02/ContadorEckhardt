package com.eckhardt.contador.widgets

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/** Espelho do modelo `CountdownEvent` do Dart. */
data class CountdownEvent(
    val id: String,
    val title: String,
    val emoji: String,
    val target: Long,
    val created: Long,
    val color: Int,
)

/**
 * Lê os eventos salvos pelo app Flutter (via home_widget) e guarda qual
 * evento cada instância de widget deve mostrar.
 */
class EventStore(private val context: Context) {

    private val config = context.getSharedPreferences(CONFIG_PREFS, Context.MODE_PRIVATE)

    fun loadEvents(): List<CountdownEvent> {
        val raw = HomeWidgetPlugin.getData(context).getString(EVENTS_KEY, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { i ->
                val o = array.getJSONObject(i)
                val target = o.getLong("target")
                CountdownEvent(
                    id = o.getString("id"),
                    title = o.optString("title", "Evento"),
                    emoji = o.optString("emoji", "⏳"),
                    target = target,
                    created = o.optLong("created", target - 30L * Countdown.DAY),
                    color = o.optLong("color", 0xFF6750A4).toInt(),
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun setEventForWidget(widgetId: Int, eventId: String) {
        config.edit().putString(key(widgetId), eventId).apply()
    }

    fun removeWidgets(widgetIds: IntArray) {
        val editor = config.edit()
        widgetIds.forEach { editor.remove(key(it)) }
        editor.apply()
    }

    /** Evento escolhido para o widget; se não houver, o próximo a acontecer. */
    fun eventForWidget(widgetId: Int, events: List<CountdownEvent>, now: Long): CountdownEvent? {
        val chosen = config.getString(key(widgetId), null)
        return events.firstOrNull { it.id == chosen } ?: nextUpcoming(events, now)
    }

    companion object {
        const val EVENTS_KEY = "events_json"
        private const val CONFIG_PREFS = "countdown_widget_config"
        private fun key(widgetId: Int) = "widget_$widgetId"

        fun upcoming(events: List<CountdownEvent>, now: Long) =
            events.filter { it.target > now }.sortedBy { it.target }

        fun nextUpcoming(events: List<CountdownEvent>, now: Long): CountdownEvent? =
            upcoming(events, now).firstOrNull() ?: events.maxByOrNull { it.target }
    }
}

/** Regras de exibição — as mesmas de `lib/ui/format.dart`. */
object Countdown {
    const val SECOND = 1_000L
    const val MINUTE = 60 * SECOND
    const val HOUR = 60 * MINUTE
    const val DAY = 24 * HOUR

    data class Headline(val value: String, val unit: String)

    fun headline(remaining: Long): Headline = when {
        remaining <= 0 -> Headline("🎉", "Chegou!")
        remaining >= DAY -> (remaining / DAY).let { Headline(it.toString(), if (it == 1L) "dia" else "dias") }
        remaining >= HOUR -> (remaining / HOUR).let { Headline(it.toString(), if (it == 1L) "hora" else "horas") }
        else -> Headline(maxOf(1L, remaining / MINUTE).toString(), "min")
    }

    fun shortLabel(remaining: Long): String =
        if (remaining <= 0) "Chegou!" else headline(remaining).let { "${it.value} ${it.unit}" }

    /** Em quantos ms o número exibido muda (null se o evento já passou). */
    fun nextChange(remaining: Long): Long? = when {
        remaining <= 0 -> null
        remaining >= DAY -> remaining % DAY
        remaining >= HOUR -> remaining % HOUR
        else -> remaining % MINUTE
    }

    /** Progresso de 0 a 1000 entre a criação e a data-alvo. */
    fun progress(event: CountdownEvent, now: Long): Int {
        val total = event.target - event.created
        if (total <= 0) return 1000
        return ((now - event.created) * 1000 / total).coerceIn(0, 1000).toInt()
    }
}
