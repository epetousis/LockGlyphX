//
//  Settings for LockGlyphX
//
//  ©2017
//

#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>

#define kBundlePath 		@"/Library/Application Support/LockGlyph/Themes/"
#define kSelfBundlePath 	@"/Library/PreferenceBundles/LockGlyphX.bundle"

#define kResetColorsAlertTag 	1
#define kApplyThemeAlertTag 	2

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(id)arg1;
@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1;
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 inTableView:(id)arg2;
@end

@interface PSTableCell ()
- (id)initWithStyle:(int)style reuseIdentifier:(id)arg2;
@end

@interface PSListController ()
-(void)clearCache;
-(void)reload;
-(void)viewWillAppear:(BOOL)animated;
@end

//------------------------------------------------------------------------------

@interface LGShared : NSObject
+(NSString *)localisedStringForKey:(NSString *)key;
+(void)parseSpecifiers:(NSArray *)specifiers;
@end

@implementation LGShared
+ (NSString *)localisedStringForKey:(NSString *)key {
	NSString *englishString = [[NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/en.lproj",kSelfBundlePath]] localizedStringForKey:key value:@"" table:nil];
	return [[NSBundle bundleWithPath:kSelfBundlePath] localizedStringForKey:key value:englishString table:nil];
}
+ (void)parseSpecifiers:(NSArray *)specifiers {
	for (PSSpecifier *specifier in specifiers) {
		NSString *localisedTitle = [LGShared localisedStringForKey:specifier.properties[@"label"]];
		NSString *localisedFooter = [LGShared localisedStringForKey:specifier.properties[@"footerText"]];
		[specifier setProperty:localisedFooter forKey:@"footerText"];
		specifier.name = localisedTitle;
	}
}
@end

//------------------------------------------------------------------------------


@interface LockGlyphXPrefsController : PSListController
@end

@implementation LockGlyphXPrefsController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	return _specifiers;
}
- (void)twitterButton {
	NSString *user = @"evilgoldfish01";
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]]];

	else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]]];

	else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:user]]];

	else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]]];

	else
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]]];
}
@end


// Custom cells ----------------------------------------------------------------

@interface LockGlyphXTitleCell : PSTableCell <PreferencesTableCustomView> {
	UILabel *tweakTitle;
	UILabel *tweakSubtitle;
}
@end

@implementation LockGlyphXTitleCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)reuseIdentifier specifier:(id)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
	if (self) {
		
		int width = self.contentView.bounds.size.width;

		CGRect frame = CGRectMake(0, 20, width, 60);
		CGRect subtitleFrame = CGRectMake(0, 55, width, 60);

		tweakTitle = [[UILabel alloc] initWithFrame:frame];
		[tweakTitle setNumberOfLines:1];
		[tweakTitle setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48]];
		[tweakTitle setText:@"LockGlyphX"];
		[tweakTitle setBackgroundColor:[UIColor clearColor]];
		[tweakTitle setTextColor:[UIColor blackColor]];
		[tweakTitle setTextAlignment:NSTextAlignmentCenter];
		tweakTitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		tweakTitle.contentMode = UIViewContentModeScaleToFill;

		tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
		[tweakSubtitle setNumberOfLines:1];
		[tweakSubtitle setFont:[UIFont fontWithName:@"HelveticaNeue-Regular" size:18]];
		[tweakSubtitle setText:[LGShared localisedStringForKey:@"FIRST_SUBTITLE_TEXT"]];
		[tweakSubtitle setBackgroundColor:[UIColor clearColor]];
		[tweakSubtitle setTextColor:[UIColor colorWithRed:119/255.0f green:119/255.0f blue:122/255.0f alpha:1.0f]];
		[tweakSubtitle setTextAlignment:NSTextAlignmentCenter];
		tweakSubtitle.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		tweakSubtitle.contentMode = UIViewContentModeScaleToFill;

		[self addSubview:tweakTitle];
		[self addSubview:tweakSubtitle];
	}
	return self;
}
- (instancetype)initWithSpecifier:(PSSpecifier *)specifier {
	return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LockGlyphXTitleCell" specifier:specifier];
}
- (void)setFrame:(CGRect)frame {
	frame.origin.x = 0;
	[super setFrame:frame];
}
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1{
    return 125.0f;
}
- (CGFloat)preferredHeightForWidth:(CGFloat)width inTableView:(id)tableView {
	return [self preferredHeightForWidth:width];
}
@end


// Other preference panels -----------------------------------------------------

@interface LockGlyphXPrefsBehaviourController : PSListController
@end
@implementation LockGlyphXPrefsBehaviourController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Behaviour" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"BEHAVIOUR_TITLE"]];
	return _specifiers;
}
@end

@interface LockGlyphXPrefsAnimationsController : PSListController
@end
@implementation LockGlyphXPrefsAnimationsController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Animations" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"ANIMATIONS_TITLE"]];
	return _specifiers;
}
@end

@interface LockGlyphXPrefsAppearanceController : PSListController
@end
@implementation LockGlyphXPrefsAppearanceController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Appearance" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	[(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"APPEARANCE_TITLE"]];
	return _specifiers;
}
- (void)viewWillAppear:(BOOL)animated {
	// for libcolorpicker
	[self clearCache];
	[self reload];
	
	[super viewWillAppear:animated];
}
- (void)resetColors {
	/*
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset colours"
		message:@"Are you sure you want to reset colours?"
		delegate:self
		cancelButtonTitle:@"No"
		otherButtonTitles:@"Yes", nil];
	alert.tag = kResetColorsAlertTag;
	[alert show];
	[alert release];
	*/
	CFPreferencesSetAppValue(CFSTR("primaryColor"), CFSTR("#BCBCBC:1.000000"), CFSTR("com.evilgoldfish.lockglyphx"));
    CFPreferencesSetAppValue(CFSTR("secondaryColor"), CFSTR("#777777:1.000000"), CFSTR("com.evilgoldfish.lockglyphx"));
    CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyphx"));
    CFNotificationCenterPostNotification(
    	CFNotificationCenterGetDarwinNotifyCenter(),
    	CFSTR("com.evilgoldfish.lockglyphx.settingschanged"),
    	NULL,
    	NULL,
    	YES
    );
    [self clearCache];
	[self reload];
}
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) { // Tapped yes
    	if (alertView.tag == kResetColorsAlertTag) {
    		CFPreferencesSetAppValue(CFSTR("primaryColor"), CFSTR("#BCBCBC:1.000000"), CFSTR("com.evilgoldfish.lockglyph"));
    		CFPreferencesSetAppValue(CFSTR("secondaryColor"), CFSTR("#777777:1.000000"), CFSTR("com.evilgoldfish.lockglyph"));
    		CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyph"));
    		CFNotificationCenterPostNotification(
    			CFNotificationCenterGetDarwinNotifyCenter(),
    			CFSTR("com.evilgoldfish.lockglyph.settingschanged"),
    			NULL,
    			NULL,
    			YES
    			);
    	} else if (alertView.tag == kApplyThemeAlertTag) {
    		system("killall -9 backboardd");
    	}
    }
}
*/
- (NSArray *)themeTitles {
    NSMutableArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:kBundlePath error:nil] mutableCopy];
    for (int i = 0; i < files.count; i++) {
    	NSString *file = [files objectAtIndex:i];
    	file = [file stringByReplacingOccurrencesOfString:@".bundle" withString:@""];
    	[files replaceObjectAtIndex:i withObject:file];
    }
    return files;
}
- (NSArray *)themeValues {
    NSMutableArray* files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:kBundlePath error:nil] mutableCopy];
    return files;
}
@end
