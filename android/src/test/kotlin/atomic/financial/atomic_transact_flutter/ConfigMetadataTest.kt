package atomic.financial.atomic_transact_flutter

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/// Covers the `AtomicConfig.metadata` passed on to Transact.
///
/// Run with `./gradlew :atomic_transact_flutter:testDebugUnitTest` from `example/android`, after the
/// example app has been built once.
class ConfigMetadataTest {
  private val plugin = AtomicTransactFlutterPlugin()

  @Test
  fun metadataFromTheMethodChannel_becomesAJSONObject() {
    // The standard method codec decodes a Dart map as a HashMap.
    val metadata = plugin.configMetadataFromMap(
      hashMapOf<Any?, Any?>("verify" to "metadata", "source" to "flutter"))

    assertEquals(2, metadata?.length())
    assertEquals("metadata", metadata?.getString("verify"))
    assertEquals("flutter", metadata?.getString("source"))
  }

  @Test
  fun noMetadata_staysNull() {
    assertNull(plugin.configMetadataFromMap(null))
  }
}
