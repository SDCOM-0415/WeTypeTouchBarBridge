#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <objc/message.h>
#import <dlfcn.h>

// Colors sampled approximately from the user-provided native Chinese candidate bar screenshot.
// The first candidate is highlighted while other candidates share a continuous dark surface.
static NSColor *candidateColor(BOOL first) {
    return [NSColor colorWithCalibratedRed:(first ? 0.225 : 0.143)
                                     green:(first ? 0.303 : 0.202)
                                      blue:(first ? 0.370 : 0.251)
                                     alpha:1.0];
}

@interface CandidateItemView : NSScrubberTextItemView
- (void)applyCandidateAppearanceAtIndex:(NSInteger)index;
@end
@implementation CandidateItemView
- (void)applyCandidateAppearanceAtIndex:(NSInteger)index {
    self.wantsLayer = YES;
    self.layer.backgroundColor = candidateColor(index == 0).CGColor;
    self.layer.cornerRadius = 0.0;
    self.layer.masksToBounds = YES;
}
@end

static NSString *const kWeTypeBundle = @"com.tencent.inputmethod.wetype";
static NSString *const kTrayIdentifier = @"org.example.wetype-touchbar.tray";
static NSString *const kCandidatesIdentifier = @"org.example.wetype-touchbar.candidates";

@interface Bridge : NSObject <NSApplicationDelegate, NSTouchBarDelegate, NSScrubberDataSource, NSScrubberFlowLayoutDelegate>
@property(nonatomic,strong) NSTouchBar *bar;
@property(nonatomic,strong) NSTouchBar *testBar;
@property(nonatomic,strong) NSMenuItem *diagnostic;
@property(nonatomic,assign) BOOL testing;
@property(nonatomic,assign) BOOL hasModalAPI;
@property(nonatomic,assign) BOOL trayRegistered;
@property(nonatomic,strong) NSScrubber *scrubber;
@property(nonatomic,strong) NSFont *candidateFont;
@property(nonatomic,assign) NSUInteger sampleCount;
@property(nonatomic,assign) double sumAXms;
@property(nonatomic,assign) double maxAXms;
@property(nonatomic,assign) NSTimeInterval lastLogTime;
@property(nonatomic,assign) NSUInteger pollSerial;
@property(nonatomic,strong) dispatch_source_t pollSource;
@property(nonatomic,assign) NSTimeInterval lastCandidateUpdate;
@property(nonatomic,strong) NSStatusItem *status;
@property(nonatomic,strong) NSArray<NSString *> *currentWords;
@property(nonatomic,strong) NSArray<NSNumber *> *currentKeys;
@property(nonatomic,assign) BOOL presented;
@property(nonatomic,assign) BOOL enabled;
@property(nonatomic,assign) pid_t lastPID;
@end

@implementation Bridge

static id AXValueFor(AXUIElementRef element, CFStringRef key) {
    CFTypeRef value = NULL;
    AXError error = AXUIElementCopyAttributeValue(element, key, &value);
    if (error != kAXErrorSuccess || value == NULL) return nil;
    return CFBridgingRelease(value);
}

static void walk(AXUIElementRef element, NSMutableArray<NSString *> *values, NSUInteger depth) {
    if (depth > 5 || values.count > 100) return;
    NSString *role = AXValueFor(element, kAXRoleAttribute);
    if ([role isEqualToString:(__bridge NSString *)kAXStaticTextRole]) {
        id text = AXValueFor(element, kAXValueAttribute);
        if ([text isKindOfClass:NSString.class] && [text length] > 0) [values addObject:text];
    }
    NSArray *children = AXValueFor(element, kAXChildrenAttribute);
    if (![children isKindOfClass:NSArray.class]) return;
    NSUInteger bound = MIN(children.count, 60);
    for (NSUInteger i = 0; i < bound; i++) {
        AXUIElementRef child = (__bridge AXUIElementRef)children[i];
        if (CFGetTypeID(child) == AXUIElementGetTypeID()) walk(child, values, depth+1);
    }
}

