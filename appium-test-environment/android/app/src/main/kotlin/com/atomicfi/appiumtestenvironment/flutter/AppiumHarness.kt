package com.atomicfi.appiumtestenvironment.flutter

import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * The native side of the `atomictest/harness` channel. It only moves data between the suite and Dart:
 * Transact itself is driven from Dart through the plugin, which is what the suite is testing.
 */
class AppiumHarness(
    messenger: BinaryMessenger,
    private val launchExtras: () -> Map<String, String>,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getLaunchExtras" -> result.success(launchExtras())
            "log" -> {
                log(call.argument<String>("message").orEmpty())
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Hands Dart the extras of a start that reached the running activity instead of a new one. */
    fun sendLaunch(extras: Map<String, String>) {
        channel.invokeMethod("launch", mapOf("extras" to extras))
    }

    /** Hands Dart a command the suite broadcast to [TransactCommandReceiver]. */
    fun sendCommand(name: String, extras: Map<String, String>) {
        channel.invokeMethod("command", mapOf("name" to name, "extras" to extras))
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    companion object {
        const val TAG = "AppiumTestEnvironment"
        private const val CHANNEL = "atomictest/harness"

        /** The harness of the engine attached to the current MainActivity, for the receiver. */
        @Volatile
        var current: AppiumHarness? = null

        /**
         * Writes to logcat under the tag the native test app uses. Dart's print lands under `flutter`
         * and its debugPrint is rate-limited, so the suite's markers go through here.
         */
        fun log(message: String) {
            Log.d(TAG, message)
        }
    }
}
