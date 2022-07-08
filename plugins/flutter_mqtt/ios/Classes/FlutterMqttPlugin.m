#import "FlutterMqttPlugin.h"
#if __has_include(<flutter_mqtt/flutter_mqtt-Swift.h>)
#import <flutter_mqtt/flutter_mqtt-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_mqtt-Swift.h"
#endif

@implementation FlutterMqttPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterMqttPlugin registerWithRegistrar:registrar];
}
@end
