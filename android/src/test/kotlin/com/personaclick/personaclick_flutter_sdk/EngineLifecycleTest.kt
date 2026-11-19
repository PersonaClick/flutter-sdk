package com.personaclick.personaclick_flutter_sdk

import android.content.Context
import com.personalization.sdk.data.models.dto.notification.NotificationData
import com.personaclick.personaclick_flutter_sdk.push.PersonaClickPushMessages
import org.mockito.Mockito.mock
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * An engine that goes takes only what it connected: another engine keeps the shop's popups, and the plugin's
 * push listener keeps drawing and reporting pushes while the process lives, with or without an engine.
 */
internal class EngineLifecycleTest {

    private var mainBefore: (() -> Unit) -> Unit = MainThread.run
    private val drawBefore = PersonaClickPushMessages.draw
    private val reportBefore = PersonaClickPushMessages.reportShown
    private val backgroundBefore = PersonaClickPushMessages.background
    private val clockBefore = PopupRelay.clock
    private val context = mock(Context::class.java)
    private val events = mutableListOf<String>()

    private fun push(id: String) =
        NotificationData(id = id, title = "Title", body = "Body", icon = null, type = "bulk", actions = null, actionUrls = null, image = null, event = null)

    private fun receiver(name: String) = object : PersonaClickPushMessages.Receiver {
        override fun received(shopId: String, data: NotificationData) {
            events += "$name received ${data.id}"
        }

        override fun delivered(shopId: String, data: NotificationData) {
            events += "$name delivered ${data.id}"
        }
    }

    @BeforeTest
    fun setUp() {
        MainThread.run = { it() }
        PersonaClickPushMessages.reset()
        PopupRelay.reset()
        PopupRelay.clock = { 0L }
        PersonaClickPushMessages.background = { it() }
        PersonaClickPushMessages.draw = { _, data, shopId -> events += "drawn ${data.id} for $shopId"; true }
        PersonaClickPushMessages.reportShown = { shopId, data -> events += "shown ${data.id} for $shopId" }
    }

    @AfterTest
    fun restore() {
        MainThread.run = mainBefore
        PersonaClickPushMessages.draw = drawBefore
        PersonaClickPushMessages.reportShown = reportBefore
        PersonaClickPushMessages.background = backgroundBefore
        PopupRelay.clock = clockBefore
        PersonaClickPushMessages.reset()
        PopupRelay.reset()
    }

    @Test
    fun aBackgroundEngineThatWentLeavesTheAppEnginesPopups() {
        val app = PersonaClickFlutterSdkPlugin()
        val background = PersonaClickFlutterSdkPlugin()
        val shown = mutableListOf<String>()
        app.popupSinkOf = { shopId -> { json -> shown += "app $shopId $json" } }
        background.popupSinkOf = { shopId -> { json -> shown += "background $shopId $json" } }

        app.connectEngine("shop-1")
        background.connectEngine("shop-1")
        PopupRelay.relay("shop-1", "a", now = 0)
        background.disconnectEngine()
        PopupRelay.relay("shop-1", "b", now = 0)
        app.disconnectEngine()
        PopupRelay.relay("shop-1", "c", now = 0)
        val next = PersonaClickFlutterSdkPlugin()
        next.popupSinkOf = { shopId -> { json -> shown += "next $shopId $json" } }
        next.connectEngine("shop-1")

        assertEquals(listOf("background shop-1 a", "app shop-1 b", "next shop-1 c"), shown)
    }

    @Test
    fun anEngineThatWentNoLongerHearsPushesButTheyAreStillDrawnAndReported() {
        val plugin = PersonaClickFlutterSdkPlugin()
        plugin.popupSinkOf = { { } }
        plugin.connectEngine("shop-1")
        assertTrue(plugin.pushReceiver in PersonaClickPushMessages.attached())

        plugin.disconnectEngine()
        PersonaClickPushMessages.onMessage(context, "shop-1", push("m-1"))

        assertEquals(emptyList(), PersonaClickPushMessages.attached())
        assertEquals(listOf("drawn m-1 for shop-1", "shown m-1 for shop-1"), events)
    }

    @Test
    fun aPushGoesToTheDartOfTheEngineAttachedLast() {
        val app = receiver("app")
        val background = receiver("background")
        PersonaClickPushMessages.attach(app)
        PersonaClickPushMessages.attach(background)

        PersonaClickPushMessages.onMessage(context, "shop-1", push("m-1"))
        PersonaClickPushMessages.detach(background)
        PersonaClickPushMessages.onMessage(context, "shop-1", push("m-2"))

        assertEquals(
            listOf(
                "background received m-1", "drawn m-1 for shop-1", "shown m-1 for shop-1", "background delivered m-1",
                "app received m-2", "drawn m-2 for shop-1", "shown m-2 for shop-1", "app delivered m-2",
            ),
            events,
        )
    }

    @Test
    fun aNotificationThatWasNotDrawnIsNotReportedShown() {
        PersonaClickPushMessages.draw = { _, data, _ -> events += "not drawn ${data.id}"; false }
        PersonaClickPushMessages.attach(receiver("app"))

        PersonaClickPushMessages.onMessage(context, "shop-1", push("m-1"))

        assertEquals(listOf("app received m-1", "not drawn m-1", "app delivered m-1"), events)
    }
}
