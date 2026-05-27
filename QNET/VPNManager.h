#import <Foundation/Foundation.h>

@interface VPNManager : NSObject

+ (instancetype)shared;

@property (nonatomic, readonly) BOOL isConnected;

- (void)connect:(void(^)(NSError *error))completion;
- (void)disconnect;
- (void)checkStatus:(void(^)(BOOL connected))completion;

@end
