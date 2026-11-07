#import "UpdateChecker.h"

static NSString *const kAutoCheckUpdatesKey = @"WTTBAutomaticallyCheckUpdates";
// Public client token: repository-scoped, read-only, deliberately distributed with this app.
// Treat it as non-secret, never upgrade its permissions or reuse it for CI writes.
static NSString *const kCNBReadToken = @"aQxLyJUxPFG3969RLP7fj3HHbYF";
static NSString *const kReleaseAPI = @"https://api.cnb.cool/SDCOM/WeTypeTouchBarBridge/-/releases/latest";
static NSString *const kReleasePagePrefix = @"https://cnb.cool/SDCOM/WeTypeTouchBarBridge/-/releases/tag/";

@interface UpdateChecker ()
@property(nonatomic,strong) NSMenuItem *autoUpdateItem;
@property(nonatomic,strong) NSTimer *updateTimer;
@property(nonatomic,assign) BOOL automaticUpdateChecks;
@property(nonatomic,assign) BOOL updateRequestInFlight;
@property(nonatomic,strong) NSString *lastNotifiedRelease;
@end

@implementation UpdateChecker

- (void)addItemsToMenu:(NSMenu *)menu {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    self.automaticUpdateChecks = [defaults objectForKey:kAutoCheckUpdatesKey] ?
        [defaults boolForKey:kAutoCheckUpdatesKey] : YES;
    self.autoUpdateItem = [[NSMenuItem alloc] initWithTitle:@"自动检查更新（每 6 小时）"
                                                     action:@selector(toggleAutomaticUpdateChecks:)
                                              keyEquivalent:@""];
    self.autoUpdateItem.target = self;
    self.autoUpdateItem.state = self.automaticUpdateChecks ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:self.autoUpdateItem];
    NSMenuItem *checkNow = [[NSMenuItem alloc] initWithTitle:@"立即检查更新"
                                                      action:@selector(checkForUpdatesNow:)
                                               keyEquivalent:@""];
    checkNow.target = self;
    [menu addItem:checkNow];
}

- (void)start {
    // Every launch checks once; the preference only controls subsequent checks.
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:6.0 * 60.0 * 60.0
                                                       target:self
                                                     selector:@selector(periodicUpdateCheck:)
                                                     userInfo:nil
                                                      repeats:YES];
    [self checkForUpdatesInformUserOnError:NO];
}

- (void)showInfo:(NSString *)title text:(NSString *)text {
    NSAlert *alert = [NSAlert new];
    alert.messageText = title;
    alert.informativeText = text;
    [alert addButtonWithTitle:@"知道了"];
    [alert runModal];
}

// Compare numeric release versions, not lexicographic text (1.10 > 1.9).
static NSArray<NSNumber *> *releaseVersionComponents(NSString *value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *raw = [value hasPrefix:@"v"] ? [value substringFromIndex:1] : value;
    NSArray<NSString *> *parts = [raw componentsSeparatedByString:@"."];
    if (parts.count < 2 || parts.count > 3) return nil;
    NSMutableArray<NSNumber *> *numbers = [NSMutableArray arrayWithCapacity:3];
    NSCharacterSet *nonDigits = [NSCharacterSet.decimalDigitCharacterSet invertedSet];
    for (NSString *part in parts) {
        if (part.length == 0 || [part rangeOfCharacterFromSet:nonDigits].location != NSNotFound) return nil;
        [numbers addObject:@(part.integerValue)];
    }
    while (numbers.count < 3) [numbers addObject:@0];
    return numbers;
}

static BOOL isNewerRelease(NSString *remote, NSString *installed) {
    NSArray<NSNumber *> *a = releaseVersionComponents(remote);
    NSArray<NSNumber *> *b = releaseVersionComponents(installed);
    if (!a || !b) return NO;
    for (NSUInteger i = 0; i < 3; i++) {
        if (a[i].integerValue > b[i].integerValue) return YES;
        if (a[i].integerValue < b[i].integerValue) return NO;
    }
    return NO;
}

- (void)toggleAutomaticUpdateChecks:(id)sender {
    (void)sender;
    self.automaticUpdateChecks = !self.automaticUpdateChecks;
    self.autoUpdateItem.state = self.automaticUpdateChecks ? NSControlStateValueOn : NSControlStateValueOff;
    [NSUserDefaults.standardUserDefaults setBool:self.automaticUpdateChecks forKey:kAutoCheckUpdatesKey];
}
- (void)periodicUpdateCheck:(NSTimer *)timer {
    (void)timer;
    if (self.automaticUpdateChecks) [self checkForUpdatesInformUserOnError:NO];
}
- (void)checkForUpdatesNow:(id)sender {
    (void)sender;
    [self checkForUpdatesInformUserOnError:YES];
}
- (void)checkForUpdatesInformUserOnError:(BOOL)interactive {
    if (self.updateRequestInFlight) return;
    self.updateRequestInFlight = YES;
    NSURL *url = [NSURL URLWithString:kReleaseAPI];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 12;
    [request setValue:@"application/vnd.cnb.api+json" forHTTPHeaderField:@"Accept"];
    [request setValue:[@"Bearer " stringByAppendingString:kCNBReadToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"image/svg+xml" forHTTPHeaderField:@"Accept"];
    [request setValue:@"WeTypeTouchBarBridge-update-check" forHTTPHeaderField:@"User-Agent"];
    __weak UpdateChecker *weakSelf = self;
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ?
                (NSHTTPURLResponse *)response : nil;
            // CNB OpenAPI requires authentication even for a public repository.
            // Its official public Release badge is anonymous and contains the
            // Latest version (or the most recently created Release).
            NSString *tag = nil;
            if (!error && http.statusCode == 200 && data.length > 0 && data.length < 131072) {
                id result = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                if ([result isKindOfClass:NSDictionary.class]) {
                    id value = ((NSDictionary *)result)[@"tag_name"];
                    if ([value isKindOfClass:NSString.class] && releaseVersionComponents(value))
                        tag = value;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                UpdateChecker *strongSelf = weakSelf;
                if (!strongSelf) return;
                strongSelf.updateRequestInFlight = NO;
                NSString *link = tag ? [kReleasePagePrefix stringByAppendingString:tag] : nil;
                NSString *installed = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                if (tag && link &&
                    isNewerRelease(tag, installed)) {
                    // Avoid repeatedly opening the same modal alert within one application session.
                    if (![tag isEqualToString:strongSelf.lastNotifiedRelease]) {
                        strongSelf.lastNotifiedRelease = tag;
                        NSAlert *alert = [NSAlert new];
                        alert.messageText = @"发现新版本";
                        alert.informativeText = [NSString stringWithFormat:
                            @"当前版本：%@\n最新版本：%@\n\n是否打开 CNB Releases 下载？", installed ?: @"未知", tag];
                        [alert addButtonWithTitle:@"前往下载"];
                        [alert addButtonWithTitle:@"稍后"];
                        if ([alert runModal] == NSAlertFirstButtonReturn)
                            [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:link]];
                    }
                } else if (interactive) {
                    if (error || http.statusCode != 200 || !tag || !installed) {
                        [strongSelf showInfo:@"检查更新失败" text:
                            @"无法从 CNB Release API 获取版本信息，请检查网络或令牌状态后重试。"];
                    } else {
                        [strongSelf showInfo:@"已经是最新版本" text:
                            [NSString stringWithFormat:@"当前版本：%@", installed]];
                    }
                }
            });
        }];
    [task resume];
}

@end