static pid_t wetypePID(void) {
    NSArray<NSRunningApplication *> *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:kWeTypeBundle];
    for (NSRunningApplication *app in apps) if (!app.isTerminated) return app.processIdentifier;
    return 0;
}

static BOOL isDigitLabel(NSString *s, NSInteger *out) {
    if (s.length != 1) return NO;
    unichar c = [s characterAtIndex:0];
    if (c >= '0' && c <= '9') { if (out) *out = c-'0'; return YES; }
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    self.enabled = YES;
    self.currentWords = @[];
    self.currentKeys = @[];
    self.status = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.status.button.title = @"候6";
    NSMenu *menu = [NSMenu new];
    NSMenuItem *toggle = [[NSMenuItem alloc] initWithTitle:@"暂停读取候选词" action:@selector(toggle:) keyEquivalent:@""];
    toggle.target = self;
    [menu addItem:toggle];
    NSMenuItem *test = [[NSMenuItem alloc] initWithTitle:@"强制测试 Touch Bar（显示测试按钮）" action:@selector(testTouchBar:) keyEquivalent:@""];
    test.target = self;
    [menu addItem:test];
    self.diagnostic = [[NSMenuItem alloc] initWithTitle:@"状态：等待候选词" action:nil keyEquivalent:@""];
    self.diagnostic.enabled = NO;
    [menu addItem:self.diagnostic];
    [menu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出" action:@selector(quit:) keyEquivalent:@""];
    quit.target = self;
    [menu addItem:quit];
    self.status.menu = menu;
    self.lastLogTime = NSProcessInfo.processInfo.systemUptime;
    NSLog(@"[Perf] v0.6 started; use log stream to view [Perf] lines");

    self.candidateFont = [NSFont systemFontOfSize:15 weight:NSFontWeightRegular];
    self.scrubber = [[NSScrubber alloc] initWithFrame:NSMakeRect(0, 0, 560, 36)];
    self.scrubber.wantsLayer = YES;
    self.scrubber.layer.backgroundColor = candidateColor(NO).CGColor;
    self.scrubber.layer.cornerRadius = 9.0;
    self.scrubber.layer.masksToBounds = YES;
    self.scrubber.scrubberLayout = [NSScrubberFlowLayout new];
    self.scrubber.dataSource = self;
    self.scrubber.delegate = self;
    self.scrubber.mode = NSScrubberModeFixed;
    self.scrubber.continuous = NO;
    [self.scrubber registerClass:CandidateItemView.class forItemIdentifier:@"candidateCell"];
    NSCustomTouchBarItem *candidateControl = [[NSCustomTouchBarItem alloc] initWithIdentifier:kCandidatesIdentifier];
    candidateControl.view = self.scrubber;
    self.bar = [NSTouchBar new];
    self.bar.defaultItemIdentifiers = @[kCandidatesIdentifier];
    self.bar.templateItems = [NSSet setWithObject:candidateControl];
    self.testBar = [NSTouchBar new];
    NSCustomTouchBarItem *testItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:@"org.example.wetype-touchbar.test"];
    testItem.view = [NSButton buttonWithTitle:@"WeType Bridge: Touch Bar OK" target:self action:@selector(stopTest:)];
    self.testBar.templateItems = [NSSet setWithObject:testItem];
    self.testBar.defaultItemIdentifiers = @[testItem.identifier];
    self.hasModalAPI = [NSTouchBar respondsToSelector:NSSelectorFromString(@"presentSystemModalTouchBar:systemTrayItemIdentifier:")];
    NSLog(@"[Bridge] modal API=%d, AX trusted=%d", self.hasModalAPI, AXIsProcessTrusted());

    // Only attempt system-wide Touch Bar API when the implementation exists.
    void *dfr = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_LAZY);
    if (dfr) {
        void (*showClose)(BOOL) = dlsym(dfr, "DFRSystemModalShowsCloseBoxWhenFrontMost");
        void (*setTrayPresence)(CFStringRef, BOOL) = dlsym(dfr, "DFRElementSetControlStripPresenceForIdentifier");
        if (showClose) showClose(YES);
        SEL add = NSSelectorFromString(@"addSystemTrayItem:");
        if ([NSTouchBarItem respondsToSelector:add] && setTrayPresence) {
            NSCustomTouchBarItem *tray = [[NSCustomTouchBarItem alloc] initWithIdentifier:kTrayIdentifier];
            tray.view = [NSButton buttonWithTitle:@"候" target:self action:@selector(toggleFromBar:)];
            ((void (*)(id, SEL, id))objc_msgSend)(NSTouchBarItem.class, add, tray);
            setTrayPresence((__bridge CFStringRef)kTrayIdentifier, YES);
            self.trayRegistered = YES;
            NSLog(@"[Bridge] control strip tray registered");
        }
        // Keep library mapped while the process runs.
    }
    if (!AXIsProcessTrusted()) {
        NSDictionary *options = @{(__bridge NSString *)kAXTrustedCheckOptionPrompt: @YES};
        AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
        [self showInfo:@"需要授权辅助功能" text:@"请在 系统设置 → 隐私与安全性 → 辅助功能 中允许本程序，然后重新启动。程序只读取微信输入法的候选窗口，不保存输入内容。"];
    }
    // Accessibility queries may block. Never perform them on AppKit's main thread.
    dispatch_queue_t queue = dispatch_queue_create("org.example.wetypebridge.axpoll", DISPATCH_QUEUE_SERIAL);
    self.pollSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.pollSource, dispatch_time(DISPATCH_TIME_NOW, 0),
                              100 * NSEC_PER_MSEC, 20 * NSEC_PER_MSEC);
    __weak Bridge *weakSelf = self;
    dispatch_source_set_event_handler(self.pollSource, ^{
        Bridge *strongSelf = weakSelf;
        if (strongSelf) [strongSelf pollCandidatesOnBackgroundQueue];
    });
    dispatch_resume(self.pollSource);
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
    (void)touchBar;
    if ([identifier isEqualToString:kCandidatesIdentifier]) return [self.bar.templateItems anyObject];
    return nil;
}

