package com.eckhardt.contador.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import com.eckhardt.contador.R

/**
 * Aberta pelo launcher ao adicionar (ou reconfigurar) um widget:
 * o usuário escolhe qual evento aquela instância vai mostrar.
 */
class WidgetConfigActivity : Activity() {

    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        widgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val store = EventStore(this)
        val now = System.currentTimeMillis()
        val events = store.loadEvents().sortedWith(
            compareBy<CountdownEvent> { it.target <= now }.thenBy { it.target },
        )

        // Sem eventos: adiciona o widget mesmo assim (mostra "crie um evento").
        if (events.isEmpty()) {
            finishWithWidget()
            return
        }

        val pad = dp(20)
        val header = TextView(this).apply {
            text = getString(R.string.widget_config_title)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            setPadding(pad, pad, pad, dp(8))
        }
        val list = ListView(this).apply {
            adapter = ArrayAdapter(
                this@WidgetConfigActivity,
                android.R.layout.simple_list_item_1,
                events.map { "${it.emoji}  ${it.title}  ·  ${Countdown.shortLabel(it.target - now)}" },
            )
            setOnItemClickListener { _, _, position, _ ->
                store.setEventForWidget(widgetId, events[position].id)
                finishWithWidget()
            }
        }
        setContentView(LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            addView(header)
            addView(list, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        })
    }

    private fun finishWithWidget() {
        val manager = AppWidgetManager.getInstance(this)
        manager.getAppWidgetInfo(widgetId)?.provider?.let { provider ->
            sendBroadcast(
                Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                    .setComponent(provider)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId)),
            )
        }
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()
}
