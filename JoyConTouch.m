#import <UIKit/UIKit.h>
#import <GameController/GameController.h>
#import <objc/message.h>
#import "PTFakeMetaTouch.h"

static NSInteger jcRightTouch = 0;
static NSInteger jcLeftTouch = 0;
static BOOL jcReady = NO;

static UIWindow *JCWindow(void) {
    UIWindow *w = UIApplication.sharedApplication.keyWindow;
    if (!w) {
        for (UIWindow *candidate in UIApplication.sharedApplication.windows) {
            if (!candidate.hidden && candidate.windowLevel == UIWindowLevelNormal) {
                w = candidate;
                break;
            }
        }
    }
    return w;
}

static CGPoint JCP(CGFloat x, CGFloat y) {
    UIWindow *w = JCWindow();
    if (!w) return CGPointZero;
    return CGPointMake(w.bounds.size.width * x, w.bounds.size.height * y);
}

static void JCTap(CGFloat x, CGFloat y) {
    if (!jcReady) return;
    CGPoint p = JCP(x, y);
    NSInteger id = [PTFakeMetaTouch getAvailablePointId];
    if (!id) return;
    id = [PTFakeMetaTouch fakeTouchId:id AtPoint:p withTouchPhase:UITouchPhaseBegan];
    [PTFakeMetaTouch fakeTouchId:id AtPoint:p withTouchPhase:UITouchPhaseEnded];
}

static void JCStartRight(void) {
    if (jcRightTouch || !jcReady) return;
    CGPoint p = JCP(0.70, 0.50);
    jcRightTouch = [PTFakeMetaTouch fakeTouchId:0 AtPoint:p withTouchPhase:UITouchPhaseBegan];
}

static void JCMoveRight(float dx, float dy) {
    if (!jcRightTouch || !jcReady) return;
    CGPoint p = JCP(0.70 + dx * 0.22, 0.50 - dy * 0.22);
    p.x = MAX(1, MIN(JCWindow().bounds.size.width - 1, p.x));
    p.y = MAX(1, MIN(JCWindow().bounds.size.height - 1, p.y));
    [PTFakeMetaTouch fakeTouchId:jcRightTouch AtPoint:p withTouchPhase:UITouchPhaseMoved];
}

static void JCEndRight(void) {
    if (!jcRightTouch) return;
    CGPoint p = JCP(0.70, 0.50);
    [PTFakeMetaTouch fakeTouchId:jcRightTouch AtPoint:p withTouchPhase:UITouchPhaseEnded];
    jcRightTouch = 0;
}

@interface JoyConTouch : NSObject
@property(nonatomic,strong) NSMutableSet *controllers;
@end

@implementation JoyConTouch

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        JoyConTouch *x = [JoyConTouch new];
        [x start];
    });
}

- (void)start {
    self.controllers = [NSMutableSet set];
    jcReady = YES;

    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    [nc addObserver:self selector:@selector(connected:) name:GCControllerDidConnectNotification object:nil];
    [nc addObserver:self selector:@selector(disconnected:) name:GCControllerDidDisconnectNotification object:nil];

    for (GCController *c in GCController.controllers) {
        [self setup:c];
    }

    NSLog(@"[JoyConTouch] loaded");
}

- (void)connected:(NSNotification *)n {
    [self setup:(GCController *)n.object];
}

- (void)disconnected:(NSNotification *)n {
    GCController *c = (GCController *)n.object;
    [self.controllers removeObject:c];
    JCEndRight();
}

- (void)setup:(GCController *)c {
    if (!c) return;
    [self.controllers addObject:c];

    GCExtendedGamepad *p = c.extendedGamepad;
    if (!p) {
        NSLog(@"[JoyConTouch] controller %@ has no extendedGamepad", c.vendorName);
        return;
    }

    __weak JoyConTouch *weakSelf = self;

    p.buttonA.pressedChangedHandler = ^(GCControllerButtonInput *b, float v, BOOL pressed) {
        if (pressed) JCTap(0.90, 0.86);
    };
    p.buttonB.pressedChangedHandler = ^(GCControllerButtonInput *b, float v, BOOL pressed) {
        if (pressed) JCTap(0.78, 0.86);
    };
    p.buttonX.pressedChangedHandler = ^(GCControllerButtonInput *b, float v, BOOL pressed) {
        if (pressed) JCTap(0.82, 0.70);
    };
    p.buttonY.pressedChangedHandler = ^(GCControllerButtonInput *b, float v, BOOL pressed) {
        if (pressed) JCTap(0.92, 0.70);
    };
    p.leftTrigger.pressedChangedHandler = ^(GCControllerButtonInput *b, float v, BOOL pressed) {
        if (pressed) JCTap(0.82, 0.56);
    };
    p.rightTrigger.pressedChangedHandler = ^(GCControllerButtonInput *b, float v, BOOL pressed) {
        if (pressed) JCTap(0.92, 0.56);
    };

    p.rightThumbstick.valueChangedHandler = ^(GCControllerDirectionPad *s, float x, float y) {
        BOOL active = (fabsf(x) > 0.12f || fabsf(y) > 0.12f);
        if (active) {
            if (!jcRightTouch) JCStartRight();
            JCMoveRight(x, y);
        } else {
            JCEndRight();
        }
    };

    p.leftThumbstick.valueChangedHandler = ^(GCControllerDirectionPad *s, float x, float y) {
        // CounterFlame's movement joystick position varies by HUD layout.
        // Log it for the first calibration pass.
        static int n = 0;
        if ((++n % 20) == 0) NSLog(@"[JoyConTouch] LEFT %.2f %.2f", x, y);
    };

    NSLog(@"[JoyConTouch] attached to %@", c.vendorName);
}

@end
