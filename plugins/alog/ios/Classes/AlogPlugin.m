#import "AlogPlugin.h"
#if __has_include(<alog/alog-Swift.h>)
#import <alog/alog-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "alog-Swift.h"
#endif

@implementation AlogPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAlogPlugin registerWithRegistrar:registrar];
}
@end
