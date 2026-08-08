package com.starforge.starforge_student

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.starforge.starforge_student/firebase_config",
        ).setMethodCallHandler { call, result ->
            if (call.method == "hasNativeFirebaseConfig") {
                val googleAppId = resources.getIdentifier("google_app_id", "string", packageName)
                result.success(googleAppId != 0)
            } else {
                result.notImplemented()
            }
        }
    }
}
