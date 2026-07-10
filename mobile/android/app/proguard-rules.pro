# Flutter / R8 — conserver les plugins courants
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
