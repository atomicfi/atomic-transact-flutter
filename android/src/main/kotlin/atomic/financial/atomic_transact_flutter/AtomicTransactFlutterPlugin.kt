package atomic.financial.atomic_transact_flutter

import android.app.Activity
import android.util.Log
import androidx.annotation.NonNull
import financial.atomic.transact.*
import financial.atomic.transact.receiver.TransactBroadcastReceiver
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject
import org.json.JSONArray


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
      val scope = configuration?.get("scope") as String
      val language = configuration?.get("language") as String
      val tasks = configuration?.get("tasks") as? List<Map<String, Any>>
      val additionalProduct = configuration?.get("additionalProduct") as? String
      val distribution = configuration?.get("distribution") as? Map<String, Any>
      val handoff = configuration?.get("handoff") as? List<String>
      val linkedAccount = configuration?.get("linkedAccount") as? String
      val metadata = configuration?.get("metadata") as? JSONObject
      val theme = configuration?.get("theme") as? Map<String, Any>
      val deeplink = configuration?.get("deeplink") as? Map<String, Any>
      val search = configuration?.get("search") as? Map<String, Any>
      val experiments = configuration?.get("experiments") as? Map<String, Any>

      val config : Config

        config = Config(
          publicToken = publicToken,
          tasks = configTaskFromList(tasks),
          scope = configScopeFromString(scope),
          additionalProduct = if (additionalProduct != null) Config.Product.valueOf(additionalProduct.uppercase()) else null,
          distribution = configDistributionFromMap(distribution),
          linkedAccount = linkedAccount,
          handoff = configHandoffFromList(handoff),
          language = Config.Language.valueOf(language),
          metadata = metadata,
          theme = configThemeFromMap(theme),
          deeplink = configDeeplinkFromMap(deeplink),
          experiments = configExperimentsFromMap(experiments),
          search = configSearchFromMap(search)
        )

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

      Transact.present(activity, config)

    } 
    else if (call.method == "presentAction") {
      val id = call.argument<String>("id") ?: return
      val config = ActionConfig(
          id = id
      )

      Transact.registerReceiver(activity, object: TransactBroadcastReceiver() {
        override fun onClose(data: JSONObject) {
          Transact.unregisterReceiver(activity, this)
          channel.invokeMethod("onCompletion", mapOf("type" to "closed", "response" to mapFromTransactResponseData(data)));
        }
        override fun onFinish(data: JSONObject) {
          Transact.unregisterReceiver(activity, this)
          channel.invokeMethod("onCompletion", mapOf("type" to "finished", "response" to mapFromTransactResponseData(data)))
        }
        override fun onLaunch() {
          channel.invokeMethod("onLaunch", null)
        }
      })

      Transact.presentAction(activity, config)
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
        val item = it.replace('-', '_').uppercase()
        result.add(Config.Handoff.valueOf(item))
      }

      return result
    }

    return null
  }

  private fun configScopeFromString(value: String?): Config.Scope {
    if (value == "user-link") {
      return Config.Scope.USER_LINK
    } else if (value == "pay-link") {
      return Config.Scope.PAY_LINK
    }
    return Config.Scope.USER_LINK
  }

  private fun configTaskFromList(value: List<Map<String, Any?>>?): List<Config.Task> {
    val result = mutableListOf<Config.Task>()

    value?.forEach {
      result.add(Config.Task(
              product = Config.Product.valueOf((it["product"] as String).uppercase()),
              distribution = configDistributionFromMap(it["distribution"] as? Map<String, Any> )))
    }

    return result
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
      val ruleId = value["ruleId"] as? String

      if(value["tags"] != null) {
        val valueTags = value["tags"] as List<String>

        valueTags.forEach {
          val item = it.replace('-', '_').uppercase()
          tags.add(Config.Search.Tag.valueOf(item))
        }
      }

      if(value["excludedTags"] != null) {
        val valueExcludedTags = value["excludedTags"] as List<String>

        valueExcludedTags.forEach {
          val item = it.replace('-', '_').uppercase()
          excludedTags.add(Config.Search.Tag.valueOf(item))
        }
      }

      return Config.Search(
              tags = tags,
              excludedTags = excludedTags,
              ruleId = ruleId 
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
    result["identifier"] = value.optString("identifier")
    result["customer"] = value.optString("customer")
    result["language"] = value.optString("language")
    result["product"] = value.optString("product")
    result["additionalProduct"] = value.optString("additionalProduct")
    result["payroll"] = value.optString("payroll")
    result["company"] = value.optString("company")
    result["value"] = toMap(value)

    return result.toMap()
  }

  private fun mapFromTransactDataRequest(data: JSONObject): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>();

    result["identifier"] = data.optString("identifier")

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

  private fun toMap(json: JSONObject): Map<String, Any?>? {
    val map = mutableMapOf<String, Any?>()
    val keys = json.keys()
    while (keys.hasNext()) {
      val key = keys.next() as String
      map[key] = fromJson(json[key])
    }
    return map
  }

  private fun toList(array: JSONArray): List<Any?>? {
    val list = mutableListOf<Any?>()
    for (i in 0 until array.length()) {
      list.add(fromJson(array.get(i)))
    }
    return list
  }

  private fun fromJson(json: Any): Any? {
    return when {
        json === JSONObject.NULL -> {
          null
        }
        json is JSONObject -> {
          toMap(json)
        }
        json is JSONArray -> {
          toList(json as JSONArray)
        }
        else -> {
          json
        }
    }
  }
}
