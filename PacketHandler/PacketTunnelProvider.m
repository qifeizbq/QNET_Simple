#import "PacketTunnelProvider.h"
#import "AppGroup.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

@interface PacketTunnelProvider ()
@property (nonatomic, assign) int serverSocket;
@property (nonatomic, assign) BOOL tunnelRunning;
@end

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    NSDictionary *config = (NSDictionary *)self.protocolConfiguration.providerConfiguration;
    NSString *server = config[@"server"] ?: @"106.54.179.198";
    NSNumber *port = config[@"port"] ?: @8888;

    NSLog(@"[QNET] Starting tunnel, server: %@:%@", server, port);

    // 配置隧道网络
    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"10.8.0.1"];

    NEIPv4Settings *ipv4 = [[NEIPv4Settings alloc] initWithAddresses:@[@"10.8.0.2"] subnetMasks:@[@"255.255.255.0"]];
    NEIPv4Route *route = [[NEIPv4Route alloc] initWithDestinationAddress:@"0.0.0.0" subnetMask:@"0.0.0.0"];
    ipv4.includedRoutes = @[route];
    NEDNSSettings *dns = [[NEDNSSettings alloc] initWithServers:@[@"8.8.8.8", @"114.114.114.114"]];
    settings.IPv4Settings = ipv4;
    settings.DNSSettings = dns;

    self.tunnelRunning = YES;
    [AppGroup setVPNRunning:YES];

    [self setTunnelNetworkSettings:settings completionHandler:^(NSError *err) {
        if (err) {
            NSLog(@"[QNET] Tunnel settings failed: %@", err);
            completionHandler(err);
            return;
        }
        NSLog(@"[QNET] Tunnel settings OK, starting packet relay");
        [self startPacketRelay];
        completionHandler(nil);
    }];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    NSLog(@"[QNET] Stopping tunnel, reason: %ld", (long)reason);
    self.tunnelRunning = NO;
    [AppGroup setVPNRunning:NO];
    if (self.serverSocket >= 0) { close(self.serverSocket); self.serverSocket = -1; }
    completionHandler();
}

- (void)startPacketRelay {
    [self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> *packets, NSArray<NSNumber *> *protocols) {
        if (!self.tunnelRunning) return;

        // 简单透传：读到的包直接写回去（验证VPN隧道建立）
        if (packets.count > 0) {
            [self.packetFlow writePackets:packets withProtocols:protocols];
        }

        // 持续读取
        [self startPacketRelay];
    }];
}

@end