- (void)updateDiagnosticMessage:(NSString *)message {
    self.diagnostic.title = [@"状态：" stringByAppendingString:message];
}
- (void)stopTest:(id)sender {
    (void)sender;
    [self dismissBar];
    self.testing = NO;
    if (self.currentWords.count) [self presentBar];
}
- (void)testTouchBar:(id)sender {
    (void)sender;
    [self dismissBar];
    self.testing = YES;
    [self presentBar];
    [self updateDiagnosticMessage:self.hasModalAPI ? @"已请求测试栏；查看 Touch Bar" : @"系统无 modal API"]; 
}
- (void)toggleFromBar:(id)sender { (void)sender; if (self.presented) [self dismissBar]; else if (self.currentWords.count) [self presentBar]; }
- (void)toggle:(id)sender {
    (void)sender;
    self.enabled = !self.enabled;
    NSMenuItem *toggle = self.status.menu.itemArray.firstObject;
    toggle.title = self.enabled ? @"暂停读取候选词" : @"继续读取候选词";
    if (!self.enabled) [self updateWithWords:@[] keys:@[]];
}
- (void)quit:(id)sender { (void)sender; [self dismissBar]; [NSApp terminate:nil]; }
- (void)showInfo:(NSString *)title text:(NSString *)text {
    NSAlert *alert = [NSAlert new];
    alert.messageText = title;
    alert.informativeText = text;
    [alert addButtonWithTitle:@"知道了"];
    [alert runModal];
}

