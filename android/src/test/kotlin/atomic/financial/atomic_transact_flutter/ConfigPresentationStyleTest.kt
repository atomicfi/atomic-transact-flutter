package atomic.financial.atomic_transact_flutter

import financial.atomic.transact.Config
import org.junit.Assert.assertEquals
import org.junit.Test

/// Covers the `presentationStyleAndroid` passed on to Transact.
///
/// Run with `./gradlew :atomic_transact_flutter:testDebugUnitTest` from `example/android`, after the
/// example app has been built once.
class ConfigPresentationStyleTest {
  private val plugin = AtomicTransactFlutterPlugin()

  @Test
  fun formSheet_becomesFormSheet() {
    assertEquals(
      Config.PresentationStyle.FORM_SHEET, plugin.configPresentationStyleFromString("formSheet"))
  }

  @Test
  fun fullScreen_becomesFullScreen() {
    assertEquals(
      Config.PresentationStyle.FULL_SCREEN, plugin.configPresentationStyleFromString("fullScreen"))
  }

  @Test
  fun noStyle_defaultsToFullScreen() {
    assertEquals(Config.PresentationStyle.FULL_SCREEN, plugin.configPresentationStyleFromString(null))
  }

  @Test
  fun unknownStyle_defaultsToFullScreen() {
    assertEquals(
      Config.PresentationStyle.FULL_SCREEN, plugin.configPresentationStyleFromString("pageSheet"))
  }
}
