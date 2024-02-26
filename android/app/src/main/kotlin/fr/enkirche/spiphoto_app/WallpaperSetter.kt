package fr.enkirche.spiphoto_app

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.app.WallpaperManager
import android.graphics.BitmapFactory
import java.io.IOException

class WallpaperSetter: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "wallpaper_setter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: io.flutter.plugin.common.MethodCall, @NonNull result: Result) {
    if (call.method == "setWallpaper") {
      val args = call.arguments as Map<*, *>
      val imagePath = args["path"] as String
      setWallpaper(imagePath)
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  private fun setWallpaper(imagePath: String) {
    val bitmap = BitmapFactory.decodeFile(imagePath)
    val wallpaperManager = WallpaperManager.getInstance(context)
    try {
      wallpaperManager.setBitmap(bitmap)
    } catch (e: IOException) {
      e.printStackTrace()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
