#import "ViewController.h"
#import "VPNManager.h"
#import "AppGroup.h"

@interface ViewController ()
@property (nonatomic, strong) UISwitch *vpnSwitch;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UILabel *serverLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    [self setupUI];
    [self restoreState];
}

#pragma mark - UI

- (void)setupUI {
    CGFloat w = self.view.bounds.size.width;
    CGFloat top = 100;

    // 标题
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, top, w, 36)];
    title.text = @"QNET VPN";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:28];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];

    // 开关
    self.vpnSwitch = [[UISwitch alloc] init];
    self.vpnSwitch.center = CGPointMake(w / 2, top + 80);
    self.vpnSwitch.onTintColor = [UIColor systemGreenColor];
    self.vpnSwitch.transform = CGAffineTransformMakeScale(1.5, 1.5);
    [self.vpnSwitch addTarget:self action:@selector(toggleVPN:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.vpnSwitch];

    // 加载圈
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.center = CGPointMake(w / 2, top + 140);
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];

    // 状态
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, top + 170, w, 28)];
    self.statusLabel.text = @"未连接";
    self.statusLabel.textColor = [UIColor systemGrayColor];
    self.statusLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    // 详情
    self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, top + 200, w, 22)];
    self.detailLabel.text = @"等待连接...";
    self.detailLabel.textColor = [UIColor systemGray2Color];
    self.detailLabel.font = [UIFont systemFontOfSize:14];
    self.detailLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.detailLabel];

    // 服务器
    self.serverLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, top + 240, w, 20)];
    self.serverLabel.text = @"服务器: 106.54.179.198";
    self.serverLabel.textColor = [UIColor systemGray3Color];
    self.serverLabel.font = [UIFont systemFontOfSize:12];
    self.serverLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.serverLabel];
}

- (void)restoreState {
    [[VPNManager shared] checkStatus:^(BOOL connected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.vpnSwitch.on = connected;
            [self updateUI:connected connecting:NO];
        });
    }];
}

- (void)toggleVPN:(UISwitch *)sender {
    sender.enabled = NO;
    [self.spinner startAnimating];
    [self updateUI:sender.on connecting:YES];

    if (sender.on) {
        [[VPNManager shared] connect:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                sender.enabled = YES;
                [self.spinner stopAnimating];
                BOOL ok = (error == nil);
                self.vpnSwitch.on = ok;
                [self updateUI:ok connecting:NO];
                [AppGroup setVPNRunning:ok];
                if (error) {
                    self.detailLabel.text = [NSString stringWithFormat:@"错误: %@", error.localizedDescription];
                }
            });
        }];
    } else {
        [[VPNManager shared] disconnect];
        [AppGroup setVPNRunning:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            sender.enabled = YES;
            [self.spinner stopAnimating];
            [self updateUI:NO connecting:NO];
        });
    }
}

- (void)updateUI:(BOOL)connected connecting:(BOOL)connecting {
    if (connecting) {
        self.statusLabel.text = @"连接中...";
        self.statusLabel.textColor = [UIColor systemOrangeColor];
        self.detailLabel.text = @"正在建立VPN隧道";
    } else if (connected) {
        self.statusLabel.text = @"弱网运行中";
        self.statusLabel.textColor = [UIColor systemGreenColor];
        self.detailLabel.text = @"模拟延迟 200ms / 丢包 5%";
    } else {
        self.statusLabel.text = @"未连接";
        self.statusLabel.textColor = [UIColor systemGrayColor];
        self.detailLabel.text = @"等待连接...";
    }
}

@end
