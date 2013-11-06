#import "HKHeroController.h"

#define SYSTEM_VERSION_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define HKPreActivateDisplayStack [hkDisplayStacks objectAtIndex:0]
#define HKActiveDisplayStack [hkDisplayStacks objectAtIndex:1]
#define HKSuspendingDisplayStack [hkDisplayStacks objectAtIndex:2]
#define HKSuspendedEventOnlyDisplayStack [hkDisplayStacks objectAtIndex:3]

#define kSpringBoardDisplayID @"com.apple.springboard"

static NSMutableArray *hkDisplayStacks = nil;
static HKHeroController *sharedHeroController = nil;

// iOS 6 BackBoardServices ///////////////////////////////////////////////////////////////////////////////////////////////////
extern "C" void BKSTerminateApplicationForReasonAndReportWithDescription(NSString *app, int a, int b, NSString *description);
extern "C" void BKSTerminateApplicationGroupForReasonAndReportWithDescription(int a, int b, int c, NSString *description);
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

%group Firmware_iOS_5
%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    hkDisplayStacks = [[NSMutableArray alloc] initWithCapacity:4];
    %orig;
}

%end

%hook SBDisplayStack

- (id)init
{
	if((self = %orig)) {
		[hkDisplayStacks addObject:self];
	}
	return self;
}

- (void)dealloc
{
	[hkDisplayStacks removeObject:self];
	%orig;
}

%end
%end

static SBWorkspace *workspace = nil;
static id scheduledTransaction = nil;

%group Firmware_iOS_6
%hook SBWorkspace

- (id)init
{
	if((self = %orig)) {
		workspace = [self retain];
	}
	return self;
}

- (void)dealloc
{
	if(workspace == self) {
		[workspace release];
		workspace = nil;
	}
	%orig;
}

- (void)transactionDidFinish:(id)transaction success:(BOOL)success
{
	%orig;
    if(scheduledTransaction != nil) {
		[self setCurrentTransaction:scheduledTransaction];
	    [scheduledTransaction release];
	    scheduledTransaction = nil;
	}
}

%end
%end

%ctor {
	if(SYSTEM_VERSION_LESS_THAN(@"6.0")) %init(Firmware_iOS_5);
	else %init(Firmware_iOS_6);
}

@interface HKHeroController ()
- (void)removeApplicationFromSwitcher:(SBApplication *)app;
@end

@implementation HKHeroController

+ (HKHeroController *)sharedHeroController
{
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedHeroController = [[self alloc] init];
	});
	return sharedHeroController;
}

- (BOOL)isSpringBoardKey
{
	if([[self keyApplicationDisplayID] isEqualToString:kSpringBoardDisplayID]) {
		return YES;
	}
	return NO;
}

- (SBApplication *)keyApplication
{
	SBApplication *app = (SYSTEM_VERSION_LESS_THAN(@"6.0")) ? [HKActiveDisplayStack topApplication] : [workspace _applicationForBundleIdentifier:[workspace.bksWorkspace topApplication] frontmost:YES];
	if(!app) {
		app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:kSpringBoardDisplayID];
	}
	return app;
}

- (NSString *)keyApplicationDisplayID
{
	return [[self keyApplication] displayIdentifier];
}

- (void)activateApplication:(SBApplication *)app
{
	[[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
}

- (void)activateApplicationWithDisplayID:(NSString *)displayID
{
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:displayID];
	[[%c(SBUIController) sharedInstance] activateApplicationFromSwitcher:app];
}

- (void)deactivateKeyApplicationAnimated:(BOOL)animated
{
	SBApplication *app = [self keyApplication];
	if(!app) return;
	
	NSString *displayID = [app displayIdentifier];
	if([displayID isEqualToString:kSpringBoardDisplayID]) return;
	
	if(SYSTEM_VERSION_LESS_THAN(@"6.0")) {
		// iOS 5
		[app setDeactivationSetting:0x2 flag:YES]; // animate
		if(!animated) [app setDeactivationSetting:0x8 value:[NSNumber numberWithInteger:1]];
		// Remove from active display stack
		[HKActiveDisplayStack popDisplay:app];
		// Deactivate the application
		[HKSuspendingDisplayStack pushDisplay:app];
	}
	else {
		// iOS 6
		SBAlertManager *alertManager = workspace.alertManager;
		SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithWorkspace:workspace.bksWorkspace alertManager:alertManager from:[self keyApplication] to:nil];
		if([workspace currentTransaction] == nil) {
			[workspace setCurrentTransaction:transaction];
		}
		else if(scheduledTransaction == nil) {
			// NOTE: Don't schedule more than one transaction.
		    scheduledTransaction = [transaction retain];
		}
		[transaction release];
	}
}