- (void)pollCandidatesOnBackgroundQueue {
    if (!self.enabled) return;
    if (!AXIsProcessTrusted()) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self updateDiagnosticMessage:@"缺少辅助功能授权"]; });
        return;
    }
    const NSTimeInterval t0 = NSProcessInfo.processInfo.systemUptime;
    pid_t pid = wetypePID();
    if (pid == 0) { dispatch_async(dispatch_get_main_queue(), ^{ [self updateDiagnosticMessage:@"未找到 WeType 进程"]; [self updateWithWords:@[] keys:@[]]; }); return; }
    AXUIElementRef app = AXUIElementCreateApplication(pid);
    AXUIElementSetMessagingTimeout(app, 0.30);
    NSArray *windows = AXValueFor(app, kAXWindowsAttribute);
    NSMutableArray<NSString *> *raw = [NSMutableArray new];
    if ([windows isKindOfClass:NSArray.class]) {
        for (id obj in [windows subarrayWithRange:NSMakeRange(0, MIN(windows.count, 4))]) {
            AXUIElementRef window = (__bridge AXUIElementRef)obj;
            if (CFGetTypeID(window) == AXUIElementGetTypeID()) walk(window, raw, 0);
        }
    }
    CFRelease(app);

    // Require sequential numbered candidates to avoid mistaking settings windows for input.
    NSMutableArray<NSString *> *words = [NSMutableArray new];
    NSMutableArray<NSNumber *> *keys = [NSMutableArray new];
    for (NSUInteger i=0; i+1 < raw.count; i++) {
        NSInteger digit = 0;
        if (!isDigitLabel(raw[i], &digit) || digit < 1 || digit > 9) continue;
        NSString *word = raw[i+1];
        NSInteger nextDigit = 0;
        if (isDigitLabel(word, &nextDigit) || word.length == 0) continue;
        if (keys.count && digit <= keys.lastObject.integerValue) continue;
        [words addObject:word];
        [keys addObject:@(digit)];
        i++;
    }
    if (keys.count == 0 || keys.firstObject.integerValue != 1) {
        [words removeAllObjects];
        [keys removeAllObjects];
    }
    const NSTimeInterval t1 = NSProcessInfo.processInfo.systemUptime;
    double axms = (t1 - t0) * 1000.0;
    NSArray<NSString *> *snapshotWords = [words copy];
    NSArray<NSNumber *> *snapshotKeys = [keys copy];
    dispatch_async(dispatch_get_main_queue(), ^{
        const NSTimeInterval t2 = NSProcessInfo.processInfo.systemUptime;
        double queuems = (t2 - t1) * 1000.0;
        self.lastCandidateUpdate = [NSDate timeIntervalSinceReferenceDate];
        BOOL changed = ![self.currentWords isEqualToArray:snapshotWords] || ![self.currentKeys isEqualToArray:snapshotKeys];
        if (changed) {
            [self updateDiagnosticMessage:[NSString stringWithFormat:@"v0.6 · %lu 候选 · AX %.1fms",(unsigned long)snapshotWords.count,axms]];
        }
        const NSTimeInterval uiStart = NSProcessInfo.processInfo.systemUptime;
        [self updateWithWords:snapshotWords keys:snapshotKeys];
        double uims = (NSProcessInfo.processInfo.systemUptime - uiStart) * 1000.0;
        self.sampleCount++;
        self.sumAXms += axms;
        self.maxAXms = MAX(self.maxAXms, axms);
        if (changed) NSLog(@"[Perf] CHANGE count=%lu AX=%.2fms queue=%.2fms UI=%.2fms",(unsigned long)snapshotWords.count,axms,queuems,uims);
        NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
        if (now - self.lastLogTime > 10.0 && self.sampleCount) {
            NSLog(@"[Perf] 10s samples=%lu AX-mean=%.2fms AX-max=%.2fms",(unsigned long)self.sampleCount,self.sumAXms/self.sampleCount,self.maxAXms);
            self.sampleCount = 0; self.sumAXms = 0; self.maxAXms = 0; self.lastLogTime = now;
        }
    });
}

- (void)updateWithWords:(NSArray<NSString *> *)words keys:(NSArray<NSNumber *> *)keys {
    if ([self.currentWords isEqualToArray:words] && [self.currentKeys isEqualToArray:keys]) return;
    self.currentWords = [words copy]; self.currentKeys = [keys copy];
    if (words.count == 0) { if (!self.testing) [self dismissBar]; return; }
    [self.scrubber reloadData];
    [self.scrubber.scrubberLayout invalidateLayout];
    if (!self.testing) [self presentBar];
}

