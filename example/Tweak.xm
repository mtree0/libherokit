#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <libherokit/libherokit.h>

%hook SBApplicationIcon
	
- (void)launch
{
	UIImage *image = [UIImage imageWithContentsOfFile:@"/Library/HeroKitExample/image.png"];
	[[HKHeroController sharedHeroController] showHUDWithImage:image title:@"libherokit" subtitle:@"That was easy." dismissAfterDelay:3.0f];
	%orig();
}

%end