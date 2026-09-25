# Transact 3.24.1 references Uplink (build.uplink.*) without depending on it or shipping a
# -dontwarn for it, and Flutter always runs R8 on release builds, so without these the release build
# fails with "Missing class build.uplink.UplinkKt". These are the rules R8 itself generates
# (build/app/outputs/mapping/release/missing_rules.txt); a Flutter app built for release needs the same.
-dontwarn build.uplink.UplinkKt
-dontwarn build.uplink.worker.Worker
