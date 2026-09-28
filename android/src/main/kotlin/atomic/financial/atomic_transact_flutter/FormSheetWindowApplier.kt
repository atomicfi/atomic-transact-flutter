package atomic.financial.atomic_transact_flutter

import android.app.Activity
import android.app.Application
import android.graphics.Color
import android.graphics.Outline
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewOutlineProvider
import android.view.WindowManager

/**
 * PoC — approximates iOS formSheet on Android by resizing TransactActivity's window.
 *
 * Ideal upstream fix: Atomic presents via BottomSheetDialogFragment (or equivalent) inside
 * the host Activity instead of startActivity(TransactActivity) with a Fullscreen theme.
 */
internal object FormSheetWindowApplier {
    private const val TRANSACT_ACTIVITY =
        "financial.atomic.transact.activity.TransactActivity"
    private const val HEIGHT_FRACTION = 0.92f
    private const val TOP_RADIUS_DP = 16f

    private var callbacks: Application.ActivityLifecycleCallbacks? = null

    fun enable(application: Application) {
        if (callbacks != null) return
        val cb = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
                if (activity.javaClass.name == TRANSACT_ACTIVITY) {
                    // Hide residual Dialog title (host application label).
                    activity.title = ""
                    activity.actionBar?.hide()
                    apply(activity)
                }
            }

            override fun onActivityResumed(activity: Activity) {
                if (activity.javaClass.name == TRANSACT_ACTIVITY) apply(activity)
            }

            override fun onActivityStarted(activity: Activity) = Unit
            override fun onActivityPaused(activity: Activity) = Unit
            override fun onActivityStopped(activity: Activity) = Unit
            override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
            override fun onActivityDestroyed(activity: Activity) = Unit
        }
        callbacks = cb
        application.registerActivityLifecycleCallbacks(cb)
    }

    fun disable(application: Application) {
        callbacks?.let { application.unregisterActivityLifecycleCallbacks(it) }
        callbacks = null
    }

    private fun apply(activity: Activity) {
        val metrics = activity.resources.displayMetrics
        val width = ViewGroup.LayoutParams.MATCH_PARENT
        val height = (metrics.heightPixels * HEIGHT_FRACTION).toInt()
        val radiusPx = TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            TOP_RADIUS_DP,
            metrics,
        )

        activity.window?.apply {
            setLayout(width, height)
            setGravity(Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL)
            addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            attributes = attributes?.apply {
                dimAmount = 0.45f
                gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                this.width = metrics.widthPixels
                this.height = height
                y = 0
                horizontalMargin = 0f
            }

            // Clip decor to rounded top corners (content + chrome).
            decorView.post {
                clipTopRounded(decorView, radiusPx)
            }
        }
    }

    private fun clipTopRounded(view: View, radiusPx: Float) {
        view.outlineProvider = object : ViewOutlineProvider() {
            override fun getOutline(v: View, outline: Outline) {
                // Extra height below so only top corners are visibly rounded.
                outline.setRoundRect(0, 0, v.width, v.height + radiusPx.toInt(), radiusPx)
            }
        }
        view.clipToOutline = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            view.setBackgroundColor(Color.WHITE)
        }
    }
}
