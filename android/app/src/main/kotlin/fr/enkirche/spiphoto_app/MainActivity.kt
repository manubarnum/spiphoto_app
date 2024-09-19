package fr.enkirche.spiphoto_app

import android.app.WallpaperManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL

class MainActivity: FlutterActivity() {
    private val CHANNEL = "fr.enkirche/wallpaper"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Vérifier si flutterEngine n'est pas null
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "setWallpaper") {
                    val imageUrl = call.argument<String>("imageUrl")
                    val wallpaperType = call.argument<Int>("wallpaperType")

                    if (imageUrl != null && wallpaperType != null) {
                        // Lancer une coroutine pour définir le fond d'écran
                        CoroutineScope(Dispatchers.Main).launch {
                            val success = setWallpaper(imageUrl, wallpaperType)
                            if (success) {
                                result.success("Fond d'écran défini avec succès")
                            } else {
                                result.error("UNAVAILABLE", "Erreur lors de la définition du fond d'écran", null)
                            }
                        }
                    } else {
                        result.error("UNAVAILABLE", "Erreur lors de la récupération des arguments", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    // Fonction suspendue pour définir le fond d'écran avec coroutines
    private suspend fun setWallpaper(imageUrl: String, wallpaperType: Int): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Télécharger l'image depuis l'URL
                val url = URL(imageUrl)
                val connection: HttpURLConnection = url.openConnection() as HttpURLConnection
                connection.doInput = true
                connection.connect()
                val input: InputStream = connection.inputStream
                val bitmap = BitmapFactory.decodeStream(input)

                // Sauvegarder l'image temporairement dans un répertoire dédié à l'application
                val directory = getExternalFilesDir(null)
                val file = File(directory, "wallpaper_temp.jpg")
                val outputStream = FileOutputStream(file)
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
                outputStream.flush()
                outputStream.close()

                // Définir le fond d'écran
                val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                when (wallpaperType) {
                    1 -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM) // Écran d'accueil
                    2 -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)   // Écran de verrouillage
                    3 -> wallpaperManager.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK) // Les deux
                }
                true // Succès
            } catch (e: Exception) {
                e.printStackTrace()
                false // Échec
            }
        }
    }
}
