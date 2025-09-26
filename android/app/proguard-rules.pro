# Keep Flutter classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Firebase and Google Play services models
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Ignore warnings from kotlin metadata
-dontwarn kotlin.**
-dontwarn org.jetbrains.**

