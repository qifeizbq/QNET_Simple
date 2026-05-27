#import "AppGroup.h"

NSString *const kAppGroupID = @"group.com.tencent.qnet.simple";
NSString *const kVPNStatusKey = @"vpn_is_running";

@implementation AppGroup

+ (NSUserDefaults *)sharedDefaults {
    return [[NSUserDefaults alloc] initWithSuiteName:kAppGroupID];
}

+ (void)setVPNRunning:(BOOL)running {
    [[self sharedDefaults] setBool:running forKey:kVPNStatusKey];
    [[self sharedDefaults] synchronize];
}

+ (BOOL)isVPNRunning {
    return [[self sharedDefaults] boolForKey:kVPNStatusKey];
}

@end
