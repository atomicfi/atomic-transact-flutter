package atomic.financial.atomic_transact_flutter

import android.app.Activity
import android.content.Context
import android.content.IntentFilter
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import financial.atomic.transact.*
import financial.atomic.transact.receiver.TransactBroadcastReceiver
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.json.JSONArray


/** AtomicTransactFlutterPlugin */
class AtomicTransactFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context : Context
  private var activity : Activity? = null
  private var pausedTransactRef: PausedTransactRef? = null

  /// Every presented flow that hasn't cleaned up yet, keyed by the instance id Dart generated for
  /// it. Each flow keeps its own receiver, so presenting again never replaces an earlier flow's.
  private val instances = mutableMapOf<String, TransactInstance>()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    context = flutterPluginBinding.applicationContext
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "atomic_transact_flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "presentTransact") {
      val instanceId = call.argument<String>("instanceId")
      val transactPath = call.argument<String>("transactPath") as String? ?: ""
      val apiPath = call.argument<String>("apiPath") as String? ?: ""
      val pluginVersion = call.argument<String>("pluginVersion") ?: ""
      val suffix = if (pluginVersion.isNotEmpty()) "flutter-$pluginVersion" else "flutter"
      val debug = call.argument<Boolean>("debug") ?: false
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
      val deferredPaymentMethodStrategy = configuration?.get("deferredPaymentMethodStrategy") as? String
      
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
          search = configSearchFromMap(search),
          environment = Config.Environment.CUSTOM,
          environmentURL = transactPath,
          deferredPaymentMethodStrategy =
            configDeferredPaymentMethodStrategyFromString(deferredPaymentMethodStrategy),
          debug = debug
        )

      config.platform = Config.Platform.suffixed(suffix)

      if (instanceId == null) {
        result.error("ConfigError", "Missing instanceId", null)
        return
      }
      val activity = this.activity
      if (activity == null) {
        result.error("PlatformError", "No activity found", null)
        return
      }

      val instance = TransactInstance(instanceId)
      instances[instanceId] = instance
      try {
        instance.present(activity, config)
      } catch (e: Exception) {
        instance.discard(activity)
        result.error("PresentError", e.message, null)
        return
      }
      result.success(null)
    }
    else if (call.method == "dismissTransact") {
      // Ends every flow that hasn't finished or closed yet, including hidden and paused ones. That
      // matches iOS, where only those flows get a dismissal. Flows that already finished or closed
      // keep running until their own cleanup.
      instances.values.filter { !it.completed }.forEach { it.close() }
      // The paused flow, if any, has just ended, so it can't be resumed.
      pausedTransactRef = null
      result.success(null)
    } else if (call.method == "hideTransact") {
      instances.values.filter { !it.completed }.forEach { it.hide() }
      result.success(null)
    } else if (call.method == "pauseTransact") {
      CoroutineScope(Dispatchers.Main).launch {
        try {
          pausedTransactRef = Transact.pauseTransact()
          result.success(null)
        } catch (e: Transact.PauseTransactException) {
          result.error("PauseTransactError", e.message, null)
        }
      }
    } else if (call.method == "resumeTransact") {
      val ref = pausedTransactRef
      if (ref != null) {
        ref.resume(activity ?: context)
        pausedTransactRef = null
        result.success(null)
      } else {
        result.error("ResumeTransactError", "No paused Transact to resume", null)
      }
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    // Nothing is left to deliver events to.
    instances.values.forEach { it.unregister() }
    instances.clear()
  }

  /// ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    this.activity = binding.activity;
  }

  override fun onDetachedFromActivity() {
    this.activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding);
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  /// One presented flow. [id] is the instance id Dart generated, which every event sent to Dart is
  /// tagged with. The SDK assigns the flow its own id, which the instance-scoped Transact calls take.
  private inner class TransactInstance(val id: String) {
    /// Set once the flow closes or finishes. A task can keep sending status updates after that,
    /// so this instance keeps listening until cleanup.
    var completed = false
      private set

    private var registered = false

    private val receiver: TransactBroadcastReceiver = object : TransactBroadcastReceiver() {
      override fun onClose(data: JSONObject) {
        completed = true
        emit("onCompletion", mapOf("type" to "closed", "response" to mapFromTransactResponseData(data)))

        // The SDK closes with `error` or `user_closed` itself when a flow ends before Transact
        // initializes, or when its page fails to load. Transact never runs to send
        // cleanup-application after those (its own close reasons are kebab-case), so end the
        // task here.
        val reason = data.optString("reason")
        if (reason == "error" || reason == "user_closed") {
          cleanup()
        }
      }
      override fun onFinish(data: JSONObject) {
        completed = true
        emit("onCompletion", mapOf("type" to "finished", "response" to mapFromTransactResponseData(data)))
      }
      override fun onInteraction(data: JSONObject) {
        emit("onInteraction", mapFromTransactInteraction(data))
      }
      override fun onDataRequest(data: JSONObject) {
        // Request/response: whatever Dart replies with is handed straight back to this flow.
        // A null reply (no handler, an error, or nothing to send) leaves Transact waiting,
        // which is the same as having no handler at all.
        channel.invokeMethod(
          "onDataRequest",
          envelope(mapFromTransactDataRequest(data)),
          object : Result {
            override fun success(result: Any?) {
              val response = transactDataResponseFromResult(result) ?: return
              val sdkInstanceId = receiver.instanceId ?: return
              Transact.sendData(context, sdkInstanceId, response)
            }

            override fun error(code: String, message: String?, details: Any?) {
              Log.w("AtomicTransact", "onDataRequest handler failed: $code $message")
            }

            override fun notImplemented() {}
          }
        )
      }
      override fun onLaunch() {
        emit("onLaunch", null)
      }
      override fun onAuthStatusUpdate(authData: Config.TransactAuthStatusUpdate) {
        emit("onAuthStatusUpdate", mapFromTransactAuthStatusUpdate(authData))
      }
      override fun onTaskStatusUpdate(taskData: Config.TaskStatusUpdate) {
        emit("onTaskStatusUpdate", mapFromTransactTaskStatusUpdate(taskData))
      }
      override fun onDebugLog(level: String, tag: String, message: String, data: JSONObject) {
        // Not tagged: the SDK routes every log through the newest flow, whichever flow it's from.
        channel.invokeMethod("onDebugLog", mapOf("message" to "[$level] $tag: $message"))
      }
      override fun onCleanup() {
        cleanup()
      }
    }

    fun present(activity: Activity, config: Config) {
      Transact.present(activity, config, receiver)

      // present() binds the receiver to the new flow and registers it against the activity. Move it
      // to the application context, outside the SDK's registry. The SDK queues its own unregister
      // right after broadcasting cleanup-application, which drops that broadcast before onCleanup
      // is delivered. And tearing down an action flow unregisters every receiver registered against
      // the activity, including other flows' receivers.
      Transact.unregisterReceiver(activity, receiver)
      // Not exported on every API level, so no other app can send this flow events.
      ContextCompat.registerReceiver(
        context, receiver, IntentFilter(Transact.ACTION_EVENT), ContextCompat.RECEIVER_NOT_EXPORTED)
      registered = true
    }

    /// Undoes a present() that threw partway through. Dart hears about it from the error reply.
    fun discard(activity: Activity) {
      Transact.unregisterReceiver(activity, receiver)
      cleanup(notifyDart = false)
    }

    /// The SDK sends nothing back when the host closes a flow, so this ends the task itself.
    fun close() {
      receiver.instanceId?.let { Transact.close(context, it) }
      cleanup()
    }

    fun hide() {
      receiver.instanceId?.let { Transact.hideTransact(context, it) }
    }

    /// Ends the task and, unless [notifyDart] is false, tells Dart. Runs at most once per flow.
    fun cleanup(notifyDart: Boolean = true) {
      if (instances.remove(id) == null) {
        return
      }
      unregister()
      if (notifyDart) {
        emit("onCleanup", null)
      }
    }

    fun unregister() {
      if (!registered) {
        return
      }
      registered = false
      try {
        context.unregisterReceiver(receiver)
      } catch (e: IllegalArgumentException) {
        // Already unregistered.
      }
    }

    private fun emit(method: String, data: Any?) {
      channel.invokeMethod(method, envelope(data))
    }

    private fun envelope(data: Any?): Map<String, Any?> = mapOf("instanceId" to id, "data" to data)
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
              product = (it["product"] as? String)?.let { Config.Product.valueOf(it.uppercase()) },
              operation = (it["operation"] as? String)?.let { Config.Product.valueOf(it.uppercase()) },
              distribution = configDistributionFromMap(it["distribution"] as? Map<String, Any>),
              apps = it["apps"] as? List<String>))
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
      val step = value["step"] as? String
      val app = value["app"] as? String
      val companyId = value["companyId"] as? String
      val companyName = value["companyName"] as? String
      val connectorId = value["connectorId"] as? String
      val singleSwitch = value["singleSwitch"] as? Boolean ?: false
      val payments = value["payments"] as? List<String>
      val accountId = value["accountId"] as? String

      val stepEnum = if (step != null) {
        val stepFormatted = step.replace('-', '_').uppercase()
        Config.Deeplink.Step.valueOf(stepFormatted)
      } else {
        Config.Deeplink.Step.EMPTY
      }

      val appEnum = if (app != null) {
        val appFormatted = app.replace('-', '_').uppercase()
        Config.Deeplink.App.valueOf(appFormatted)
      } else {
        Config.Deeplink.App.EMPTY
      }

      return Config.Deeplink(
              step = stepEnum,
              app = appEnum,
              companyId = companyId,
              companyName = companyName,
              connectorId = connectorId,
              singleSwitch = singleSwitch,
              payments = payments,
              accountId = accountId
      )
    }

    return null
  }

  private fun configDeferredPaymentMethodStrategyFromString(
    value: String?
  ): Config.DeferredPaymentMethodStrategy? {
    if (value == null) {
      return null
    }

    return Config.DeferredPaymentMethodStrategy.values().firstOrNull {
      it.name.equals(value, ignoreCase = true)
    }
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
    val name = data.optString("name")
    val value = data.optJSONObject("value")

    result["name"] = name
    if (value != null) {
      result["identifier"] = value.optString("identifier")
      result["customer"] = value.optString("customer")
      result["language"] = value.optString("language")
      result["product"] = value.optString("product")
      result["additionalProduct"] = value.optString("additionalProduct")
      result["payroll"] = value.optString("payroll")
      result["company"] = value.optString("company")
      result["value"] = toMap(value)
    } else {
      result["identifier"] = ""
      result["customer"] = ""
      result["language"] = ""
      result["product"] = ""
      result["additionalProduct"] = ""
      result["payroll"] = ""
      result["company"] = ""
      result["value"] = null
    }

    return result.toMap()
  }

  private fun mapFromTransactDataRequest(data: JSONObject): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>();

    result["taskId"] = data.optString("taskId")
    result["userId"] = data.optString("userId")
    result["identifier"] = data.optString("identifier")

    val fields = mutableListOf<String>()
    val jArray = data.optJSONArray("fields")

    if (jArray != null) {
      for (i in 0 until jArray.length()) {
        fields.add(jArray.optString(i))
      }
    }

    result["fields"] = fields.toList()
    // Mirrors iOS, where `data` carries the whole request payload so consumers can read
    // anything Transact sends that isn't modeled above.
    result["data"] = toMap(data)

    return result.toMap()
  }

  /// Data request response converters

  private fun transactDataResponseFromResult(result: Any?): Config.TransactDataResponse? {
    val response = result as? Map<*, *> ?: return null
    val card = transactCardDataFromMap(response["card"] as? Map<*, *>)
    val identity = transactIdentityFromMap(response["identity"] as? Map<*, *>)

    if (card == null && identity == null) {
      return null
    }

    return Config.TransactDataResponse(card = card, identity = identity)
  }

  private fun transactCardDataFromMap(
    value: Map<*, *>?
  ): Config.TransactDataResponse.CardData? {
    // The SDK requires a card number; anything else is not a usable card response.
    val number = value?.get("number") as? String ?: return null
    val cardType = (value["cardType"] as? String)?.let { type ->
      Config.TransactDataResponse.CardType.values().firstOrNull {
        it.name.equals(type, ignoreCase = true)
      }
    }

    return Config.TransactDataResponse.CardData(
            number = number,
            expiry = value["expiry"] as? String,
            cvv = value["cvv"] as? String,
            cardType = cardType
    )
  }

  private fun transactIdentityFromMap(
    value: Map<*, *>?
  ): Config.TransactDataResponse.Identity? {
    if (value == null) {
      return null
    }

    return Config.TransactDataResponse.Identity(
            firstName = value["firstName"] as? String,
            lastName = value["lastName"] as? String,
            postalCode = value["postalCode"] as? String,
            address = value["address"] as? String,
            address2 = value["address2"] as? String,
            city = value["city"] as? String,
            state = value["state"] as? String,
            phone = value["phone"] as? String,
            email = value["email"] as? String
    )
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

  private fun mapFromTransactAuthStatusUpdate(authData: Config.TransactAuthStatusUpdate): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>()
    
    // Map company data
    val company = mutableMapOf<String, Any?>()
    company["id"] = authData.company.id
    company["name"] = authData.company.name
    
    // Map branding if present
    authData.company.branding?.let { branding ->
        val brandingMap = mutableMapOf<String, Any?>()
        brandingMap["color"] = branding.color
        
        // Map logo data
        val logoMap = mutableMapOf<String, Any?>()
        logoMap["url"] = branding.logo.url
        branding.logo.backgroundColor?.let { logoMap["backgroundColor"] = it }
        
        brandingMap["logo"] = logoMap
        company["branding"] = brandingMap
    }
    
    result["company"] = company
    result["status"] = authData.status.name.lowercase()
    
    return result.toMap()
  }

  private fun mapFromTransactTaskStatusUpdate(taskData: Config.TaskStatusUpdate): Map<String, Any?> {
    val result = mutableMapOf<String, Any?>()
    
    result["taskId"] = taskData.taskId
    result["product"] = taskData.product.name.lowercase()
    result["status"] = taskData.status.name.lowercase()
    result["failReason"] = taskData.failReason
    
    // Map company data
    val company = mutableMapOf<String, Any?>()
    company["id"] = taskData.company.id
    company["name"] = taskData.company.name
    
    // Map branding if present
    taskData.company.branding?.let { branding ->
        val brandingMap = mutableMapOf<String, Any?>()
        brandingMap["color"] = branding.color
        
        val logoMap = mutableMapOf<String, Any?>()
        logoMap["url"] = branding.logo.url
        branding.logo.backgroundColor?.let { logoMap["backgroundColor"] = it }
        
        brandingMap["logo"] = logoMap
        company["branding"] = brandingMap
    }
    result["company"] = company
    
    // Map switch data if present
    taskData.switchData?.let { switchData ->
        val switchMap = mutableMapOf<String, Any?>()
        val paymentMethod = mutableMapOf<String, Any?>()
        
        with(switchData.paymentMethod) {
            paymentMethod["id"] = id
            paymentMethod["title"] = title
            paymentMethod["type"] = type.name.lowercase()
            expiry?.let { paymentMethod["expiry"] = it }
            brand?.let { paymentMethod["brand"] = it }
            lastFour?.let { paymentMethod["lastFour"] = it }
            routingNumber?.let { paymentMethod["routingNumber"] = it }
            accountType?.let { paymentMethod["accountType"] = it }
            lastFourAccountNumber?.let { paymentMethod["lastFourAccountNumber"] = it }
        }
        
        switchMap["paymentMethod"] = paymentMethod
        result["switchData"] = switchMap
    }
    
    // Map deposit data if present
    taskData.depositData?.let { depositData ->
        val depositMap = mutableMapOf<String, Any?>()
        
        depositData.accountType?.let { depositMap["accountType"] = it }
        depositData.distributionAmount?.let { depositMap["distributionAmount"] = it }
        depositData.distributionType?.let { depositMap["distributionType"] = it }
        depositData.lastFour?.let { depositMap["lastFour"] = it }
        depositData.routingNumber?.let { depositMap["routingNumber"] = it }
        depositData.title?.let { depositMap["title"] = it }
        
        result["depositData"] = depositMap
    }
    
    // Map managedBy if present
    taskData.managedBy?.let { managedBy ->
        val managedByMap = mutableMapOf<String, Any?>()
        val managedByCompany = mutableMapOf<String, Any?>()
        
        managedByCompany["id"] = managedBy.company.id
        managedByCompany["name"] = managedBy.company.name
        
        managedBy.company.branding?.let { branding ->
            val brandingMap = mutableMapOf<String, Any?>()
            brandingMap["color"] = branding.color
            
            val logoMap = mutableMapOf<String, Any?>()
            logoMap["url"] = branding.logo.url
            branding.logo.backgroundColor?.let { logoMap["backgroundColor"] = it }
            
            brandingMap["logo"] = logoMap
            managedByCompany["branding"] = brandingMap
        }
        
        managedByMap["company"] = managedByCompany
        result["managedBy"] = managedByMap
    }
    
    return result.toMap()
  }
}