- (void)presentBar {
    if (self.presented) return;
    // Private API used only for presenting the native candidate bar system-wide.
    SEL selector = NSSelectorFromString(@"presentSystemModalTouchBar:systemTrayItemIdentifier:");
    Class cls = NSTouchBar.class;
    if (![cls respondsToSelector:selector]) {
        NSLog(@"[Bridge] missing private modal selector");
        [self updateDiagnosticMessage:@"无系统 modal 接口"]; 
        self.status.button.title = @"候!";
        return;
    }
    typedef void (*Message)(id, SEL, id, id);
    NSTouchBar *chosen = self.testing ? self.testBar : self.bar;
    NSLog(@"[Bridge] presenting %@; tray=%d",self.testing?@"test":@"candidate",self.trayRegistered);
    ((Message)objc_msgSend)(cls, selector, chosen, self.trayRegistered ? kTrayIdentifier : nil);
    self.presented = YES;
}
- (void)dismissBar {
    if (!self.presented) return;
    SEL selector = NSSelectorFromString(@"dismissSystemModalTouchBar:");
    Class cls = NSTouchBar.class;
    if ([cls respondsToSelector:selector]) {
        typedef void (*Message)(id, SEL, id);
        ((Message)objc_msgSend)(cls, selector, self.testing ? self.testBar : self.bar);
    }
    self.presented = NO;
}

// Variable-width candidates, using glyph measurement (not character count).
- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber {
    (void)scrubber;
    return (NSInteger)self.currentWords.count;
}
- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index {
    CandidateItemView *view = [scrubber makeItemWithIdentifier:@"candidateCell" owner:self];
    if (index >= 0 && index < (NSInteger)self.currentWords.count) {
        view.title = self.currentWords[index];
        // NSScrubber recycles its cells: style every time a cell is configured.
        [view applyCandidateAppearanceAtIndex:index];
    }
    return view;
}
- (NSSize)scrubber:(NSScrubber *)scrubber layout:(NSScrubberFlowLayout *)layout sizeForItemAtIndex:(NSInteger)index {
    (void)scrubber; (void)layout;
    if (index < 0 || index >= (NSInteger)self.currentWords.count) return NSMakeSize(44,36);
    NSString *word = self.currentWords[index];
    CGFloat glyphWidth = [word sizeWithAttributes:@{NSFontAttributeName:self.candidateFont}].width;
    // minimum hit target, horizontal breathing room; long phrases cap to allow scrolling.
    return NSMakeSize(MIN(270.0, MAX(44.0, ceil(glyphWidth) + 26.0)), 36);
}
- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)index {
    (void)scrubber;
    if (index < 0 || index >= (NSInteger)self.currentKeys.count || !AXIsProcessTrusted()) return;
    if ([NSDate timeIntervalSinceReferenceDate] - self.lastCandidateUpdate > 0.8) return;
    TISInputSourceRef source = TISCopyCurrentKeyboardInputSource();
    NSString *sourceID = source ? [(__bridge NSString *)TISGetInputSourceProperty(source, kTISPropertyInputSourceID) copy] : nil;
    if (source) CFRelease(source);
    if (![sourceID isEqualToString:@"com.tencent.inputmethod.wetype.pinyin"]) return;
    int digit = self.currentKeys[index].intValue;
    if (digit < 1 || digit > 9) return;
    const CGKeyCode keycodes[] = {0,18,19,20,21,23,22,26,28,25};
    CGKeyCode key = keycodes[digit];
    CGEventRef down = CGEventCreateKeyboardEvent(NULL, key, true);
    CGEventRef up = CGEventCreateKeyboardEvent(NULL, key, false);
    if (down && up) {
        CGEventPost(kCGHIDEventTap, down);
        CGEventPost(kCGHIDEventTap, up);
    }
    if (down) CFRelease(down);
    if (up) CFRelease(up);
}
@end

int main(int argc, const char *argv[]) {
    (void)argc; (void)argv;
    @autoreleasepool {
        [NSApplication sharedApplication];
        Bridge *delegate = [Bridge new];
        NSApp.delegate = delegate;
        [NSApp run];
    }
    return 0;
}
