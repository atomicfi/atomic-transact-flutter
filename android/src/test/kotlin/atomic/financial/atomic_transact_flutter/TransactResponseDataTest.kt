package atomic.financial.atomic_transact_flutter

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/// Covers the response passed to `onCompletion` for a finish or close.
///
/// Run with `./gradlew :atomic_transact_flutter:testDebugUnitTest` from `example/android`, after the
/// example app has been built once.
class TransactResponseDataTest {
  private val plugin = AtomicTransactFlutterPlugin()

  @Test
  fun finishAtAHandoff_carriesTheHandoffAndTheWholePayload() {
    val response = plugin.mapFromTransactResponseData(
      JSONObject("""{"taskId":"task-1","handoff":"authentication-success","identifier":"user-1"}"""))

    assertEquals("task-1", response["taskId"])
    assertEquals("authentication-success", response["handoff"])
    assertEquals(
      mapOf("taskId" to "task-1", "handoff" to "authentication-success", "identifier" to "user-1"),
      response["data"])
  }

  @Test
  fun closeWithoutAHandoff_leavesTheHandoffNull() {
    val response = plugin.mapFromTransactResponseData(JSONObject("""{"reason":"zero-search-results"}"""))

    assertEquals("zero-search-results", response["reason"])
    assertNull(response["handoff"])
    assertEquals(mapOf("reason" to "zero-search-results"), response["data"])
  }

  @Test
  fun nestedPayloadValues_becomeMapsAndLists() {
    // JSONObject and JSONArray can't be sent over the method channel.
    val response = plugin.mapFromTransactResponseData(
      JSONObject("""{"taskId":"task-1","company":{"name":"Amazon"},"products":["deposit"],"extra":null}"""))

    assertEquals(
      mapOf(
        "taskId" to "task-1",
        "company" to mapOf("name" to "Amazon"),
        "products" to listOf("deposit"),
        "extra" to null),
      response["data"])
  }
}
