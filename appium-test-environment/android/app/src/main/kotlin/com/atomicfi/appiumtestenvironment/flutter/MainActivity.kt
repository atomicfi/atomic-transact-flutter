package com.atomicfi.appiumtestenvironment.flutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Exposes the suite's TRANSACT_* launch extras to Dart.
 *
 * The suite clears the app and starts this activity with FLAG_ACTIVITY_NEW_TASK |
 * FLAG_ACTIVITY_CLEAR_TASK, so a launch is normally a cold start that Dart reads through
 * `getLaunchExtras`. A start that reaches the running activity arrives in [onNewIntent] and is
 * forwarded; Dart ignores one whose TRANSACT_LAUNCH_ID it has already launched.
 */
class MainActivity : FlutterActivity() {
    private var harness: AppiumHarness? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val harness = AppiumHarness(flutterEngine.dartExecutor.binaryMessenger) { launchExtras(intent) }
        this.harness = harness
        AppiumHarness.current = harness
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        harness?.let {
            // A replaced activity can be destroyed after its successor attached; keep the new harness.
            if (AppiumHarness.current === it) {
                AppiumHarness.current = null
            }
            it.dispose()
        }
        harness = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        AppiumHarness.log("onNewIntent")
        harness?.sendLaunch(launchExtras(intent))
    }

    private fun launchExtras(intent: Intent?): Map<String, String> {
        val extras = intent?.extras ?: return emptyMap()
        return extras.keySet()
            .filter { it.startsWith("TRANSACT_") }
            .mapNotNull { key -> intent.getStringExtra(key)?.let { key to it } }
            .toMap()
    }
}
