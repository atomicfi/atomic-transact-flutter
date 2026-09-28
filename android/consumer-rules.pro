# Transact 3.24.1 compiles against Uplink (build.uplink.*) without depending on it, and ships no
# -dontwarn for it. Flutter minifies every release build, so without this R8 fails any app that
# doesn't include Uplink with "Missing class build.uplink.UplinkKt". The SDK copes with Uplink being
# absent at runtime. The next Transact release ships this rule itself (SDK-837); it's harmless after.
-dontwarn build.uplink.**
