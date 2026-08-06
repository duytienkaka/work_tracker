package com.example.work_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "work_tracker/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "updateWidget") {
                    val title = call.argument<String>("title") ?: "Work Tracker"
                    val subtitle = call.argument<String>("subtitle") ?: "Open the app to see your shifts"
                    getSharedPreferences("widget_state", MODE_PRIVATE).edit()
                        .putString("title", title)
                        .putString("subtitle", subtitle)
                        .apply()
                    WorkTrackerWidget.refresh(this)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
