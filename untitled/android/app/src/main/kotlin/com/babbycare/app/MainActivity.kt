package com.babbycare.app

import com.google.android.play.core.appupdate.AppUpdateInfo
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var appUpdateManager: AppUpdateManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appUpdateManager = AppUpdateManagerFactory.create(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            UPDATE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAndStartImmediateUpdate" -> checkAndStartUpdate(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndStartUpdate(result: MethodChannel.Result) {
        appUpdateManager.appUpdateInfo
            .addOnSuccessListener { info -> handleUpdateInfo(info, result) }
            .addOnFailureListener { error ->
                result.error("UPDATE_CHECK_FAILED", error.message, null)
            }
    }

    private fun handleUpdateInfo(info: AppUpdateInfo, result: MethodChannel.Result) {
        val availability = info.updateAvailability()
        val updateAvailable =
            availability == UpdateAvailability.UPDATE_AVAILABLE ||
                availability == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS
        if (!updateAvailable) {
            result.success(false)
            return
        }

        if (!info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
            result.error(
                "IMMEDIATE_UPDATE_NOT_ALLOWED",
                "Google Play reported an update but did not allow an immediate update.",
                null,
            )
            return
        }

        val started = appUpdateManager.startUpdateFlowForResult(
            info,
            AppUpdateType.IMMEDIATE,
            this,
            UPDATE_REQUEST_CODE,
        )
        if (!started) {
            result.error(
                "UPDATE_START_FAILED",
                "Google Play could not start the immediate update.",
                null,
            )
            return
        }
        // The update screen now owns the UI. Dart keeps its blocking screen in
        // place if the user cancels and checks again when the app resumes.
        result.success(true)
    }

    companion object {
        private const val UPDATE_CHANNEL = "com.babbycare.app/play_update"
        private const val UPDATE_REQUEST_CODE = 7104
    }
}
