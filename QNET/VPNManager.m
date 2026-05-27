#import "VPNManager.h"
#import <NetworkExtension/NetworkExtension.h>
#import "AppGroup.h"

static NSString *const kExtBundleID = @"com.tencent.qnet.simple.packet-handler";
static NSString *const kServerAddress = @"106.54.179.198";

@interface VPNManager ()
@property (nonatomic, strong) NETunnelProviderManager *manager;
@end

@implementation VPNManager

+ (instancetype)shared {
    static VPNManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[VPNManager alloc] init]; });
    return instance;
}

#pragma mark - Public

- (void)connect:(void(^)(NSError *error))completion {
    NETunnelProviderManager *mgr = self.manager ?: [[NETunnelProviderManager alloc] init];

    NETunnelProviderProtocol *proto = [[NETunnelProviderProtocol alloc] init];
    proto.providerBundleIdentifier = kExtBundleID;
    proto.serverAddress = kServerAddress;
    proto.providerConfiguration = @{
        @"server": kServerAddress,
        @"port": @8888,
    };
    mgr.protocolConfiguration = proto;
    mgr.localizedDescription = @"QNET VPN";
    mgr.enabled = YES;

    [mgr saveToPreferencesWithCompletionHandler:^(NSError *saveError) {
        if (saveError) { if (completion) completion(saveError); return; }
        [mgr loadFromPreferencesWithCompletionHandler:^(NSError *loadError) {
            if (loadError) { if (completion) completion(loadError); return; }
            self.manager = mgr;
            NSError *startErr;
            [mgr.connection startVPNTunnelAndReturnError:&startErr];
            if (completion) completion(startErr);
        }];
    }];
}

- (void)disconnect {
    [self.manager.connection stopVPNTunnel];
}

- (void)checkStatus:(void(^)(BOOL connected))completion {
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> *managers, NSError *error) {
        NETunnelProviderManager *mgr = managers.firstObject;
        if (!mgr) { if (completion) completion(NO); return; }
        self.manager = mgr;
        BOOL connected = (mgr.connection.status == NEVPNStatusConnected);
        if (completion) completion(connected);
    }];
}

- (BOOL)isConnected {
    return self.manager.connection.status == NEVPNStatusConnected;
}

@end
