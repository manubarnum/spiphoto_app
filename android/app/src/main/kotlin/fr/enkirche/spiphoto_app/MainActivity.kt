package fr.enkirche.spiphoto_app

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL

class MainActivity: FlutterActivity() {
    private val CHANNEL = "fr.enkirche/wallpaper"

    companion object {
        private const val ENGINE_ID = "spiphoto_engine"
    }

    // Poser un fond d'écran change les couleurs système (Material You) sur
    // Android 12+, ce qui recrée l'activité. Avec le moteur par défaut,
    // l'app Dart repartait alors de zéro, sur l'accueil. Un moteur en cache
    // survit à la recréation : l'activité s'y rebranche avec l'état intact.
    // Un moteur fourni ainsi n'est pas détruit avec l'activité. Ses plugins
    // sont enregistrés par le constructeur FlutterEngine(context) lui-même
    // (automaticallyRegisterPlugins) : ne pas les réenregistrer ici.
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        return FlutterEngineCache.getInstance().get(ENGINE_ID)
            ?: FlutterEngine(context.applicationContext).also { engine ->
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint.createDefault()
                )
                FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Vérifier si flutterEngine n'est pas null
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "setWallpaper") {
                    val imageUrl = call.argument<String>("imageUrl")
                    // Fichier de l'image dans le cache disque côté Flutter,
                    // quand l'aperçu l'a déjà chargée.
                    val imagePath = call.argument<String>("imagePath")
                    val wallpaperType = call.argument<Int>("wallpaperType")
                    // Zone à conserver [gauche, haut, droite, bas], en fractions
                    // de l'image (0..1). Optionnelle : image entière si absente.
                    val crop = call.argument<List<Double>>("crop")

                    if (imageUrl != null && wallpaperType != null) {
                        // Lancer une coroutine pour définir le fond d'écran
                        CoroutineScope(Dispatchers.Main).launch {
                            val success = setWallpaper(imageUrl, imagePath, wallpaperType, crop)
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
    private suspend fun setWallpaper(imageUrl: String, imagePath: String?, wallpaperType: Int, crop: List<Double>?): Boolean {
        return withContext(Dispatchers.IO) {
            var bitmap: Bitmap? = null
            try {
                // Image lue dans le cache disque si possible, téléchargée sinon.
                bitmap = imagePath?.let { BitmapFactory.decodeFile(it) } ?: telecharger(imageUrl)
                if (bitmap == null) return@withContext false

                // Zone choisie dans l'aperçu, passée comme zone visible sur
                // l'image entière : le système la garde à l'écran et prend
                // sa marge de parallaxe dans les pixels autour. Une image
                // pré-découpée aux proportions de l'écran ne lui laisse pas
                // cette marge : il zoome alors au-delà de l'aperçu.
                val zoneVisible = crop?.let { zoneEnPixels(bitmap, it) }

                // Définir le fond d'écran
                val wallpaperManager = WallpaperManager.getInstance(applicationContext)
                when (wallpaperType) {
                    1 -> wallpaperManager.setBitmap(bitmap, zoneVisible, true, WallpaperManager.FLAG_SYSTEM) // Écran d'accueil
                    2 -> wallpaperManager.setBitmap(bitmap, zoneVisible, true, WallpaperManager.FLAG_LOCK)   // Écran de verrouillage
                    3 -> wallpaperManager.setBitmap(bitmap, zoneVisible, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK) // Les deux
                }
                true // Succès
            } catch (e: Exception) {
                e.printStackTrace()
                false // Échec
            } finally {
                // setBitmap() copie les pixels en interne, donc on peut
                // libérer la mémoire native du bitmap ici sans risque.
                bitmap?.recycle()
            }
        }
    }

    // Télécharge l'image depuis l'URL — connexion + flux fermés via .use{}
    // même en cas d'exception pendant le décodage.
    private fun telecharger(imageUrl: String): Bitmap? {
        val connection: HttpURLConnection = URL(imageUrl).openConnection() as HttpURLConnection
        connection.doInput = true
        connection.connect()
        try {
            return connection.inputStream.use { input -> BitmapFactory.decodeStream(input) }
        } finally {
            connection.disconnect()
        }
    }

    // Convertit la zone [gauche, haut, droite, bas], exprimée en fractions
    // de l'image, en pixels. Bornée pour toujours garder au moins 1 px.
    private fun zoneEnPixels(source: Bitmap, crop: List<Double>): Rect? {
        if (crop.size != 4) return null
        val gauche = (crop[0] * source.width).toInt().coerceIn(0, source.width - 1)
        val haut = (crop[1] * source.height).toInt().coerceIn(0, source.height - 1)
        val droite = (crop[2] * source.width).toInt().coerceIn(gauche + 1, source.width)
        val bas = (crop[3] * source.height).toInt().coerceIn(haut + 1, source.height)
        return Rect(gauche, haut, droite, bas)
    }
}