- (void)deactivateKeyApplication
{
	[self deactivateKeyApplicationAnimated:YES];
}

- (void)killApplication:(SBApplication *)app removeFromAppSwitcher:(BOOL)removeFromAppSwitcher
{	
	if(SYSTEM_VERSION_LESS_THAN(@"6.0")) {
		// iOS 5
		if([[app displayIdentifier] isEqualToString:[self keyApplicationDisplayID]]) {
			[self deactivateKeyApplication];
		}
		[app kill];
	}
	else {
		// iOS 6
		// Deactivates and kills app
		BKSTerminateApplicationForReasonAndReportWithDescription([app displayIdentifier], 5, 1, @"Killed by libherokit");
	}
	
	if(removeFromAppSwitcher) {
		[self removeApplicationFromSwitcher:app];
	}
}

- (void)killApplication:(SBApplication *)app
{
	[self killApplication:app removeFromAppSwitcher:YES];
}

- (void)killApplicationWithDisplayID:(NSString *)displayID
{
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithDisplayIdentifier:displayID];
	[self killApplication:app];
}

- (void)removeApplicationFromSwitcher:(SBApplication *)app
{
	SBAppSwitcherModel *switcherModel = [%c(SBAppSwitcherModel) sharedInstance];
	if([switcherModel respondsToSelector:@selector(remove:)]) {
	    // As of iOS 5, remove: takes an NSString* not an SBApplication*
		[switcherModel remove:[app displayIdentifier]];
	}
}

