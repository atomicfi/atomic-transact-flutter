#import "AtomicTransactFlutterPlugin.h"
#if __has_include(<atomic_transact_flutter/atomic_transact_flutter-Swift.h>)
#import <atomic_transact_flutter/atomic_transact_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "atomic_transact_flutter-Swift.h"
#endif

@implementation AtomicTransactFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAtomicTransactFlutterPlugin registerWithRegistrar:registrar];
}
@end
