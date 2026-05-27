#import <Foundation/Foundation.h>

extern NSString *const kAppGroupID;
extern NSString *const kVPNStatusKey;

@interface AppGroup : NSObject

+ (NSUserDefaults *)sharedDefaults;
+ (void)setVPNRunning:(BOOL)running;
+ (BOOL)isVPNRunning;

@end
