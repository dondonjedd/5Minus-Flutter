# Guava references J2ObjC annotations that are not on the Android classpath.
# R8 only needs them at compile time; they are unused at runtime.
-dontwarn com.google.j2objc.annotations.ReflectionSupport
-dontwarn com.google.j2objc.annotations.**
