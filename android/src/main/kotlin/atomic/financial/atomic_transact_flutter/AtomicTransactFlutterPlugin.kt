package atomic.financial.atomic_transact_flutter

import android.app.Activity
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import org.json.JSONObject
import financial.atomic.transact.*
import financial.atomic.transact.receiver.TransactBroadcastReceiver
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding


/** AtomicTransactFlutterPlugin */
class AtomicTransactFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var activity : Activity

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "atomic_transact_flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "presentTransact") {
      val configuration = call.argument<Map<String, Any>>("configuration")
      val publicToken = configuration?.get("publicToken") as String
      val language = configuration?.get("language") as String
      val product = configuration?.get("product") as String
      val additionalProduct = configuration?.get("additionalProduct") as? String
      val handoff = configuration?.get("handoff") as? List<String>
      val linkedAccount = configuration?.get("linkedAccount") as? String
      val metadata = configuration?.get("metadata") as? String
      val theme = configuration?.get("theme") as? Map<String, Any>
      val distribution = configuration?.get("distribution") as? Map<String, Any>
      val deeplink = configuration?.get("deeplink") as? Map<String, Any>
      val search = configuration?.get("search") as? Map<String, Any>
      val experiments = configuration?.get("experiments") as? Map<String, Any>

      val config = Config(
              publicToken = publicToken,
              product = Config.Product.valueOf(product.toUpperCase()),
              additionalProduct = if (additionalProduct != null) Config.Product.valueOf(additionalProduct.toUpperCase()) else null,
              linkedAccount = linkedAccount,
              handoff = configHandoffFromList(handoff),
              language = Config.Language.valueOf(language),
              metadata = metadata,
              theme = configThemeFromMap(theme),
              distribution = configDistributionFromMap(distribution),
              deeplink = configDeeplinkFromMap(deeplink),
              experiments = configExperimentsFromMap(experiments),
              search = configSearchFromMap(search)
      )

      val envString = call.argument<String>("environment") as String
      val environment = Config.Environment.valueOf(envString.toUpperCase())

      Transact.registerReceiver(activity, object: TransactBroadcastReceiver() {
        override fun onClose(data: JSONObject) {
          Transact.unregisterReceiver(activity, this)
          channel.invokeMethod("onCompletion", mapOf("type" to "closed", "response" to mapFromTransactResponseData(data)));
        }
        override fun onFinish(data: JSONObject) {
          Transact.unregisterReceiver(activity, this)
          channel.invokeMethod("onCompletion", mapOf("type" to "finished", "response" to mapFromTransactResponseData(data)))
        }
        override fun onInteraction(data: JSONObject) {
          channel.invokeMethod("onInteraction", mapOf("interaction" to mapFromTransactInteraction(data)))
        }
        override fun onDataRequest(data: JSONObject) {
          channel.invokeMethod("onDataRequest", mapOf("request" to mapFromTransactDataRequest(data)))
        }
      })

      Transact.present(activity, config, environment)

    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)

  }

  /// ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity;
  }

  override fun onDetachedFromActivity() {
    //
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding);
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  /// Configuration converters

  private fun configHandoffFromList(value: List<String>?): List<Config.Handoff>? {
    if(value != null) {
      val result = mutableListOf<Config.Handoff>()

      value.forEach {
        val item = it.replace('-', '_').toUpperCase()
        result.add(Config.Handoff.valueOf(item))
      }

      return result
    }

    return null
  }

  private fun configThemeFromMap(value: Map<String, Any?>?): Config.Theme? {
    if (value != null) {
      return Config.Theme(
              brandColor = value["brandColor"] as? String,
              overlayColor = value["overlayColor"] as? String,
              dark = value["dark"] as? Boolean
      )
    }
    return null
  }

  private fun configDistributionFromMap(value: Map<String, Any?>?): Config.Distribution? {
    if (value != null) {
      val type = value["type"] as String
      val action = value["action"] as String
      val amount = value["amount"] as? Double

      return Config.Distribution(
              type = Config.Distribution.Type.valueOf(type),
              action = Config.Distribution.Action.valueOf(action),
              amount = amount
      )
    }

    return null
  }

  private fun configSearchFromMap(value: Map<String, Any?>?): Config.Search? {
    if (value != null) {
      val tags = mutableListOf<Config.Search.Tag>()
      val excludedTags = mutableListOf<Config.Search.Tag>()

      if(value["tags"] != null) {
        val valueTags = value["tags"] as List<String>

        valueTags.forEach {
          val item = it.replace('-', '_').toUpperCase()
          tags.add(Config.Search.Tag.valueOf(item))
        }
      }

      if(value["excludedTags"] != null) {
        val valueExcludedTags = value["excludedTags"] as List<String>

        valueExcludedTags.forEach {
          val item = it.replace('-', '_').toUpperCase()
          excludedTags.add(Config.Search.Tag.valueOf(item))
        }
      }

      return Config.Search(
              tags = tags,
              excludedTags = excludedTags
      )
    }

    return null
  }

  private fun configDeeplinkFromMap(value: Map<String, Any?>?): Config.Deeplink? {
    if (value != null) {
      val step = value["step"] as String
      val companyId = value["companyId"] as? String
      val companyName = value["companyName"] as? String
      val connectorId = value["connectorId"] as? String

      val stepFormatted = step.replace('-', '_').toUpperCase()

      return Config.Deeplink(
              step = Config.Deeplink.Step.valueOf(stepFormatted),
              companyId = companyId,
              companyName = companyName,
              connectorId = connectorId
      )
    }

    return null
  }

  private fun configExperimentsFromMap(value: Map<String, Any?>?): Config.Experiments? {
    if (value != null) {
      return Config.Experiments(
              fractionalDeposits = value["fractionalDeposits"] as? Boolean,
              unemploymentCarousel = value["unemploymentCarousel"] as? Boolean
      )
    }

    return null
  }

  /// Event converters

  private fun mapFromTransactInteraction(data: JSONObject): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>();
    val name = data.getString("name")
    val value = data.getJSONObject("value")

    result["name"] = name
    result["customer"] = value.optString("customer")
    result["language"] = value.optString("language")
    result["product"] = value.optString("product")
    result["additionalProduct"] = value.optString("additionalProduct")
    result["payroll"] = value.optString("payroll")
    result["company"] = value.optString("company")

    return result.toMap()
  }

  private fun mapFromTransactDataRequest(data: JSONObject): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>();

    result["name"] = data.optString("taskId")
    result["customer"] = data.optString("userId")

    val jArray = data.optJSONArray("fields")

    if (jArray != null) {
      val fields = mutableListOf<String>()

      for (i in 0 until jArray.length()) {
        fields.add(jArray.get(i) as String)
      }

      result["fields"] = fields.toList()
    }

    return result.toMap()
  }

  private fun mapFromTransactResponseData(data: JSONObject): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>();

    result["taskId"] = data.optString("taskId")
    result["reason"] = data.optString("reason")

    return result.toMap()
  }
}
