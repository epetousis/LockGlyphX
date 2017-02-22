//
//  LockGlyphXPrefs.mm
//  Settings for LockGlyphX
//
//  (c)2017 evilgoldfish
//
//  feat. @sticktron
//

#import "Common.h"
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <Preferences/PSTableCell.h>
#import <Social/Social.h>


#define kResetColorsAlertTag 	1
#define kApplyThemeAlertTag 	2

#define kHeaderHeight 148.0f


@interface PSListController ()
- (void)clearCache;
@end


@interface LGShared : NSObject
+ (NSString *)localisedStringForKey:(NSString *)key;
+ (void)parseSpecifiers:(NSArray *)specifiers;
@end

@implementation LGShared
+ (NSString *)localisedStringForKey:(NSString *)key {
	NSString *englishString = [[NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/en.lproj", kPrefsBundlePath]] localizedStringForKey:key value:@"" table:nil];
	return [[NSBundle bundleWithPath:kPrefsBundlePath] localizedStringForKey:key value:englishString table:nil];
}
+ (void)parseSpecifiers:(NSArray *)specifiers butOnlyFooter:(BOOL)onlyFooter {
    for (PSSpecifier *specifier in specifiers) {
        NSString *localisedTitle = [LGShared localisedStringForKey:specifier.properties[@"label"]];
        NSString *localisedFooter = [LGShared localisedStringForKey:specifier.properties[@"footerText"]];
        [specifier setProperty:localisedFooter forKey:@"footerText"];
        if(!onlyFooter) {
            specifier.name = localisedTitle;
        }
    }
}
+ (void)parseSpecifiers:(NSArray *)specifiers {
    [LGShared parseSpecifiers:specifiers butOnlyFooter:NO];
}
@end


// Main Controller -------------------------------------------------------------

@interface LockGlyphXPrefsController : PSListController
@end

@implementation LockGlyphXPrefsController
- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.title = @"";
	
	// add a heart button to the navbar
	// UIImage *heartImage = [[UIImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/heart.png", kPrefsBundlePath]];
	// UIBarButtonItem *heartButton = [[UIBarButtonItem alloc] initWithImage:heartImage style:UIBarButtonItemStylePlain target:self action:@selector(showLove)];
	// heartButton.imageInsets = (UIEdgeInsets){2, 0, -2, 0};
	// heartButton.tintColor = kTintColor;
	// [self.navigationItem setRightBarButtonItem:heartButton];
}
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs" target:self];
	}
	[LGShared parseSpecifiers:_specifiers];
	return _specifiers;
}
- (void)showLove {
	// send a nice tweet ;)
	// NSString *tweet = @"Bless your lockscreen with LockGlyphX, free for iOS 10!";
	// SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
	// [composeController setInitialText:tweet];
	// [self presentViewController:composeController animated:YES completion:nil];
}
- (void)openTwitterForUser:(NSString *)user {
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]]];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]]];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:user]]];
		
	} else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]]) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]]];
		
	} else {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]]];
	}
}
- (void)twitterButton {
	[self openTwitterForUser:@"evilgoldfish01"];
}
- (void)twitterButton2 {
	[self openTwitterForUser:@"sticktron"];
}
- (void)twitterButton3 {
	[self openTwitterForUser:@"AppleBetasDev"];
}
- (void)issueButton {
	// [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/evilgoldfish/LockGlyphX/issues"]];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/sticktron/LockGlyphX/issues"]];
}
- (CGFloat)tableView:(id)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 || indexPath.section == 1 || indexPath.section == 2) {
		return 60;
	} else {
		return [super tableView:tableView heightForRowAtIndexPath:indexPath];
	}
}
- (CGFloat)tableView:(id)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return kHeaderHeight;
	} else if (section == 1 || section == 2) {
		return 4;
	} else {
		return [super tableView:tableView heightForHeaderInSection:section];
	}
}
- (CGFloat)tableView:(id)tableView heightForFooterInSection:(NSInteger)section {
	if (section == 0 || section == 1) {
		return 4;
	} else {
		return [super tableView:tableView heightForFooterInSection:section];
	}
}
- (id)tableView:(id)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		UIView *headerView = [[UIView alloc] initWithFrame:(CGRect){{0, 0}, {320, kHeaderHeight}}];
		headerView.backgroundColor = UIColor.clearColor;
		headerView.clipsToBounds = YES;
		
		// icon
		UIImage *icon = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Icon.png", kPrefsBundlePath]];
		UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
		iconView.frame = (CGRect){{0, 21}, iconView.frame.size};
		iconView.center = (CGPoint){headerView.center.x, iconView.center.y};
		iconView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:iconView];
		
		// title
		CGRect frame = CGRectMake(0, 54, headerView.bounds.size.width, 50);
		UILabel *tweakTitle = [[UILabel alloc] initWithFrame:frame];
		tweakTitle.font = [UIFont systemFontOfSize:46 weight:UIFontWeightUltraLight];
		tweakTitle.text = @"LockGlyphX";
		tweakTitle.textColor = UIColor.blackColor;
		tweakTitle.textAlignment = NSTextAlignmentCenter;
		tweakTitle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:tweakTitle];
		
		// subtitle
		CGRect subtitleFrame = CGRectMake(0, 102, headerView.bounds.size.width, 30);
		UILabel *tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
		tweakSubtitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightUltraLight];
		tweakSubtitle.text = @"custom lockscreen glyphs";
		tweakSubtitle.textColor = [UIColor colorWithWhite:0 alpha:0.33];
		tweakSubtitle.textAlignment = NSTextAlignmentCenter;
		tweakSubtitle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:tweakSubtitle];
		
		// beta tag
		UILabel *betaLabel = [[UILabel alloc] initWithFrame:headerView.bounds];
		betaLabel.font = [UIFont systemFontOfSize:120 weight:UIFontWeightBold];
		betaLabel.text = @"BETA";
		betaLabel.textColor = [UIColor colorWithRed:0.5 green:1 blue:0 alpha:0.05];
		betaLabel.textAlignment = NSTextAlignmentCenter;
		betaLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
		[headerView addSubview:betaLabel];
		
		return headerView;
	} else {
		return [super tableView:tableView viewForHeaderInSection:section];
	}
}
@end


