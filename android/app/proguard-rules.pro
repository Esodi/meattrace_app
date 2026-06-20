# ─────────────────────────────────────────────────────────────────────────────
# Flutter / Dart
# ─────────────────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ─────────────────────────────────────────────────────────────────────────────
# Kotlin
# ─────────────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Lazy { *; }

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}
-dontwarn kotlinx.coroutines.**

# ─────────────────────────────────────────────────────────────────────────────
# Firebase / FCM
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Required for Firebase messaging background handler
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }
-keep class * extends com.google.firebase.messaging.FirebaseMessagingService { *; }

# ─────────────────────────────────────────────────────────────────────────────
# flutter_local_notifications
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ─────────────────────────────────────────────────────────────────────────────
# flutter_blue_plus (BLE)
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.boskokg.flutter_blue_plus.** { *; }
-dontwarn com.boskokg.flutter_blue_plus.**
# RxAndroidBle (used internally by some BLE libs)
-keep class com.polidea.rxandroidble2.** { *; }
-dontwarn com.polidea.rxandroidble2.**

# ─────────────────────────────────────────────────────────────────────────────
# QR code (qr_code_scanner_plus / ZXing)
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**

# ─────────────────────────────────────────────────────────────────────────────
# ESC/POS printer (esc_pos_utils)
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.dantsu.escposprinter.** { *; }
-dontwarn com.dantsu.escposprinter.**

# ─────────────────────────────────────────────────────────────────────────────
# SQLite / sqflite
# ─────────────────────────────────────────────────────────────────────────────
-keep class * extends android.database.sqlite.SQLiteOpenHelper { *; }
-keep class * extends android.database.sqlite.SQLiteDatabase { *; }

# ─────────────────────────────────────────────────────────────────────────────
# Dio / OkHttp / Retrofit annotations (used for HTTP client)
# ─────────────────────────────────────────────────────────────────────────────
-keepattributes Signature, InnerClasses, EnclosingMethod
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-dontwarn retrofit2.**
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions$*
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit

# OkHttp
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase
-adaptresourcefilenames okhttp3/internal/publicsuffix/PublicSuffixDatabase.gz
-dontwarn okhttp3.**
-dontwarn org.codehaus.mojo.animal_sniffer.*

# ─────────────────────────────────────────────────────────────────────────────
# Gson (JSON serialisation used by Dio responses)
# ─────────────────────────────────────────────────────────────────────────────
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter { *; }
-keep class * implements com.google.gson.TypeAdapterFactory { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }

# ─────────────────────────────────────────────────────────────────────────────
# Geolocator
# ─────────────────────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ─────────────────────────────────────────────────────────────────────────────
# image_picker
# ─────────────────────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# ─────────────────────────────────────────────────────────────────────────────
# share_plus / url_launcher
# ─────────────────────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# ─────────────────────────────────────────────────────────────────────────────
# connectivity_plus
# ─────────────────────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# ─────────────────────────────────────────────────────────────────────────────
# Google Play Core (split install — suppresses lint warnings on AAB builds)
# ─────────────────────────────────────────────────────────────────────────────
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# ─────────────────────────────────────────────────────────────────────────────
# Keep line numbers for crash reporting (remove if you want full obfuscation)
# ─────────────────────────────────────────────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
