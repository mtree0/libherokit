#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>
#import <IOSurface/IOSurface.h>

@class SBApplication;
@class SBProcess;

@interface UIApplication (liherokit)
- (void)_rebootNow;
- (void)_powerDownNow;
- (void)_relaunchSpringBoardNow;
@end

@interface UIWindow (libherokit)
+ (UIWindow *)keyWindow;
+ (IOSurfaceRef)createScreenIOSurface;
@end

@interface UIImage (libherokit)
- (id)_initWithIOSurface:(IOSurfaceRef)surface scale:(CGFloat)scale orientation:(int)orientation;
@end

@interface SpringBoard : UIApplication
- (void)setBackgroundingEnabled:(BOOL)enabled forDisplayIdentifier:(NSString *)displayID;
@end

@interface SBHUDView : UIView
@property(retain, nonatomic) UIImage *image;
@property(retain, nonatomic) NSString *subtitle;
@property(retain, nonatomic) NSString *title;
- (id)initWithHUDViewLevel:(int)level;
@end

@interface SBHUDController
+ (id)sharedHUDController;
- (void)presentHUDView:(SBHUDView *)hud autoDismissWithDelay:(NSTimeInterval)delay;
@end

@interface SBUIController
+ (id)sharedInstance;
- (void)activateApplicationFromSwitcher:(SBApplication *)app;
- (void)lockFromSource:(int)source;
- (void)_toggleSwitcher; // iOS 5
- (BOOL)isSwitcherShowing; // iOS 6
- (BOOL)activateSwitcher; // iOS 6
- (void)dismissSwitcherAnimated:(BOOL)animated; // iOS 6
- (BOOL)activateAssistantWithOptions:(id)options; // iOS 5
@end

@interface SBIcon
- (id)getIconImage:(int)image;
@end

@interface SBIconModel : NSObject
+ (id)sharedInstance; // iOS 5
- (SBIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBIconController
+ (id)sharedInstance;
- (void)scrollToIconListAtIndex:(int)index animate:(BOOL)animate;
- (SBIconModel *)model; // iOS 6
@end

@interface SBBrightnessController
+ (id)sharedBrightnessController;
- (void)setBrightnessLevel:(float)level;
@end

@interface SBAssistantController
+ (id)sharedInstance;
+ (BOOL)supportedAndEnabled;
+ (BOOL)shouldEnterAssistant;
+ (BOOL)isAssistantVisible; // iOS 6
- (BOOL)isAssistantVisible; // iOS 5
- (void)dismissAssistant;
@end

@interface SBUIPluginManager
+ (id)sharedInstance;
- (BOOL)handleActivationEvent:(int)event; // iOS 6 - activates assistant
@end

@interface SBVoiceControlAlert : NSObject
+ (id)pendingOrActiveAlert;
+ (BOOL)shouldEnterVoiceControl;
- (void)cancel;
- (id)initFromMenuButton;
- (void)_workspaceActivate; // iOS 5
@end

@interface SBVoiceControlController
+ (id)sharedInstance;
- (BOOL)handleHomeButtonHeld;
@end

@interface SBBulletinListController
+ (id)sharedInstance;
- (BOOL)listViewIsActive;
- (void)showListViewAnimated:(BOOL)animated;
- (void)hideListViewAnimated:(BOOL)animated;
@end

@interface SBApplicationController
+ (id)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayID;
@end

@interface SBApplication : NSObject
- (NSString *)displayIdentifier;
- (void)setDeactivationSetting:(unsigned)setting flag:(BOOL)flag;
- (void)setDeactivationSetting:(unsigned)setting value:(id)value;
- (void)kill; // iOS 5
@end

@interface SBAppSwitcherModel : NSObject
+ (id)sharedInstance;
- (void)remove:(id)app;
@end

@interface SBAppSwitcherController : NSObject
+ (id)sharedInstance;
- (void)iconCloseBoxTapped:(id)iconView;
@end

// Display Stack (iOS 5 or below) //////////
@interface SBDisplay
- (void)setActivationSetting:(unsigned)setting flag:(BOOL)flag;
- (void)setDeactivationSetting:(unsigned)setting flag:(BOOL)flag;
- (void)setDisplaySetting:(unsigned)setting flag:(BOOL)flag;
@end

@interface SBDisplayStack
- (id)popDisplay:(id)display;
- (void)pushDisplay:(id)display;
- (id)topApplication;
@end
////////////////////////////////////////

// Workspace (iOS 6 or above) //////////
@interface BKSWorkspace
- (id)topApplication;
@end

@interface SBAlertManager
@end

@interface SBWorkspaceTransaction : NSObject
@end

@interface SBToAppWorkspaceTransaction : SBWorkspaceTransaction
- (id)initWithWorkspace:(id)workspace alertManager:(id)manager toApplication:(id)application;
@end

@interface SBAppToAppWorkspaceTransaction : SBToAppWorkspaceTransaction
- (id)initWithWorkspace:(id)workspace alertManager:(id)manager from:(id)from to:(id)to;
- (id)initWithWorkspace:(id)workspace alertManager:(id)manager exitedApp:(id)app;
@end

@interface SBAppExitedWorkspaceTransaction : SBAppToAppWorkspaceTransaction
@end

@interface SBWorkspace : NSObject
@property(readonly, assign, nonatomic) SBAlertManager *alertManager;
@property(readonly, assign, nonatomic) BKSWorkspace *bksWorkspace;
@property(retain, nonatomic) SBWorkspaceTransaction *currentTransaction;
- (id)_applicationForBundleIdentifier:(id)bundleIdentifier frontmost:(BOOL)frontmost;
@end
//////////////////////////////////////////