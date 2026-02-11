# Vosk Speech Recognition - JNA rules
# Keep all JNA classes to prevent "Can't obtain peer field ID" errors
-keep class com.sun.jna.** { *; }
-keepclassmembers class com.sun.jna.** { *; }
-keep class * implements com.sun.jna.** { *; }

# Keep the Vosk library classes
-keep class org.vosk.** { *; }
-keepclassmembers class org.vosk.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep JNA Pointer and related classes specifically
-keep class com.sun.jna.Pointer { *; }
-keep class com.sun.jna.Native { *; }
-keep class com.sun.jna.Memory { *; }
-keep class com.sun.jna.Structure { *; }
-keep class com.sun.jna.Callback { *; }
-keep class com.sun.jna.platform.** { *; }

# Keep field names for JNA structures
-keepclassmembers class * extends com.sun.jna.Structure {
    public *;
}

# Don't warn about JNA classes
-dontwarn com.sun.jna.**
-dontwarn org.vosk.**

# Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class org.vosk.vosk_flutter.** { *; }