- (UIImage *)currentScreenImage
{
	IOSurfaceRef surface = [UIWindow createScreenIOSurface];
	UIImage *surfaceImage = [[UIImage alloc] _initWithIOSurface:surface scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
	CFRelease(surface);
	return surfaceImage;
	[surfaceImage release];
}

- (UIImage *)iconForApplicationWithDisplayID:(NSString *)displayID size:(HKIconSize)size
{
	if(SYSTEM_VERSION_LESS_THAN(@"6.0")) {
		SBIcon *icon = [[%c(SBIconModel) sharedInstance] applicationIconForDisplayIdentifier:displayID];
		if(icon) { return [icon getIconImage:size]; }
	}
	else {
		SBIconModel *model = (SBIconModel *)[[%c(SBIconController) sharedInstance] model];
		SBIcon *icon = [model applicationIconForDisplayIdentifier:displayID];
		if(icon) { return [icon getIconImage:size]; }
	}
	return nil;
}

- (void)shutdownDevice
{
	[[UIApplication sharedApplication] _powerDownNow];
}

- (void)rebootDevice
{
	[[UIApplication sharedApplication] _rebootNow];
}

- (void)respringDevice
{
	[[UIApplication sharedApplication] _relaunchSpringBoardNow];
}

- (void)enterSafeMode
{
	system("touch /var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat");
	[[UIApplication sharedApplication] _relaunchSpringBoardNow];
}

- (void)lockDevice
{
	[[%c(SBUIController) sharedInstance] lockFromSource:0];
}

- (void)vibrateDevice
{
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)setBrightnessLevel:(float)level
{
	[[%c(SBBrightnessController) sharedBrightnessController] setBrightnessLevel:level];
}

- (void)openSpotlight
{
	if(![self isSpringBoardKey]) {
		[self deactivateKeyApplication];
		[[%c(SBIconController) sharedInstance] scrollToIconListAtIndex:-1 animate:NO];
	}
	else {
		[[%c(SBIconController) sharedInstance] scrollToIconListAtIndex:-1 animate:YES];
	}	
}

- (void)toggleAppSwitcher
{
	if(SYSTEM_VERSION_LESS_THAN(@"6.0")) {
		[[%c(SBUIController) sharedInstance] _toggleSwitcher];
	}
	else {
		if(![[%c(SBUIController) sharedInstance] isSwitcherShowing]) {
			[[%c(SBUIController) sharedInstance] activateSwitcher];
		}
		else {
			[[%c(SBUIController) sharedInstance] dismissSwitcherAnimated:YES];
		}
	}
}

- (void)toggleSiri
{
	if([%c(SBAssistantController) supportedAndEnabled]) {
		// Siri
		if([%c(SBAssistantController) shouldEnterAssistant]) {
			if(SYSTEM_VERSION_LESS_THAN(@"6.0")) {
				if(![[%c(SBAssistantController) sharedInstance] isAssistantVisible]) {
					[[%c(SBUIController) sharedInstance] activateAssistantWithOptions:nil];
				}
				else {
					[[%c(SBAssistantController) sharedInstance] dismissAssistant];
				}
			}
			else {
				if(![%c(SBAssistantController) isAssistantVisible]) {
					[[%c(SBUIPluginManager) sharedInstance] handleActivationEvent:1];
				}
				else {
					[[%c(SBAssistantController) sharedInstance] dismissAssistant];
				}
			}
		}
	}
	else {
		// Voice controls
		if(SYSTEM_VERSION_LESS_THAN(@"6.0")) {
			SBVoiceControlAlert *alert = [%c(SBVoiceControlAlert) pendingOrActiveAlert];
			if (alert) { [alert cancel]; }
			if ([%c(SBVoiceControlAlert) shouldEnterVoiceControl]) {
			    alert = [[%c(SBVoiceControlAlert) alloc] initFromMenuButton];
				[alert _workspaceActivate];
			    [alert release];
			}
		}
		else {
			[[%c(SBVoiceControlController) sharedInstance] handleHomeButtonHeld];
		}
	}
}

- (void)toggleNotificationCenter
{
	SBBulletinListController *blc = [%c(SBBulletinListController) sharedInstance];
	if(blc) {
		if(![blc listViewIsActive]) {
			[blc showListViewAnimated:YES];
		}
		else {
			[blc hideListViewAnimated:YES];
		}
	}
}

- (void)toggleLEDFlash
{
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if([device hasTorch])
	{
		if(!device.torchActive) {
		    [device lockForConfiguration:nil];
		    [device setTorchMode:AVCaptureTorchModeOn];
		    [device unlockForConfiguration];
		}
		else {
			[device lockForConfiguration:nil];
			[device setTorchMode:AVCaptureTorchModeOff];
			[device unlockForConfiguration];
		}
	}
}

- (void)showHUDWithImage:(UIImage *)image title:(NSString *)title subtitle:(NSString *)subtitle dismissAfterDelay:(NSTimeInterval)delay
{
	SBHUDView *hud = [[%c(SBHUDView) alloc] initWithHUDViewLevel:0];
	hud.image = image;
	hud.title = title;
	hud.subtitle = subtitle;
	[[%c(SBHUDController) sharedHUDController] presentHUDView:hud autoDismissWithDelay:delay];
	[hud release];
}

#pragma mark iOS_5_SBDisplayStack

- (SBDisplayStack *)preActivateDisplayStack { return HKPreActivateDisplayStack; }
- (SBDisplayStack *)activeDisplayStack { return HKActiveDisplayStack; }
- (SBDisplayStack *)suspendingDisplayStack { return HKSuspendingDisplayStack; }
- (SBDisplayStack *)suspendedEventOnlyDisplayStack { return HKSuspendedEventOnlyDisplayStack; }

@end