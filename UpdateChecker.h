#import <Cocoa/Cocoa.h>

// Owns update preferences, scheduled checks, GitHub Releases requests, and alerts.
// Public interface stays independent from the Touch Bar/AX bridge.
@interface UpdateChecker : NSObject
- (void)addItemsToMenu:(NSMenu *)menu;
- (void)start;
@end