// Behaviour Controller --------------------------------------------------------

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

-(NSArray *)soundValues {
    return @[@0, @1, @2, @3];
}

-(NSArray *)soundTitles {
    NSMutableArray *titles = [@[@"SOUND_NONE", @"SOUND_DEFAULT", @"SOUND_APPLE_PAY", @"SOUND_OLD_APPLE_PAY"] mutableCopy];
    for (int i = 0; i < titles.count; i++) {
        titles[i] = [LGShared localisedStringForKey:titles[i]];
    }
    return titles;
}
@end


// Appearance Controller -------------------------------------------------------

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
@end


// Animations Controller -------------------------------------------------------

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


// Credits Controller ----------------------------------------------------------

@interface LockGlyphXPrefsCreditsController : PSListController
@end

@implementation LockGlyphXPrefsCreditsController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"LockGlyphXPrefs-Credits" target:self];
	}
	// [LGShared parseSpecifiers:_specifiers];
	// [(UINavigationItem *)self.navigationItem setTitle:[LGShared localisedStringForKey:@"ANIMATIONS_TITLE"]];
	return _specifiers;
}
@end


// Custom Cells ----------------------------------------------------------------

@interface LGXButtonCell : PSTableCell
@end

@implementation LGXButtonCell
- (void)layoutSubviews {
	[super layoutSubviews];
	[self.textLabel setTextColor:UIColor.blackColor];
}
@end


@interface LGXSwitchCell : PSSwitchTableCell
@end

@implementation LGXSwitchCell
- (id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
	self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
	if (self) {
		[((UISwitch *)[self control]) setOnTintColor:kTintColor];
	}
	return self;
}
@end


@interface LGXThemeLinkCell : PSTableCell
@end

@implementation LGXThemeLinkCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(PSSpecifier *)specifier {
	// overridde the cell style because we want a detail label on the right side ...
	if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier specifier:specifier]) {
		NSString *selectedTheme;
		
		// check prefs for selected theme
		CFPreferencesAppSynchronize(kPrefsAppID);
		CFPropertyListRef value = CFPreferencesCopyAppValue(kPrefsCurrentThemeKey, kPrefsAppID);
		selectedTheme = (value) ? (NSString *)CFBridgingRelease(value) : kDefaultThemeName;
		
		self.detailTextLabel.text = selectedTheme;
	}
	return self;
}
@end

// Items Controller (still localizes footer) --------------------------------------------------------

@interface PSListItemsController : PSListController
@end

@interface LockGlyphXPrefsItemsController : PSListItemsController
@end

@implementation LockGlyphXPrefsItemsController
- (NSArray *)specifiers {
    NSArray *specifiers = [super specifiers];
    [LGShared parseSpecifiers:specifiers butOnlyFooter:YES];
    return specifiers;
}
@end
