#import "HKInterface.h"

typedef enum {
	HKIconSizeSettings = 1,
	HKIconSizeSpringBoard = 2
} HKIconSize;

@class SBApplication;
@class SBDisplayStack;

@interface HKHeroController : NSObject

+ (HKHeroController *)sharedHeroController;

// Returns a BOOL indicating whether SpringBoard is the key application
- (BOOL)isSpringBoardKey;

// Returns the current key application
// If nothing is open, returns SpringBoard
- (SBApplication *)keyApplication;

// Returns the key application's display identifier
- (NSString *)keyApplicationDisplayID;

// Activates a given application
- (void)activateApplication:(SBApplication *)app;

// Activates a given application from it's display identifier
- (void)activateApplicationWithDisplayID:(NSString *)displayID;

// Deactivates the key application (if there is one)
// NOTE: the animated: parameter only applies to iOS 5 at the moment
- (void)deactivateKeyApplicationAnimated:(BOOL)animated;

// Deactivates the key application (if there is one)
// This always sets animated:YES
- (void)deactivateKeyApplication;

// Kills a given application and optionally removes it from the app-switcher
- (void)killApplication:(SBApplication *)app removeFromAppSwitcher:(BOOL)removeFromAppSwitcher;

// Kills a given application
// This always sets removeFromSwitcher:YES
- (void)killApplication:(SBApplication *)app;

// Kills a given application from it's display identifier
- (void)killApplicationWithDisplayID:(NSString *)displayID;

// Returns a UIImage of the current screen
- (UIImage *)currentScreenImage; 

// Returns a UIImage of the specified application's icon
// HKIconSizeSettings = 1, HKIconSizeSpringBoard = 2
- (UIImage *)iconForApplicationWithDisplayID:(NSString *)displayID size:(HKIconSize)size;

// Powers the device down
- (void)shutdownDevice;

// Restarts the device
- (void)rebootDevice;

// Resprings the device
- (void)respringDevice;

// Puts the device into mobile substrate safe-mode
- (void)enterSafeMode;

// Locks the device
- (void)lockDevice; 

// Vibrates the device
- (void)vibrateDevice; 

// Sets the screen's brightness level
// level should range between 0 and 1
- (void)setBrightnessLevel:(float)level;

// Opens spotlight search
- (void)openSpotlight;

// Toggles the switcher on & off
- (void)toggleAppSwitcher;

// Toggles Siri on & off.
// If device doesn't have Siri, voice-controls will be used instead
- (void)toggleSiri;

// Toggles notification center
- (void)toggleNotificationCenter;

// Toggles the device's LED flash on & off
- (void)toggleLEDFlash;

// Shows a standard system HUD with a given image, title, and subtitle
// HUD will be dismissed after specified delay
- (void)showHUDWithImage:(UIImage *)image title:(NSString *)title subtitle:(NSString *)subtitle dismissAfterDelay:(NSTimeInterval)delay;

// Display Stack (iOS 5 ONLY) ///////////////////////////////////////////////////////////////////////
- (SBDisplayStack *)preActivateDisplayStack; // Returns the preActivate display stack				/
- (SBDisplayStack *)activeDisplayStack; // Returns the active display stack							/
- (SBDisplayStack *)suspendingDisplayStack; // Returns the suspending display stack					/
- (SBDisplayStack *)suspendedEventOnlyDisplayStack; // Returns the suspendedEventOnly display stack /
/////////////////////////////////////////////////////////////////////////////////////////////////////

@end