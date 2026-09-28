package com.atomicfi.appiumtestenvironment.flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Receives the suite's commands (`--es command PAUSE_TRANSACT|RESUME_TRANSACT|WEBVIEW`) and hands
 * them to Dart, which carries them out through the plugin. Declared in the manifest because the
 * suite addresses it by explicit component.
 */
class TransactCommandReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val command = intent.getStringExtra(EXTRA_COMMAND)
        if (command == null) {
            AppiumHarness.log("Broadcast without a command extra")
            return
        }
        val extras = intent.extras?.keySet().orEmpty()
            .filter { it != EXTRA_COMMAND }
            .mapNotNull { key -> intent.getStringExtra(key)?.let { key to it } }
            .toMap()
        AppiumHarness.log("Received command $command $extras")

        val harness = AppiumHarness.current
        if (harness == null) {
            AppiumHarness.log("Dropping command $command: Flutter is not running yet")
            return
        }
        harness.sendCommand(command, extras)
    }

    private companion object {
        const val EXTRA_COMMAND = "command"
    }
}
